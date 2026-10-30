package Langertha::Raider::Monitor;
# ABSTRACT: Internal event stream of one background command: every stdout line becomes a notification
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Encode ();
use List::Util qw( min );
use POSIX qw( WNOHANG );
use Scalar::Util qw( weaken );
use Time::HiRes ();


has id          => ( is => 'ro', isa => 'Str', required => 1 );
has command     => ( is => 'ro', isa => 'Str', required => 1 );
has description => ( is => 'ro', isa => 'Str', required => 1 );
has loop        => ( is => 'ro', isa => 'IO::Async::Loop', required => 1 );
has tasks       => ( is => 'ro', isa => 'Langertha::Raider::Tasks', required => 1 );


has recipient   => ( is => 'ro', isa => 'Str', default => 'main' );
has tool_use_id => ( is => 'ro', isa => 'Maybe[Str]' );
has working_directory => ( is => 'ro', isa => 'Maybe[Str]' );
has stderr_file => ( is => 'ro', isa => 'Maybe[Path::Tiny]' );


has timeout       => ( is => 'ro', isa => 'Num', default => 300 );
has batch_window  => ( is => 'ro', isa => 'Num', default => 0.2 );
has burst_limit   => ( is => 'ro', isa => 'Int', default => 20 );
has burst_window  => ( is => 'ro', isa => 'Num', default => 10 );
has event_limit   => ( is => 'ro', isa => 'Int', default => 500 );
has line_limit    => ( is => 'ro', isa => 'Int', default => 2000 );
has batch_limit   => ( is => 'ro', isa => 'Int', default => 8000 );
has kill_grace    => ( is => 'ro', isa => 'Num', default => 2 );
has clock         => ( is => 'ro', isa => 'CodeRef', default => sub { sub { Time::HiRes::time() } } );
has on_end        => ( is => 'ro', isa => 'Maybe[CodeRef]' );


has pid      => ( is => 'rw', init_arg => undef );
has status   => ( is => 'rw', init_arg => undef, default => 'running' );
has exit_code => ( is => 'rw', init_arg => undef );
has events   => ( is => 'rw', init_arg => undef, default => 0 );
has quiet    => ( is => 'rw', isa => 'Bool', default => 0 );

has _buffer  => ( is => 'rw', init_arg => undef, default => '' );
has _lines   => ( is => 'ro', init_arg => undef, default => sub { [] } );
has _times   => ( is => 'ro', init_arg => undef, default => sub { [] } );
has _handle  => ( is => 'rw', init_arg => undef );
has _batch_timer => ( is => 'rw', init_arg => undef );
has _deadline_timer => ( is => 'rw', init_arg => undef );
has _watched => ( is => 'rw', init_arg => undef, default => 0 );
has _reason  => ( is => 'rw', init_arg => undef );
has _ended   => ( is => 'rw', init_arg => undef, default => 0 );


sub start {
  my ( $self ) = @_;
  pipe( my $rd, my $wr ) or return 'pipe: '.$!;
  my $err;
  if ( my $file = $self->stderr_file ) {
    open $err, '>', "$file" or return 'cannot write '.$file.': '.$!;
  }
  my $pid = fork;
  return 'fork: '.$! unless defined $pid;
  unless ($pid) {
    # The child: a process group of its own (stopping it reaches everything it
    # starts), default signals, stdout into the pipe.
    eval { setpgrp( 0, 0 ) };
    $SIG{$_} = 'DEFAULT' for grep { exists $SIG{$_} } qw( INT TERM HUP QUIT PIPE CHLD ALRM );
    close $rd;
    open STDIN,  '<',  '/dev/null';
    open STDOUT, '>&', $wr;
    if ($err) { open STDERR, '>&', $err } else { open STDERR, '>', '/dev/null' }
    if ( defined $self->working_directory && length $self->working_directory && !chdir $self->working_directory ) {
      print STDERR 'raider: cannot change to '.$self->working_directory.': '.$!."\n";
      POSIX::_exit(1);
    }
    { no warnings 'exec'; exec 'bash', '-c', $self->command; }
    print STDERR 'raider: cannot run bash: '.$!."\n";
    POSIX::_exit(127);
  }
  close $wr;
  close $err if $err;
  $rd->blocking(0);
  $self->_handle($rd);
  $self->pid($pid);

  weaken( my $weak = $self );
  $self->tasks->add(
    id          => $self->id,
    kind        => 'monitor',
    command     => $self->command,
    timeout     => $self->timeout,
    description => $self->description,
    tool_use_id => $self->tool_use_id,
    recipient   => $self->recipient,
    background  => 1,
    stop        => sub { $weak->stop('stopped') if $weak },
  );
  my $me = $self;    # held by the loop's watchers until the monitor ends
  $self->loop->watch_io( handle => $rd, on_read_ready => sub { $me->_read } );
  $self->_watched(1);
  $self->loop->watch_process( $pid, sub {
    my ( undef, $status ) = @_;
    $me->_watched(0);
    $me->_finish( $me->_outcome($status) );
  } );
  $self->_deadline_timer( $self->loop->watch_time( after => $self->timeout, code => sub {
    $me->_deadline_timer(undef);
    $me->stop('timeout');
  } ) );
  return;
}

#### Reading

# All that is there to read, without blocking: whole lines are events.
sub _read {
  my ( $self ) = @_;
  my $fh = $self->_handle or return;
  my $eof;
  while (1) {
    my $got = sysread( $fh, my $chunk, 65536 );
    if ( defined $got && $got > 0 ) {
      $self->_buffer( $self->_buffer.$chunk );
      next;
    }
    $eof = 1 if defined $got;    # 0: the other end is closed
    last;                       # undef: nothing more for now
  }
  my $buffer = $self->_buffer;
  while ( $buffer =~ s/\A([^\n]*)\n// ) {
    $self->_line($1);
  }
  $self->_buffer($buffer);
  if ($eof) {
    $self->_line($buffer) if length $buffer;
    $self->_buffer('');
    $self->_close_handle;
  }
  return;
}

sub _close_handle {
  my ( $self ) = @_;
  my $fh = $self->_handle or return;
  eval { $self->loop->unwatch_io( handle => $fh, on_read_ready => 1 ) };
  close $fh;
  $self->_handle(undef);
  return;
}

sub _line {
  my ( $self, $bytes ) = @_;
  return if $self->_ended;
  my $line = Encode::decode( 'UTF-8', $bytes );
  $line =~ s/\r\z//;
  my $max = $self->line_limit;
  $line = substr( $line, 0, $max ).' ... [line truncated]' if length $line > $max;
  push @{ $self->_lines }, $line;
  unless ( defined $self->_batch_timer ) {
    my $me = $self;
    $self->_batch_timer( $self->loop->watch_time( after => $self->batch_window, code => sub {
      $me->_batch_timer(undef);
      $me->_flush;
    } ) );
  }
  return;
}

#### Events

# Delivers the lines collected so far as one notification -- or stops the
# monitor when it has sent too many.
sub _flush {
  my ( $self ) = @_;
  if ( defined( my $timer = $self->_batch_timer ) ) {
    $self->_batch_timer(undef);
    eval { $self->loop->unwatch_time($timer) };
  }
  my @lines = splice @{ $self->_lines };
  return if !@lines || $self->_ended || $self->_overflowed;

  my $now   = $self->clock->();
  my $times = $self->_times;
  push @$times, $now;
  shift @$times while @$times && $times->[0] < $now - $self->burst_window;
  if ( @$times > $self->burst_limit ) {
    $self->stop('burst');
    return;
  }
  if ( $self->events >= $self->event_limit ) {
    $self->stop('total');
    return;
  }
  $self->events( $self->events + 1 );

  my $text = join "\n", @lines;
  my $max  = $self->batch_limit;
  $text = substr( $text, 0, $max )."\n... [".( length($text) - $max ).' more characters not shown]' if length $text > $max;
  $self->_deliver( $self->tasks->notification_text(
    task_id     => $self->id,
    tool_use_id => $self->tool_use_id,
    summary     => 'Monitor event: "'.$self->description.'"',
    event       => $text,
  ), 'monitor '.$self->id.' event' );
  return;
}

# Nothing goes to a subagent that has ended, nor while raider is torn down.
sub _deliver {
  my ( $self, $text, $label ) = @_;
  return if $self->quiet || ${^GLOBAL_PHASE} eq 'DESTRUCT';
  return if ( $self->tasks->get( $self->id ) // {} )->{quiet};    # stopped quietly (Tasks/stop)
  my $recipient = $self->recipient;
  if ( $recipient ne 'main' ) {
    my $caller = $self->tasks->get($recipient);
    return unless $caller && $caller->{status} eq 'running';
  }
  $self->tasks->notify( $recipient, $text, id => $self->id, label => $label );
  return;
}

#### Ending


sub stop {
  my ( $self, $reason ) = @_;
  return if $self->_ended || $self->_reason;
  $reason //= 'stopped';
  # What was collected before the end is still delivered.
  unless ( $reason eq 'burst' || $reason eq 'total' ) {
    $self->_flush;
    return if $self->_ended || $self->_reason;    # it stopped itself: too many events
  }
  $self->_reason($reason);
  my $pid = $self->pid or return;
  $self->_signal('TERM');
  my $deadline = Time::HiRes::time() + $self->kill_grace;
  my $status;
  while (1) {
    my $got = waitpid( $pid, WNOHANG );
    if ( $got == $pid ) { $status = $?; last }
    if ( $got < 0 ) { last }    # reaped by the loop already
    if ( Time::HiRes::time() >= $deadline ) {
      $self->_signal('KILL');
      my $reaped = waitpid( $pid, 0 );
      $status = $? if $reaped == $pid;
      last;
    }
    Time::HiRes::sleep(0.02);
  }
  if ( $self->_watched ) {
    $self->_watched(0);
    eval { $self->loop->unwatch_process($pid) };
  }
  $self->_finish( $self->_outcome($status) );
  return;
}

sub _overflowed { my $reason = $_[0]->_reason // ''; return $reason eq 'burst' || $reason eq 'total' }

sub _signal {
  my ( $self, $signal ) = @_;
  my $pid = $self->pid or return;
  return kill( $signal => -$pid ) || kill( $signal => $pid );
}

# ( status, exit_code ) from a wait status; undef: it ended in a way we
# could not see (stopped).
sub _outcome {
  my ( $self, $wait ) = @_;
  return ( 'killed' ) if $self->_reason || !defined $wait;
  my $code = ( $wait & 127 ) ? 128 + ( $wait & 127 ) : $wait >> 8;
  return ( $code ? 'failed' : 'completed', $code );
}

# The end, once: what is left of the output is delivered, then the
# notification that says how it ended.
sub _finish {
  my ( $self, $status, $code ) = @_;
  return if $self->_ended;
  $self->_read;                          # what the command wrote last
  $self->_flush;
  return if $self->_ended;               # the flush stopped it: too many events
  $self->_ended(1);
  for my $timer ( map { $self->$_ } qw( _batch_timer _deadline_timer ) ) {
    eval { $self->loop->unwatch_time($timer) } if defined $timer;
  }
  $self->_close_handle;
  $self->status($status);
  $self->exit_code($code);
  $self->tasks->finish( $self->id, $status, ( defined $code ? ( exit_code => $code ) : () ) );
  $self->_deliver( $self->_ending_text($status), 'monitor '.$self->id.' ended' );
  $self->on_end->($self) if $self->on_end;
  return;
}

sub _ending_text {
  my ( $self, $status ) = @_;
  my $what   = 'Monitor "'.$self->description.'"';
  my $reason = $self->_reason // '';
  my ( $summary, $result );
  if ( $reason eq 'timeout' ) {
    $summary = $what.' timed out after '.$self->_span( $self->timeout );
    $result  = 'The watch ended at its deadline. Start it again with monitor if you still need it.';
  }
  elsif ( $reason eq 'burst' || $reason eq 'total' ) {
    $summary = $what.' was stopped: too many events';
    $result  = $reason eq 'burst'
      ? 'It sent more than '.$self->burst_limit.' notifications within '.$self->burst_window.' seconds.'
      : 'It sent more than '.$self->event_limit.' notifications.';
    $result .= ' Start it again with a command that prints less: filter the stream (grep --line-buffered) or print only what changed.';
  }
  elsif ( $status eq 'killed' ) {
    $summary = $what.' was stopped';
  }
  elsif ( $status eq 'failed' ) {
    $summary = $what.' failed with exit code '.$self->exit_code;
    $result  = $self->_stderr_tail;
  }
  else {
    $summary = $what.' ended (exit code '.( $self->exit_code // 0 ).')';
  }
  return $self->tasks->notification_text(
    task_id     => $self->id,
    tool_use_id => $self->tool_use_id,
    status      => $status,
    summary     => $summary,
    ( defined $result && length $result ? ( result => $result ) : () ),
  );
}

# The last lines the command wrote to standard error.
sub _stderr_tail {
  my ( $self ) = @_;
  my $file = $self->stderr_file or return;
  return unless -s "$file";
  my $text = eval { Encode::decode( 'UTF-8', $file->slurp_raw ) } // '';
  $text =~ s/\s+\z//;
  my @lines = split /\n/, $text;
  @lines = @lines[ -20 .. -1 ] if @lines > 20;
  $text = join "\n", @lines;
  $text = '... '.substr( $text, -2000 ) if length $text > 2000;
  return length $text ? $text : ();
}


sub _span {
  my ( $self, $seconds ) = @_;
  $seconds = int( $seconds + 0.5 ) if $seconds >= 1;
  return $seconds >= 60 && $seconds % 60 == 0 ? $seconds / 60 .'m' : $seconds.'s';
}

sub span { $_[0]->_span( $_[0]->timeout ) }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Monitor - Internal event stream of one background command: every stdout line becomes a notification

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $monitor = Langertha::Raider::Monitor->new(
      id          => $tasks->next_id('monitor'),
      loop        => $app->loop,
      tasks       => $app->tasks,
      command     => 'tail -f build.log | grep --line-buffered ERROR',
      description => 'errors in build.log',
      timeout     => 300,
      recipient   => 'main',
    );
    my $error = $monitor->start;          # undef, or why it could not start

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

One run of the C<monitor> tool (ADR 0031): a command that runs in the
background, in a process group of its own, with standard input from
F</dev/null>. Each line it writes to standard output is an I<event>; the
lines that come close together (L</batch_window>) are delivered as one
C<< <task-notification> >> to the run that started the monitor
(L<Langertha::Raider::Tasks/notify>), with the summary C<Monitor event:
"DESCRIPTION"> and the lines in an C<< <event> >> element. Standard error
is not an event; it is kept for the notification that ends the monitor with
a failure.

The monitor is an entry of the registry (kind C<monitor>, C<monitor_N>),
and it ends in exactly one of these ways, each with its own notification:

=over

=item * The command exits: C<completed> (exit code 0) or C<failed>.

=item * The deadline (L</timeout>) passes: the command is stopped, status
C<killed>, summary C<... timed out after Ns>, and a hint that it can be
started again.

=item * Too many events (L</burst_limit> notifications within
L</burst_window> seconds, or L</event_limit> in all): the command is
stopped and the notification says so and what to do about it.

=item * It is stopped from outside (C<kill_shell>, the run that started it
ended, raider leaves): C<killed>.

=back

=head2 id

=head2 command

=head2 description

Required: the registry ID (C<monitor_1>), the command (run with
C<bash -c>) and the description the notifications show.

=head2 loop

=head2 tasks

Required: the application's loop and registry.

=head2 recipient

The run the events go to: C<main>, or the agent ID of the subagent that
started the monitor. Nothing is delivered once that subagent has ended.

=head2 tool_use_id

The call that started it, for the C<tool-use-id> of the notifications.

=head2 working_directory

Where the command runs; raider's own directory without it.

=head2 stderr_file

A L<Path::Tiny> the command's standard error is written to. Without one it
is discarded.

=head2 timeout

Seconds the monitor may run (the caller has applied the limits of the
tool: 5 minutes by default, at most 30, at most 10 without a person).

=head2 batch_window

Seconds the lines that follow the first of a batch are collected: 0.2.

=head2 burst_limit

=head2 burst_window

More than C<burst_limit> notifications (20) within C<burst_window> seconds
(10) stop the monitor.

=head2 event_limit

More than this many event notifications (500) in all stop the monitor.

=head2 line_limit

=head2 batch_limit

A line is cut at C<line_limit> characters (2000), a batch at C<batch_limit>
(8000), each with a note.

=head2 kill_grace

Seconds between C<SIGTERM> and C<SIGKILL> when the command is stopped.

=head2 clock

A code reference for the time the burst window is measured with.

=head2 on_end

Called with the monitor when it has ended.

=head2 start

    my $error = $monitor->start;

Registers the entry, starts the command and the deadline. Returns undef, or
the reason the command could not be started.

=head2 stop

    $monitor->stop;                 # as asked from outside
    $monitor->stop('timeout');      # timeout, burst, total

Ends the command: C<SIGTERM> to its process group, C<SIGKILL> after
L</kill_grace> seconds, and the monitor with a C<killed> notification that
names the reason. Does nothing once the monitor has ended.

=head2 span

How long the monitor runs, as the tool says it: C<5m>, C<90s>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::BashTools>

=item * L<Langertha::Raider::Tasks>

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
