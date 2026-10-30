package Langertha::Raider::CronTools;
# ABSTRACT: Internal session-scoped scheduled prompts: cron_create, cron_delete and cron_list
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use IO::Async::Timer::Periodic;
use Langertha::Raider::Cron;
use MCP::Server;
use POSIX ();
use Scalar::Util qw( weaken );


has loop => (
  is       => 'ro',
  isa      => 'IO::Async::Loop',
  required => 1,
);


has tasks => (
  is       => 'ro',
  isa      => 'Langertha::Raider::Tasks',
  required => 1,
);


has recipient => ( is => 'ro', isa => 'Str', default => 'cron' );


has clock => ( is => 'ro', isa => 'CodeRef', default => sub { sub { time } } );


has max_jobs => ( is => 'ro', isa => 'Int', default => 50 );


has expire_after => ( is => 'ro', isa => 'Int', default => 7 * 86400 );


has tick_interval => ( is => 'ro', isa => 'Num', default => 1 );


has timer => ( is => 'ro', isa => 'Bool', default => 1 );


has _timer => ( is => 'rw', init_arg => undef );

sub cron_class { 'Langertha::Raider::Cron' }

has server => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_server',
  init_arg => undef,
);


#### The server

sub _build_server {
  my ( $self ) = @_;
  weaken( my $weak = $self );
  my $call = sub {
    my ( $method ) = @_;
    return sub {
      my ( $tool, $in ) = @_;
      return $tool->text_result( 'the scheduler is gone', 1 ) unless $weak;
      return $tool->text_result( $weak->$method( ref $in eq 'HASH' ? $in : {} ) );
    };
  };
  my $server = MCP::Server->new( name => 'raider-cron', version => '1.0' );
  $server->tool(
    name         => 'cron_create',
    description  => 'Schedule a prompt to be run at a future time within this session, either recurring or once. '
      .'Uses standard 5-field cron in the user\'s local timezone: "minute hour day-of-month month day-of-week". '
      .'"0 9 * * *" means 9am local -- no timezone conversion needed. '
      .'One-shot tasks (recurring: false) fire once and are deleted; pin the minute, hour, day of month and month '
      .'("30 14 15 3 *" for 2:30pm on March 15th). Recurring tasks (the default) fire on every match and expire '
      .'after 7 days: they run one final time and are deleted. '
      .'Avoid the :00 and :30 minute marks when the user\'s request is approximate (use "57 8 * * *" for "around 9am") '
      .'so that jobs do not pile up on the same minute. '
      .'The prompt is run as a new turn when raider is idle -- it never interrupts a turn in progress -- and only '
      .'while raider is running: jobs live in this session and are lost when it ends (durable is not supported). '
      .'Returns a job ID for cron_delete. A session holds at most '.$self->max_jobs.' jobs.',
    input_schema => {
      type       => 'object',
      properties => {
        cron      => { type => 'string', description => 'Standard 5-field cron expression in local time: "M H DoM Mon DoW" '
          .'(e.g. "*/5 * * * *" = every 5 minutes, "30 14 28 2 *" = Feb 28 at 2:30pm local once).' },
        prompt    => { type => 'string', description => 'The prompt to run at each fire time.' },
        recurring => { type => 'boolean', description => 'true (default) = fire on every cron match until deleted or '
          .'auto-expired after 7 days. false = fire once at the next match, then auto-delete.' },
        durable   => { type => 'boolean', description => 'Not supported: jobs live in this session only and are lost when raider exits.' },
      },
      required => [ 'cron', 'prompt' ],
    },
    code => $call->('create'),
  );
  $server->tool(
    name         => 'cron_delete',
    description  => 'Cancel a job previously scheduled with cron_create. Takes the job ID it returned.',
    input_schema => {
      type       => 'object',
      properties => { id => { type => 'string', description => 'The job ID returned by cron_create.' } },
      required   => [ 'id' ],
    },
    code => $call->('delete'),
  );
  $server->tool(
    name         => 'cron_list',
    description  => 'List all jobs scheduled with cron_create in this session: ID, schedule, whether it recurs, '
      .'when it runs next, and the prompt.',
    input_schema => { type => 'object', properties => {} },
    code         => $call->('list'),
  );
  return $server;
}

#### Tools


sub create {
  my ( $self, $in ) = @_;
  my $expr   = $in->{cron};
  my $prompt = $in->{prompt};
  $expr =~ s/\A\s+|\s+\z//g if defined $expr && !ref $expr;
  my $error = $self->cron_class->validate($expr);
  return ( 'Invalid cron expression "'.( $expr // '' ).'": '.$error, 1 ) if defined $error;
  return ( 'No prompt given: the prompt parameter must be a non-empty string', 1 )
    unless defined $prompt && !ref $prompt && $prompt =~ /\S/;
  return ( 'Too many scheduled jobs ('.$self->max_jobs.'). Cancel one with cron_delete first.', 1 )
    if $self->jobs >= $self->max_jobs;
  my $recurring = !exists $in->{recurring} || !defined $in->{recurring} || $in->{recurring} ? 1 : 0;

  my $now = $self->clock->();
  my $id  = $self->tasks->next_id('cron');
  weaken( my $weak = $self );
  my $job = $self->tasks->add(
    id        => $id,
    kind      => 'cron',
    cron      => $expr,
    prompt    => $prompt,
    recurring => $recurring,
    created   => $now,
    expires   => $now + $self->expire_after,
    fires     => 0,
    stop      => sub { $weak->_remove( $id, 'killed' ) if $weak },
  );
  $self->_schedule( $job, $now );
  $self->_ensure_timer;
  return ( $recurring
    ? 'Scheduled recurring job '.$id.' ('.$expr.'). Session-only (not written to disk, dies when raider exits). '
      .'Auto-expires after 7 days. Use cron_delete to cancel sooner.'
    : 'Scheduled one-shot job '.$id.' ('.$expr.'). It fires once, then is deleted. Session-only (not written to disk, '
      .'dies when raider exits).', 0 );
}


sub delete {
  my ( $self, $in ) = @_;
  my $id  = $in->{id};
  my $job = defined $id && !ref $id ? $self->tasks->get($id) : undef;
  return ( 'No scheduled job with ID: '.( $id // '' ), 1 ) unless $job && $job->{kind} eq 'cron' && $job->{status} eq 'running';
  $self->_remove( $id, 'killed' );
  return ( 'Cancelled job '.$id.'.', 0 );
}


sub list {
  my ( $self ) = @_;
  my @jobs = $self->jobs;
  return ( 'No scheduled jobs.', 0 ) unless @jobs;
  return ( join( "\n", map {
    my $prompt = $_->{prompt} =~ s/\s+/ /gr;
    $prompt = substr( $prompt, 0, 97 ).'...' if length $prompt > 100;
    $_->{id}.' - '.$_->{cron}.' ('.( $_->{recurring} ? 'recurring' : 'one-shot' ).', next run '
      .POSIX::strftime( '%Y-%m-%d %H:%M:%S', localtime $_->{fire_at} ).'): '.$prompt;
  } @jobs ), 0 );
}


sub jobs {
  my ( $self ) = @_;
  return $self->tasks->running( kind => 'cron' );
}

#### Scheduling

# The next run of a job after $now, with its jitter.
sub _schedule {
  my ( $self, $job, $now ) = @_;
  my $class   = $self->cron_class;
  my $after   = $now > ( $job->{nominal} // 0 ) ? $now : $job->{nominal};
  my $nominal = $class->next( $job->{cron}, $after );
  unless ( defined $nominal ) {
    $self->_remove( $job->{id}, 'completed' );
    return;
  }
  $job->{nominal} = $nominal;
  $job->{fire_at} = $nominal + $class->jitter( $job->{cron}, $nominal, key => $job->{id}, recurring => $job->{recurring} );
  return $job;
}


sub tick {
  my ( $self, $now ) = @_;
  $now //= $self->clock->();
  my @fired;
  for my $job ( $self->jobs ) {
    next if $job->{fire_at} > $now;
    my $waiting = grep { ( $_->{id} // '' ) eq $job->{id} } $self->tasks->peek( $self->recipient );
    unless ($waiting) {
      $self->tasks->post( $self->recipient, $job->{prompt},
        id => $job->{id}, label => 'scheduled job '.$job->{id}.' ('.$job->{cron}.')', scheduled => 1 );
      $job->{fires}++;
      $job->{last_fired} = $now;
      push @fired, $job->{id};
    }
    if ( !$job->{recurring} || $now >= $job->{expires} ) {
      $self->_remove( $job->{id}, 'completed' );
    }
    else {
      $self->_schedule( $job, $now );
    }
  }
  $self->_drop_timer unless $self->jobs;
  return @fired;
}

sub _remove {
  my ( $self, $id, $status ) = @_;
  my $job = $self->tasks->get($id);
  $self->tasks->finish( $id, $status ) if $job && $job->{status} eq 'running';
  $self->_drop_timer unless $self->jobs;
  return;
}

#### The timer

sub _ensure_timer {
  my ( $self ) = @_;
  return unless $self->timer && !$self->_timer;
  weaken( my $weak = $self );
  my $timer = IO::Async::Timer::Periodic->new(
    interval => $self->tick_interval,
    on_tick  => sub { $weak->tick if $weak },
  );
  $self->loop->add($timer);
  $timer->start;
  $self->_timer($timer);
  return;
}

sub _drop_timer {
  my ( $self ) = @_;
  my $timer = $self->_timer or return;
  $self->_timer(undef);
  $timer->stop;
  $self->loop->remove($timer) if $timer->loop;
  return;
}


sub stop_all {
  my ( $self ) = @_;
  $self->_remove( $_->{id}, 'killed' ) for $self->jobs;
  $self->_drop_timer;
  return;
}

sub DEMOLISH {
  my ( $self, $global ) = @_;
  return if $global;
  $self->_drop_timer;
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CronTools - Internal session-scoped scheduled prompts: cron_create, cron_delete and cron_list

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $cron = Langertha::Raider::CronTools->new(
      loop  => $app->loop,
      tasks => $app->tasks,
    );
    my $server = $cron->server;       # MCP::Server with cron_create, cron_delete, cron_list

    $cron->tick;                      # what the loop's timer does once a second

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The scheduled prompts of raider, shaped after Claude Code's C<CronCreate>,
C<CronDelete> and C<CronList> (L<Langertha::Raider::ToolNames>, ADR 0031).
A job is a five-field cron expression
(L<Langertha::Raider::Cron>), in local time, a prompt, and whether it
recurs or fires once. Jobs belong to the session -- they are entries of the
application's L<Langertha::Raider::Tasks> (kind C<cron>, IDs C<cron_N>) and
go when raider does; nothing is written to disk.

A timer on the application's loop looks once a second for jobs that are
due. A due job does not interrupt anything: its prompt waits in the
registry's queue C<cron> (L</recipient>) until the surface is free -- the
REPL at its prompt with nothing typed -- and then runs as a new turn.
Several fires of one job that wait are one (no catch-up: a job whose time
passed while a turn ran fires once when the turn is over). A recurring job
expires seven days after its creation: it fires one more time, then it is
deleted. Run times are shifted the way Claude Code does it
(L<Langertha::Raider::Cron/jitter>).

=head2 loop

Required. The loop the timer runs on -- the application's.

=head2 tasks

Required. The application's registry: the jobs are its entries, the fires
its queue.

=head2 recipient

The queue of L<Langertha::Raider::Tasks> the prompts of due jobs are posted
to: C<cron>. It is not C<main>: a prompt that is due is not a notification
and must not be pulled into a turn that is running.

=head2 clock

The clock, a code reference that returns epoch seconds: C<time>. Tests give
it a clock they move by hand.

=head2 max_jobs

How many jobs a session may hold: 50, as in Claude Code.

=head2 expire_after

Seconds a recurring job lives: seven days.

=head2 tick_interval

Seconds between two looks at the jobs: one.

=head2 timer

True (the default) when the object runs the timer on the loop. Without it
the caller calls L</tick> itself.

=head2 server

The L<MCP::Server> with C<cron_create>, C<cron_delete> and C<cron_list>,
built once.

=head2 create

    my ( $text, $is_error ) = $cron->create({ cron => '*/5 * * * *', prompt => 'check the build' });

The C<cron_create> tool: schedules the job and answers with its ID. The
expression must parse (L<Langertha::Raider::Cron/validate>), the prompt must
not be empty, and the session may hold L</max_jobs> jobs.

=head2 delete

    my ( $text, $is_error ) = $cron->delete({ id => 'cron_1' });

The C<cron_delete> tool: C<Cancelled job ID.>, or the error C<No scheduled
job with ID: X>.

=head2 list

    my ( $text ) = $cron->list({});

The C<cron_list> tool: one line per job -- ID, expression, C<recurring> or
C<one-shot>, the next run (local time) and the prompt -- or C<No scheduled
jobs.>

=head2 jobs

    my @jobs = $cron->jobs;      # the entries of the jobs that are scheduled, oldest first
    my $n    = $cron->jobs;

=head2 tick

    $cron->tick;
    $cron->tick($epoch);

Fires every job that is due at C<$epoch> (default: the clock): its prompt is
queued for the surface (L</recipient>), the next run of a recurring job is
set -- counted from now, so missed runs are not made up -- and a one-shot
job, or a recurring one past its expiry, is finished. A job whose previous
fire still waits in the queue is not queued again. Returns the IDs of the
jobs that fired.

=head2 stop_all

Deletes every job and stops the timer; the application going away does it.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Cron>

=item * L<Langertha::Raider::Tasks>

=item * L<Langertha::Raider::Application>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut
