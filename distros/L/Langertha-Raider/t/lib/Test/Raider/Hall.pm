package Test::Raider::Hall;
# ABSTRACT: Halls with a fake raider for tests, which never disturb each other

use strict;
use warnings;
use Exporter 'import';
use File::Temp qw( tempdir );
use Path::Tiny;
use Scalar::Util qw( refaddr );
use Langertha::Raider::Hall;

our @EXPORT_OK = qw( fake_hall hall_events run_spawns wait_until reap_halls );

=head1 SYNOPSIS

    use lib 't/lib';
    use Test::Raider::Hall qw( fake_hall hall_events run_spawns wait_until );

    my ( $hall, $tmp ) = fake_hall( yml => "raiders:\n  bjorn: {}\n" );
    my @done = run_spawns( $hall, 2,
      { name => '1ivar', mission => 'alpha' },
      { name => '1ivar', mission => 'beta' } );

=head1 DESCRIPTION

Every L<Langertha::Raider::Hall> of a process shares one
L<IO::Async::Loop>, so raiders a subtest left running -- it failed, or ran
into its deadline -- would be reaped while the next subtest turns the
loop, and their C<raider.done> would count there. This module keeps them
apart:

=over

=item * L</fake_hall> first reaps every hall made before: waiting
missions are dropped, running raiders get TERM (KILL after a grace
period) and are reaped, so each subtest starts on a quiet loop. So does
C<END>.

=item * L</hall_events> records the events of one hall only; L</run_spawns>
counts on it, never on events of another hall.

=back

=cut

my @HALLS;
my %EVENTS;

# Record every hall's events for hall_events; a test's own local override
# of _emit still wraps this one.
{
  no warnings 'redefine';
  my $emit = \&Langertha::Raider::Hall::_emit;
  *Langertha::Raider::Hall::_emit = sub {
    my ( $self, $type, $data ) = @_;
    my $ret = $self->$emit( $type, $data );
    my $log = $EVENTS{ refaddr $self };
    push @$log, [ $type, { %$data } ] if $log;
    return $ret;
  };
}

my $LIB = path( $INC{'Langertha/Raider/Hall.pm'} )->absolute->parent(3);

# A stand-in for bin/raider that treats sessions the way the real one does:
# --session ID opens that journal for writing (exit 4 when another writer
# holds it, exit 2 when there is none), without it a new session is
# created in <--root>/.raider/sessions. It appends the mission as a
# message and ends with run.finished naming the session. Mission "hold"
# keeps the session open until the file in FAKE_RELEASE exists.
my $SESSION_FAKE = <<'PERL';
use strict;
use warnings;
use JSON::PP;
use Langertha::Raider::SessionStore;
my @argv = @ARGV;
open my $a, '>>', $ENV{FAKE_ARGV_LOG} or die $!;
print $a JSON::PP->new->canonical->encode([ @argv ]), "\n";
close $a;
my %opt;
while (@argv && $argv[0] ne '--') {
  my $o = shift @argv;
  $opt{$1} = shift @argv if $o =~ /^--(session|root)$/;
}
shift @argv;
my $mission = join ' ', @argv;
my $store = Langertha::Raider::SessionStore->new(root => $opt{root});
my $session;
if (defined $opt{session}) {
  unless ($store->exists($opt{session})) { print STDERR "unknown session $opt{session}\n"; exit 2 }
  $session = eval { $store->open($opt{session}) };
  unless ($session) { print STDERR "$@ by another raider\n"; exit 4 }
}
else {
  $session = $store->create;
}
my $run = $session->next_run;
$session->append('message', run => $run, role => 'user', content => $mission);
if ($mission eq 'hold') {
  my $until = time + 20;
  select undef, undef, undef, 0.05 until -e $ENV{FAKE_RELEASE} || time > $until;
}
$| = 1;
print JSON::PP->new->canonical->encode({ version => 1, type => 'run.finished', seq => 1, time => time,
  status => 'completed', response => 'answer: '.$mission,
  session => { id => $session->id, path => ''.$session->path } }), "\n";
exit 0;
PERL

=func fake_hall

    my ( $hall, $tmp ) = fake_hall( yml => $yml, script => $perl );

Reaps the halls made before (see L</reap_halls>), then a hall in a fresh
temp dir whose raider is C<script> (Perl source, run with this perl and
the hall's F<lib>; default: a session-aware fake that answers
C<answer: MISSION>, and holds on the mission C<hold> until the file in
C<FAKE_RELEASE> exists). C<yml> becomes F<.raider-hall.yml>. Sets
C<RAIDER_HALL_RAIDER_BIN>, C<FAKE_ARGV_LOG> and C<FAKE_RELEASE> to files in
the temp dir.

=cut

sub fake_hall {
  my ( %args ) = @_;
  reap_halls();
  my $tmp = path( tempdir( CLEANUP => 1 ) );
  $tmp->child('.raider-hall.yml')->spew_utf8( $args{yml} ) if defined $args{yml};
  my $bin = $tmp->child('fake-raider');
  $bin->spew_utf8( "#!$^X\nuse lib '".$LIB."';\n".( $args{script} // $SESSION_FAKE ) );
  $bin->chmod(0755);
  $ENV{RAIDER_HALL_RAIDER_BIN} = "$bin";
  $ENV{FAKE_ARGV_LOG} = $tmp->child('argv.jsonl')->stringify;
  $ENV{FAKE_RELEASE} = $tmp->child('release')->stringify;
  my $hall = Langertha::Raider::Hall->new( root => $tmp );
  hall_events($hall);
  return ( $hall, $tmp );
}

=func hall_events

    my $events = hall_events($hall);   # [ [ TYPE, { ... } ], ... ]

The events this hall emitted since it was first passed here (or made by
L</fake_hall>), as a live array ref. The hall is reaped with the others.

=cut

sub hall_events {
  my ( $hall ) = @_;
  my $key = refaddr $hall;
  push @HALLS, $hall unless $EVENTS{$key};
  return $EVENTS{$key} //= [];
}

=func run_spawns

    my @done = run_spawns( $hall, $n, @spawn_args );

Spawns each hash ref of arguments, then turns the loop until C<$n>
C<raider.done> of this hall arrived and it has no raider left (30s at
most). Returns their data.

=cut

sub run_spawns {
  my ( $hall, $n, @spawns ) = @_;
  my $events = hall_events($hall);
  my $from = @$events;
  $hall->spawn(%$_) for @spawns;
  my @done;
  wait_until( $hall, sub {
    @done = map { $_->[1] } grep { $_->[0] eq 'raider.done' } @$events[ $from .. $#$events ];
    !%{ $hall->raiders } && @done >= $n;
  } );
  return @done;
}

=func wait_until

    wait_until( $hall, sub { ... }, $seconds );

Turns the hall's loop until the condition holds or C<$seconds> (default
30) passed; returns the condition's last value.

=cut

sub wait_until {
  my ( $hall, $cond, $seconds ) = @_;
  my $deadline = time + ( $seconds // 30 );
  $hall->loop->loop_once(0.1) until $cond->() || time > $deadline;
  return $cond->();
}

=func reap_halls

Stops everything the recorded halls still have going: drops their waiting
missions, sends their running raiders TERM (KILL after 10s), turns the loop
until those are reaped and forgets the halls. Raider entries whose pid is
not a child of this process (a test's stand-in) are only removed, never
signalled.

=cut

sub reap_halls {
  while ( my $hall = shift @HALLS ) {
    delete $EVENTS{ refaddr $hall };
    %{ $hall->singleton_queues } = ();
    %{ $hall->binding_queues } = ();
    my @pids = grep { _own_child($_) } map { $_->pid // () } values %{ $hall->raiders };
    my $running = sub {
      my %pid = map { ( $_->pid // 0 ) => 1 } values %{ $hall->raiders };
      return grep { $pid{$_} } @pids;
    };
    for my $signal (qw( TERM KILL )) {
      last unless $running->();
      kill $signal, grep { _own_child($_) } $running->();
      wait_until( $hall, sub { !$running->() }, 10 );
    }
    %{ $hall->raiders } = ();
  }
  return;
}

sub _own_child {
  my ( $pid ) = @_;
  return 0 unless $pid && $pid > 0 && kill 0, $pid;
  return 1 unless -d '/proc/'.$$;
  my $stat = path( '/proc', $pid, 'stat' );
  return 0 unless -r $stat;
  my ($ppid) = $stat->slurp =~ /\)\s+\S+\s+(\d+)/;
  return ( $ppid // 0 ) == $$;
}

END { local $?; reap_halls() }

1;
