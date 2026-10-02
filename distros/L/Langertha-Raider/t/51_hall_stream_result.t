#!/usr/bin/env perl
# ABSTRACT: the Hall runs raiders with --stream-json and takes the result from run.finished

use strict;
use warnings;
use utf8;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::Hall qw( hall_events wait_until );
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::ACP;
use Langertha::Raider::Hall::Raider;

clear_engine_env();

my $repo = path(__FILE__)->absolute->parent->parent;

# A stand-in for bin/raider. It records its argv, writes noise to stderr
# and, depending on the mission, a --stream-json event stream to stdout:
#   silent  - nothing on stdout, exit 0
#   noisy   - non-JSON text on stdout around the events
#   killed  - one event, then SIGKILL on itself before run.finished
#   twice   - two run.finished events, the last one counts
#   wait    - one event, then waits for a signal: SIGINT ends it cancelled,
#             SIGTERM interrupted, each with run.finished and death by the
#             signal (unblocked first), as bin/raider does; FAKE_RELEASE is
#             touched once waiting
#   *       - run.started, message, run.finished with "answer: MISSION"
my $FAKE = <<'PERL';
use strict;
use warnings;
use JSON::PP;
use POSIX qw( sigprocmask SIG_UNBLOCK SIGINT SIGTERM );
my $mission = $ARGV[-1];
open my $a, '>>', $ENV{FAKE_ARGV_LOG} or die $!;
print $a JSON::PP->new->canonical->encode([ @ARGV ]), "\n";
close $a;
$| = 1;
my $json = JSON::PP->new->canonical->utf8;
my $seq = 0;
sub event { my ( $type, %p ) = @_; print $json->encode({ version => 1, type => $type, seq => ++$seq, time => time, %p }), "\n" }
print STDERR "warning: some diagnostic noise\n";
print STDERR qq({"type":"run.finished","status":"completed","response":"stderr is not the stream"}\n);
exit 0 if $mission eq 'silent';
print "plain text on stdout\n" if $mission eq 'noisy';
event('run.started');
if ( $mission eq 'killed' ) { kill 'KILL', $$; sleep 5 }
if ( $mission eq 'wait' ) {
  for my $sig (qw( INT TERM )) {
    $SIG{$sig} = sub {
      event('run.finished', status => $sig eq 'INT' ? 'cancelled' : 'interrupted',
        $sig eq 'TERM' ? ( signal => 'TERM' ) : (), elapsed => 0.3);
      $SIG{$sig} = 'DEFAULT';
      # Perl blocks the signal while its handler runs; unblock it, as
      # bin/raider does, or it only lands once the handler is left.
      sigprocmask( SIG_UNBLOCK, POSIX::SigSet->new( $sig eq 'INT' ? SIGINT : SIGTERM ) );
      kill $sig, $$;
      sleep 5;
      exit 1;
    };
  }
  open my $r, '>', $ENV{FAKE_RELEASE} or die $!;
  close $r;
  sleep 30;
  exit 1;
}
event('message', text => 'thinking');
event('run.finished', status => 'completed', response => 'first', elapsed => 0.1) if $mission eq 'twice';
print "{broken json\n" if $mission eq 'noisy';
event('run.finished', status => 'completed', response => 'answer: '.$mission, metrics => {}, elapsed => 0.2);
print "trailing noise\n" if $mission eq 'noisy';
exit 0;
PERL

sub fake_hall {
  my ( $yml ) = @_;
  return Test::Raider::Hall::fake_hall( script => $FAKE, yml => $yml );
}

# Spawn and turn the loop until the hall has reaped every raider; returns
# the raider.done events emitted meanwhile.
sub run_spawns {
  my ( $hall, @spawns ) = @_;
  return Test::Raider::Hall::run_spawns( $hall, scalar @spawns, @spawns );
}

subtest 'run_finished reads the last run.finished of the events file' => sub {
  my $tmp = path( tempdir( CLEANUP => 1 ) );
  my $events = $tmp->child('x.events.jsonl');
  my $raider = sub {
    Langertha::Raider::Hall::Raider->new(
      id => 'x-1', slot_name => 'x', base_name => 'x', mission => 'm',
      log_path => $tmp->child('x.log'), @_ );
  };
  is( $raider->()->run_finished, undef, 'no events path: undef' );
  is( $raider->( events_path => $events )->run_finished, undef, 'missing file: undef' );

  $events->spew_raw( qq({"version":1,"type":"run.started","seq":1,"time":1}\n) );
  is( $raider->( events_path => $events )->run_finished, undef, 'no run.finished: undef' );

  $events->spew_raw( join "\n",
    'noise',
    qq({"version":1,"type":"run.finished","seq":2,"time":1,"status":"completed","response":"old"}),
    '{half',
    'more noise', '' );
  my $bytes = qq({"version":1,"type":"run.finished","seq":3,"time":2,"status":"completed","response":"Gr\xc3\xbc\xc3\x9fe"}\n);
  $events->append_raw($bytes);
  is( $raider->( events_path => $events )->run_finished,
    { version => 1, status => 'completed', response => 'Grüße' },
    'last event wins, UTF-8 decoded, event fields stripped' );
};

subtest 'bin/raider --stream-json stdout gives a run.finished the Hall reads' => sub {
  my $tmp = path( tempdir( CLEANUP => 1 ) );
  my $events = $tmp->child('r.events.jsonl');
  my $log = $tmp->child('r.log');
  my @cmd = ( $^X, '-I'.$repo->child('lib'), $repo->child('bin', 'raider')->stringify,
    '--stream-json', '-e', 'openai', '-k', 'test', '-r', "$tmp",
    '-o', 'url=http://127.0.0.1:1', '--', 'hi' );
  my $q = join ' ', map { "'$_'" } @cmd;
  `$q >'$events' 2>>'$log' </dev/null`;
  is( $? >> 8, 1, 'unreachable engine: run failed' );
  my $doc = Langertha::Raider::Hall::Raider->new(
    id => 'r-1', slot_name => 'r', base_name => 'r', mission => 'hi',
    log_path => $log, events_path => $events )->run_finished;
  is( $doc, hash {
    field version => 1;
    field status  => 'failed';
    field error   => T();
    etc;
  }, 'the failure document' );
};

subtest 'spawn uses --stream-json and a per-run events file' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my ($done) = run_spawns( $hall, { name => 'bjorn', mission => 'hello' } );
  my ($argv) = map { JSON::MaybeXS->new->decode($_) } path( $ENV{FAKE_ARGV_LOG} )->lines;
  ok( ( grep { $_ eq '--stream-json' } @$argv ), 'raider started with --stream-json' );
  ok( !( grep { $_ eq '--json' } @$argv ), 'not with --json' );
  is( $done->{status}, 'completed', 'status from run.finished' );
  is( $done->{response}, 'answer: hello', 'response from run.finished' );
  ok( !exists $done->{error}, 'no error' );
  my $logs = $tmp->child( '.raider-hall', 'logs' );
  like( $logs->child('bjorn.log')->slurp_utf8, qr/some diagnostic noise/, 'stderr goes to the log' );
  unlike( $logs->child('bjorn.log')->slurp_utf8, qr/run\.started/, 'the stream does not' );
  ok( $logs->child( $done->{id}.'.events.jsonl' )->exists, 'events file named after the run' );
};

subtest 'a reused slot never returns the previous result' => sub {
  my ( $hall ) = fake_hall();
  my ($first) = run_spawns( $hall, { name => 'bjorn', mission => 'one' } );
  is( $first->{response}, 'answer: one', 'first run' );
  my ($second) = run_spawns( $hall, { name => 'bjorn', mission => 'silent' } );
  is( $second->{status}, 'failed', 'second run without run.finished failed' );
  ok( !exists $second->{response}, 'no stale response' );
  like( $second->{error}, qr/ended without a result \(exit code 0\)/, 'says why' );

  my @queued = run_spawns( $hall,
    { name => '1ivar', mission => 'alpha' },
    { name => '1ivar', mission => 'beta' } );
  is( [ map { $_->{response} } @queued ], [ 'answer: alpha', 'answer: beta' ],
    'singleton queue: each run gets its own result' );
};

subtest 'stdout noise and several run.finished events' => sub {
  my ( $hall ) = fake_hall();
  my ($noisy) = run_spawns( $hall, { name => 'bjorn', mission => 'noisy' } );
  is( $noisy->{response}, 'answer: noisy', 'non-JSON lines are skipped' );
  my ($twice) = run_spawns( $hall, { name => 'bjorn', mission => 'twice' } );
  is( $twice->{response}, 'answer: twice', 'the last run.finished counts' );
};

subtest 'a killed raider is a clear failure, not raw text' => sub {
  my ( $hall ) = fake_hall();
  my ($done) = run_spawns( $hall, { name => 'bjorn', mission => 'killed' } );
  is( $done->{signaled}, 1, 'signaled' );
  is( $done->{status}, 'failed', 'failed' );
  like( $done->{error}, qr/^raider bjorn-\d+ ended without a result \(killed by signal 9\)$/,
    'error names the run and the signal' );
};

subtest 'the slot log ends each run with a readable result line' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my $log = $tmp->child( '.raider-hall', 'logs', 'bjorn.log' );
  my ($ok) = run_spawns( $hall, { name => 'bjorn', mission => "two\nlines" } );
  my @lines = $log->lines_utf8({ chomp => 1 });
  is( $lines[-1], '[hall] raider '.$ok->{id}.' completed: answer: two lines',
    'status and response, whitespace folded onto one line, last in the log' );

  my ($fail) = run_spawns( $hall, { name => 'bjorn', mission => 'killed' } );
  @lines = $log->lines_utf8({ chomp => 1 });
  is( $lines[-1], '[hall] raider '.$fail->{id}.' failed: '.$fail->{error},
    'a failure line carries the error' );

  my ($long) = run_spawns( $hall, { name => 'bjorn', mission => 'x' x 2000 } );
  @lines = $log->lines_utf8({ chomp => 1 });
  like( $lines[-1], qr/^\[hall\] raider \Q$long->{id}\E completed: answer: x+\.\.\.$/,
    'a long response is cut' );
  cmp_ok( length $lines[-1], '<', 400, 'to a short line' );
  is( scalar( grep { /^\[hall\] raider \S+ \w+: / } @lines ), 3, 'one result line per run' );
};

subtest 'unnumbered names run in parallel, each run is reaped' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my @done = run_spawns( $hall,
    { name => 'bjorn', mission => 'alpha' },
    { name => 'bjorn', mission => 'beta' } );
  is( scalar @done, 2, 'a raider.done for each run' );
  is( [ sort map { $_->{response} } @done ], [ 'answer: alpha', 'answer: beta' ],
    'each run with its own result' );
  isnt( $done[0]{id}, $done[1]{id}, 'distinct run IDs' );
  is( [ map { $_->{slot} } @done ], [ 'bjorn', 'bjorn' ], 'same slot' );
  is( $hall->raiders, {}, 'both left the table' );
  my $log = $tmp->child( '.raider-hall', 'logs', 'bjorn.log' )->slurp_utf8;
  like( $log, qr/^\[hall\] raider \Q$_->{id}\E completed: /m, 'result line of '.$_->{id} ) for @done;

  my @ids = map { $hall->spawn( name => 'bjorn', mission => $_ )->{id} } 'one', 'two';
  is( [ sort map { $_->{id} } $hall->ps ], [ sort @ids ], 'ps lists both running runs' );
  is( $hall->mcp_adapter->handle_tool_call('hall_status')->{slots}, ['bjorn'],
    'status names the slot once' );
  my @more = run_spawns($hall);
  is( [ sort map { $_->{id} } @more ], [ sort @ids ], 'both reaped' );
};

subtest 'the slot log marks the start of each run, logs ID shows only that run' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my $log = $tmp->child( '.raider-hall', 'logs', 'bjorn.log' );
  $log->parent->mkpath;
  $log->spew_utf8("legacy line without a marker\n");
  my $running = $hall->spawn( name => 'bjorn', mission => 'one' );
  like( $log->slurp_utf8, qr/^\[hall\] raider \Q$running->{id}\E started$/m, 'start marker' );
  like( $hall->logs( id => $running->{id} )->{log}, qr/\A\[hall\] raider \Q$running->{id}\E started\n/,
    'running: the section starts at the marker' );
  my ($one) = run_spawns($hall);
  my ($two) = run_spawns( $hall, { name => 'bjorn', mission => 'two' } );

  my $first = $hall->logs( id => $one->{id} )->{log};
  like( $first, qr/\A\[hall\] raider \Q$one->{id}\E started\n/, 'starts at its marker' );
  like( $first, qr/some diagnostic noise/, 'holds its stderr' );
  like( $first, qr/^\[hall\] raider \Q$one->{id}\E completed: answer: one\n\z/m, 'ends with its result line' );
  unlike( $first, qr/legacy line|\Q$two->{id}\E /, 'nothing before or after the run' );

  my $second = $hall->logs( id => $two->{id} )->{log};
  like( $second, qr/\A\[hall\] raider \Q$two->{id}\E started\n.*completed: answer: two\n\z/s,
    'the second run alone' );
  unlike( $second, qr/\Q$one->{id}\E /, 'without the first' );

  my $logs = $tmp->child( '.raider-hall', 'logs' );
  $logs->child('bjorn-7.events.jsonl')->spew_utf8("\n");
  like( $hall->logs( id => 'bjorn-7' )->{log}, qr/\Alegacy line.*answer: two/s,
    'no marker (older run): the whole slot log' );
};

subtest 'run IDs stay unique within the same second' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my $logs = $tmp->child( '.raider-hall', 'logs' );
  $logs->mkpath;
  my $now = time;
  my %taken = map { ( "bjorn-$_" => 1 ) } $now .. $now + 5;
  $logs->child("$_.events.jsonl")->spew_utf8("keep\n") for keys %taken;
  my ($done) = run_spawns( $hall, { name => 'bjorn', mission => 'hello' } );
  like( $done->{id}, qr/^bjorn-\d+\.\d+$/, 'a taken ID gets a counter suffix' );
  ok( !$taken{ $done->{id} }, 'no existing ID reused' );
  is( $done->{response}, 'answer: hello', 'the run reads its own events' );
  is( [ grep { $_->slurp_utf8 ne "keep\n" } map { $logs->child("$_.events.jsonl") } keys %taken ],
    [], 'earlier events files untouched' );

  my @queued = run_spawns( $hall,
    { name => '1ivar', mission => 'alpha' },
    { name => '1ivar', mission => 'beta' } );
  isnt( $queued[0]{id}, $queued[1]{id}, 'back-to-back queued runs get distinct IDs' );
  is( Langertha::Raider::Hall::Raider->new( id => 'x', slot_name => 'x', base_name => 'x',
      mission => 'm', log_path => $tmp->child('x.log'),
      events_path => $logs->child( $queued[0]{id}.'.events.jsonl' ) )->run_finished->{response},
    'answer: alpha', 'the first run keeps its own events file' );
};

subtest 'only the newest events files of a slot are kept' => sub {
  my ( $hall, $tmp ) = fake_hall("logs:\n  keep_events: 2\n");
  my $logs = $tmp->child( '.raider-hall', 'logs' );
  $logs->mkpath;
  my @foreign = map { $logs->child($_) }
    'bjorn-x-100.events.jsonl', 'bjorn-5-100.events.jsonl', 'other-100.events.jsonl', 'bjorn.log.keep';
  $_->spew_utf8("foreign\n") for @foreign;
  $logs->child('bjorn-100.events.jsonl')->spew_utf8("old\n");
  my @done = map { run_spawns( $hall, { name => 'bjorn', mission => "run$_" } ) } 1 .. 3;
  my @left = sort map { $_->basename } grep { $_->basename =~ /^bjorn-\d+(?:\.\d+)?\.events\.jsonl$/ } $logs->children;
  is( \@left, [ sort map { $_->{id}.'.events.jsonl' } @done[ 1, 2 ] ], 'the last two runs remain' );
  ok( ( !grep { !$_->exists } @foreign ), 'other slots and other files untouched' );
  ok( $logs->child('bjorn.log')->exists, 'the slot log stays' );
};

subtest 'events files are kept by default, keep_events 0 keeps all' => sub {
  for my $yml ( undef, "logs:\n  keep_events: 0\n" ) {
    my ( $hall, $tmp ) = fake_hall($yml);
    my $logs = $tmp->child( '.raider-hall', 'logs' );
    $logs->mkpath;
    $logs->child("bjorn-$_.events.jsonl")->spew_utf8("old\n") for 100 .. 124;
    run_spawns( $hall, { name => 'bjorn', mission => 'hello' } );
    my $n = grep { $_->basename =~ /^bjorn-.*\.events\.jsonl$/ } $logs->children;
    is( $n, defined $yml ? 26 : 20, defined $yml ? 'keep_events 0: nothing removed' : 'default: the last 20' );
  }
};

subtest 'a large slot log is rotated when the next run starts' => sub {
  my ( $hall, $tmp ) = fake_hall("logs:\n  max_log_size: 100\n");
  my $logs = $tmp->child( '.raider-hall', 'logs' );
  $logs->mkpath;
  my $log = $logs->child('bjorn.log');
  $log->spew_utf8( "old run\n" x 20 );
  $logs->child('bjorn.log.1')->spew_utf8("older\n");
  my ($done) = run_spawns( $hall, { name => 'bjorn', mission => 'hello' } );
  is( $logs->child('bjorn.log.1')->slurp_utf8, "old run\n" x 20, 'the full log moved to SLOT.log.1' );
  unlike( $log->slurp_utf8, qr/old run/, 'the new log starts empty' );
  like( $log->slurp_utf8, qr/^\[hall\] raider \Q$done->{id}\E completed/m, 'and holds the new run' );

  $log->spew_utf8("small\n");
  run_spawns( $hall, { name => 'bjorn', mission => 'hello' } );
  like( $log->slurp_utf8, qr/^small$/m, 'a log under the limit stays' );
  is( $logs->child('bjorn.log.1')->slurp_utf8, "old run\n" x 20, 'SLOT.log.1 untouched' );
};

subtest 'no rotation while a raider of the slot still writes the log' => sub {
  my ( $hall, $tmp ) = fake_hall("logs:\n  max_log_size: 10\n");
  my $logs = $tmp->child( '.raider-hall', 'logs' );
  $logs->mkpath;
  $logs->child('bjorn.log')->spew_utf8( "busy\n" x 10 );
  $hall->raiders->{bjorn} = Langertha::Raider::Hall::Raider->new(
    id => 'bjorn-1', slot_name => 'bjorn', base_name => 'bjorn', mission => 'm',
    log_path => $logs->child('bjorn.log') );
  $hall->_rotate_log('bjorn');
  ok( !$logs->child('bjorn.log.1')->exists, 'occupied slot: not rotated' );
  $hall->raiders->{'bjorn-2'} = delete $hall->raiders->{bjorn};
  $hall->_rotate_log('bjorn');
  ok( !$logs->child('bjorn.log.1')->exists, 'occupied slot, entry under its run ID: not rotated' );
  delete $hall->raiders->{'bjorn-2'};
  $hall->_rotate_log('bjorn');
  ok( $logs->child('bjorn.log.1')->exists, 'free slot: rotated' );
};

subtest 'max_log_size: default and 0' => sub {
  my ( $hall ) = fake_hall();
  is( $hall->max_log_size, 1024 * 1024, 'default 1 MiB' );
  my ( $off, $tmp ) = fake_hall("logs:\n  max_log_size: 0\n");
  my $logs = $tmp->child( '.raider-hall', 'logs' );
  $logs->mkpath;
  $logs->child('bjorn.log')->spew_utf8( 'x' x 5000 );
  $off->_rotate_log('bjorn');
  ok( !$logs->child('bjorn.log.1')->exists, '0 never rotates' );
};

subtest 'logs ID after the run ended' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my ($done) = run_spawns( $hall, { name => 'bjorn', mission => 'hello' } );
  my $res = $hall->logs( id => $done->{id} );
  ok( !$res->{error}, 'found after the raider left the table' );
  like( $res->{log}, qr/some diagnostic noise/, 'the slot log' );
  like( $res->{log}, qr/^\[hall\] raider \Q$done->{id}\E completed: answer: hello$/m, 'with its result line' );

  my ($two) = run_spawns( $hall, { name => '1ivar', mission => 'alpha' } );
  my $logs = $tmp->child( '.raider-hall', 'logs' );
  $logs->child('1ivar.log')->remove;
  is( $hall->logs( id => $two->{id} )->{log},
    '[hall] raider '.$two->{id}.' completed: answer: alpha'."\n",
    'no slot log: the result from the events file' );

  $logs->child('bjorn-7.events.jsonl')->spew_utf8("\n");
  $logs->child('bjorn-7.2.events.jsonl')->spew_utf8("\n");
  ok( !$hall->logs( id => 'bjorn-7.2' )->{error}, 'SLOT-TIME.N resolves to its slot' );
  like( $hall->logs( id => 'bjorn-7.2' )->{log}, qr/answer: hello/, 'and shows the slot log' );

  for my $id ( 'bjorn-8', 'nope-1', 'bjorn', '../bjorn-7', 'x/../bjorn-7', '' ) {
    is( $hall->logs( id => $id ), { error => 'raider not found' }, 'unknown: '.$id );
  }
};

{
  package CaptureStream;
  sub new { bless { lines => [] }, shift }
  sub write { push @{ $_[0]{lines} }, JSON::MaybeXS->new->decode( $_[1] ); 1 }
}

sub acp_prompt {
  my ( $mission ) = @_;
  my ( $hall, $tmp ) = fake_hall();
  $tmp->child('.raider-hall.yml')->spew_utf8("raiders:\n  bjorn: {}\n");
  $hall = Langertha::Raider::Hall->new( root => $tmp );
  hall_events($hall);
  my $acp = Langertha::Raider::Hall::ACP->new( hall => $hall, port => 0, host => '127.0.0.1' );
  my $stream = CaptureStream->new;
  $acp->_sessions->{s1} = { stream => $stream, raider_name => 'bjorn' };
  $acp->_session_prompt( $stream, 7, { sessionId => 's1', prompt => [ { type => 'text', text => $mission } ] } );
  wait_until( $hall, sub { grep { ( $_->{id} // 0 ) == 7 } @{ $stream->{lines} } } );
  my @chunks = map { $_->{params}{update}{content}{text} }
    grep { ( $_->{method} // '' ) eq 'session/update' } @{ $stream->{lines} };
  my ($reply) = grep { ( $_->{id} // 0 ) == 7 } @{ $stream->{lines} };
  return ( $chunks[-1], $reply->{result}{stopReason} );
}

subtest 'ACP forwards the response of run.finished' => sub {
  my ( $text, $stop ) = acp_prompt('hello');
  is( $text, 'answer: hello', 'response as the last chunk' );
  is( $stop, 'end_turn', 'end_turn' );
};

subtest 'ACP forwards a clear error when the raider was killed' => sub {
  my ( $text, $stop ) = acp_prompt('killed');
  like( $text, qr/ended without a result \(killed by signal 9\)/, 'error, not raw log text' );
  unlike( $text, qr/run\.started|diagnostic noise/, 'no stream or stderr content' );
  is( $stop, 'cancelled', 'signaled: cancelled' );
};

subtest 'ACP maps an interrupted run to cancelled' => sub {
  my $hall = Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ) );
  my $acp = Langertha::Raider::Hall::ACP->new( hall => $hall, port => 0, host => '127.0.0.1' );
  my $stream = CaptureStream->new;
  my $session = { stream => $stream, raider_name => 'bjorn', pending_request_id => 9 };
  $acp->_sessions->{s1} = $session;
  $acp->_attach_subscription( $session, 'bjorn-1', $stream );
  $hall->_emit( 'raider.done', { id => 'bjorn-1', exit_code => 0, signaled => 0,
    status => 'interrupted', error => 'interrupted by SIGTERM' } );
  my ($reply) = grep { ( $_->{id} // 0 ) == 9 } @{ $stream->{lines} };
  is( $reply->{result}{stopReason}, 'cancelled', 'interrupted: cancelled' );
};

subtest 'ACP maps a cancelled run to cancelled, signalled or not' => sub {
  for my $signaled ( 0, 1 ) {
    my $hall = Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ) );
    my $acp = Langertha::Raider::Hall::ACP->new( hall => $hall, port => 0, host => '127.0.0.1' );
    my $stream = CaptureStream->new;
    my $session = { stream => $stream, raider_name => 'bjorn', pending_request_id => 9 };
    $acp->_sessions->{s1} = $session;
    $acp->_attach_subscription( $session, 'bjorn-1', $stream );
    $hall->_emit( 'raider.done', { id => 'bjorn-1', exit_code => 0, signaled => $signaled, status => 'cancelled' } );
    my ($reply) = grep { ( $_->{id} // 0 ) == 9 } @{ $stream->{lines} };
    is( $reply->{result}{stopReason}, 'cancelled', 'cancelled, signaled '.$signaled );
  }
};

# A hall whose bjorn waits for a signal (mission "wait"), turned until it
# does; returns the hall and its events.
sub waiting_hall {
  my ( $hall, $tmp ) = fake_hall("raiders:\n  bjorn: {}\n");
  return ( $hall, hall_events($hall) );
}

sub wait_ready {
  my ( $hall ) = @_;
  ok( wait_until( $hall, sub { -e $ENV{FAKE_RELEASE} } ), 'the raider waits for a signal' );
}

subtest 'ACP session/cancel sends the running raider SIGINT' => sub {
  my ( $hall, $events ) = waiting_hall();
  my $acp = Langertha::Raider::Hall::ACP->new( hall => $hall, port => 0, host => '127.0.0.1' );
  my $stream = CaptureStream->new;
  $acp->_sessions->{s1} = { stream => $stream, raider_name => 'bjorn' };
  $acp->_session_prompt( $stream, 7, { sessionId => 's1', prompt => [ { type => 'text', text => 'wait' } ] } );
  wait_ready($hall);
  $acp->_session_cancel( $stream, 8, { sessionId => 's1' } );
  wait_until( $hall, sub { grep { ( $_->{id} // 0 ) == 7 } @{ $stream->{lines} } } );
  my ($reply) = grep { ( $_->{id} // 0 ) == 7 } @{ $stream->{lines} };
  is( $reply->{result}{stopReason}, 'cancelled', 'the prompt: cancelled' );
  my ($done) = map { $_->[1] } grep { $_->[0] eq 'raider.done' } @$events;
  like( $done, { status => 'cancelled', signaled => 1 }, 'the raider ended its run cancelled, by SIGINT' );
};

subtest 'kill_raider still sends SIGTERM' => sub {
  my ( $hall, $events ) = waiting_hall();
  my $spawn = $hall->spawn( name => 'bjorn', mission => 'wait' );
  wait_ready($hall);
  is( $hall->kill_raider( $spawn->{id} ), { killed => 1, id => $spawn->{id} }, 'killed' );
  wait_until( $hall, sub { !%{ $hall->raiders } } );
  my ($done) = map { $_->[1] } grep { $_->[0] eq 'raider.done' } @$events;
  like( $done, { status => 'interrupted', signaled => 1 }, 'the raider ended its run interrupted, by SIGTERM' );
};

done_testing;
