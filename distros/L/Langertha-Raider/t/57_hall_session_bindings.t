#!/usr/bin/env perl
# ABSTRACT: the Hall binds its runs to sessions (ADR 0015, Hall bindings)

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::Hall qw( fake_hall hall_events run_spawns wait_until );
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::ACP;
use Langertha::Raider::Hall::Cron;
use Langertha::Raider::Hall::Telegram;
use Langertha::Raider::SessionStore;

clear_engine_env();

my $repo = path(__FILE__)->absolute->parent->parent;

sub argvs {
  my $log = path( $ENV{FAKE_ARGV_LOG} );
  return [] unless -f $log;
  return [ map { JSON::MaybeXS->new->decode($_) } $log->lines ];
}

sub session_flag {
  my ( $argv ) = @_;
  for my $i ( 0 .. $#$argv ) {
    last if $argv->[$i] eq '--';
    return $argv->[ $i + 1 ] if $argv->[$i] eq '--session';
  }
  return;
}

sub store_of { Langertha::Raider::SessionStore->new( root => ''.$_[0] ) }

subtest 'a numbered slot keeps one session across its queued missions' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my @done = run_spawns( $hall, 2,
    { name => '1ivar', mission => 'alpha' },
    { name => '1ivar', mission => 'beta' } );
  is( [ map { $_->{response} } @done ], [ 'answer: alpha', 'answer: beta' ], 'both ran' );
  my @ids = map { session_flag($_) } @{ argvs() };
  is( scalar @ids, 2, 'both started with --session' );
  is( $ids[0], $ids[1], 'the same session' );
  is( [ map { $_->{session} } @done ], [ @ids ], 'raider.done names the session' );

  my $store = store_of($tmp);
  ok( $store->exists( $ids[0] ), 'the journal lives in the hall root as project' );
  my $journal = $store->read( $ids[0] );
  is( $journal->created->{root}, $tmp->absolute->stringify, 'session.created: root is the hall root' );
  is( [ map { $_->{content} } grep { $_->{type} eq 'message' } @{ $journal->events } ],
    [ 'alpha', 'beta' ], 'the second mission continued the first' );

  my $map = JSON::MaybeXS->new->decode( $tmp->child( '.raider-hall', 'state', 'sessions.json' )->slurp_utf8 );
  is( $map, { 'slot:1ivar' => $ids[0] }, 'binding map in the hall directory' );

  my ($later) = run_spawns( Langertha::Raider::Hall->new( root => $tmp ), 1,
    { name => '1ivar', mission => 'gamma' } );
  is( $later->{session}, $ids[0], 'a restarted hall continues the binding' );
};

subtest 'a plain name gets a fresh session per run' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my @done = run_spawns( $hall, 2,
    { name => 'bjorn', mission => 'one' },
    { name => 'bjorn', mission => 'two' } );
  is( [ grep { defined } map { session_flag($_) } @{ argvs() } ], [], 'no --session' );
  ok( ( !grep { !defined $_->{session} } @done ), 'raider.done names the session from run.finished' );
  isnt( $done[0]{session}, $done[1]{session}, 'never shared' );
  ok( !-e $tmp->child( '.raider-hall', 'state', 'sessions.json' ), 'nothing bound' );
};

subtest 'an explicit binding wins over the slot, a lost journal is replaced' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my ($slot) = run_spawns( $hall, 1, { name => '1ivar', mission => 'a' } );
  my ($cron) = run_spawns( $hall, 1, { name => '1ivar', mission => 'b', binding => 'cron:nightly' } );
  isnt( $cron->{session}, $slot->{session}, 'the cron job has its own session' );
  my ($again) = run_spawns( $hall, 1, { name => '1ivar', mission => 'c', binding => 'cron:nightly' } );
  is( $again->{session}, $cron->{session}, 'and continues it' );

  store_of($tmp)->path_of( $cron->{session} )->remove;
  my ($fresh) = run_spawns( $hall, 1, { name => '1ivar', mission => 'd', binding => 'cron:nightly' } );
  is( $fresh->{status}, 'completed', 'a binding whose journal is gone still runs' );
  isnt( $fresh->{session}, $cron->{session}, 'in a new session' );
  is( $hall->session_bindings->{'cron:nightly'}, $fresh->{session}, 'which the binding now names' );
};

subtest 'a mission for a busy binding waits for it (ADR 0003: new input is queued)' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my $events = hall_events($hall);
  my $binding = 'telegram:ops:42';
  my $first = $hall->spawn( name => 'bjorn', mission => 'hold', binding => $binding );
  my $info = $hall->attach( $first->{id} );
  ok( $info->{session}, 'attach names the session' );
  is( $info->{binding}, $binding, 'and the binding' );
  like( $first->{events_path}, qr/\Q$first->{id}\E\.events\.jsonl\z/, 'the spawn reply names the events file' );
  is( $info->{events_path}, $first->{events_path}, 'the one attach follows' );
  is( ( $hall->ps )[0]{session}, $info->{session}, 'ps names it too' );

  my $second = $hall->spawn( name => 'bjorn', mission => 'late', binding => $binding );
  is( $second, { queued => 1, slot => 'bjorn', binding => $binding, queue_depth => 1 },
    'queued on the binding' );
  my ($queued) = grep { $_->[0] eq 'raider.queued' } @$events;
  is( $queued->[1]{binding}, $binding, 'raider.queued names the binding' );
  my $file = $tmp->child( '.raider-hall', 'state', 'binding_queues.json' );
  is( JSON::MaybeXS->new->decode( $file->slurp_utf8 )->{$binding}[0]{mission}, 'late',
    'persisted in the hall directory' );

  my $other = $hall->spawn( name => 'bjorn', mission => 'elsewhere', binding => 'telegram:ops:43' );
  ok( $other->{id}, 'another binding of the same name runs at once' );
  my $plain = $hall->spawn( name => 'bjorn', mission => 'unbound' );
  ok( $plain->{id}, 'so does an unbound plain-name run' );
  is( scalar keys %{ $hall->raiders }, 3, 'three in parallel' );

  path( $ENV{FAKE_RELEASE} )->touch;
  wait_until( $hall, sub { !%{ $hall->raiders } && 4 == grep { $_->[0] eq 'raider.done' } @$events }, 40 );

  my @done = map { $_->[1] } grep { $_->[0] eq 'raider.done' } @$events;
  is( [ grep { $_->{status} ne 'completed' } @done ], [], 'every run completed, none hit the lock' );
  my ($late) = grep { ( $_->{response} // '' ) eq 'answer: late' } @done;
  is( $late->{session}, $info->{session}, 'the queued mission ran in the binding\'s session' );
  is( [ map { $_->{content} } grep { $_->{type} eq 'message' }
      @{ store_of($tmp)->read( $info->{session} )->events } ],
    [ 'hold', 'late' ], 'after the first one' );
  is( JSON::MaybeXS->new->decode( $file->slurp_utf8 ), {}, 'queue drained' );
};

subtest 'a session held outside the hall still fails loudly (exit 4)' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my $binding = 'telegram:ops:42';
  my $id = $hall->session_for($binding);
  my $held = store_of($tmp)->open($id);
  my ($late) = run_spawns( $hall, 1, { name => 'bjorn', mission => 'late', binding => $binding } );
  is( $late->{status}, 'failed', 'the colliding run failed' );
  is( $late->{exit_code}, 4, 'raider exited 4' );
  is( $late->{session}, $id, 'raider.done names the session' );
  is( $late->{error},
    'session '.$id.' of '.$binding.' is in use by another run; mission not run',
    'with a clear message' );
  $held->release;
  is( [ grep { $_->{type} eq 'message' } @{ store_of($tmp)->read($id)->events } ], [],
    'the journal was not touched' );
};

subtest 'a binding queue survives a hall restart' => sub {
  my ( $hall, $tmp ) = fake_hall();
  $hall->raiders->{busy} = Langertha::Raider::Hall::Raider->new(
    id => 'bjorn-1', pid => 2**22 + 12345, slot_name => 'bjorn', base_name => 'bjorn',
    mission => 'm', log_path => $tmp->child('x.log'),
    session_id => $hall->session_for('cron:nightly'), binding => 'cron:nightly' );
  ok( $hall->spawn( name => 'bjorn', mission => 'next', binding => 'cron:nightly' )->{queued}, 'queued' );

  my $restarted = Langertha::Raider::Hall->new( root => $tmp );
  my $events = hall_events($restarted);
  $restarted->_drain_binding_queues;
  my @done;
  wait_until( $restarted, sub {
    @done = map { $_->[1] } grep { $_->[0] eq 'raider.done' } @$events;
    @done && !%{ $restarted->raiders };
  } );
  is( $done[0]{response}, 'answer: next', 'the waiting mission ran after the restart' );
  is( $done[0]{session}, $hall->session_bindings->{'cron:nightly'}, 'on its binding' );
  is( $restarted->binding_queues, {}, 'and left the queue' );
};

subtest 'the queue keeps the binding of a waiting mission' => sub {
  my ( $hall, $tmp ) = fake_hall();
  $hall->raiders->{busy} = Langertha::Raider::Hall::Raider->new(
    id => '1ivar-1', pid => 2**22 + 12345, slot_name => '1ivar', base_name => 'ivar',
    mission => 'm', log_path => $tmp->child('x.log') );
  ok( $hall->spawn( name => '1ivar', mission => 'next', binding => 'cron:nightly' )->{queued}, 'queued' );
  my $queue = JSON::MaybeXS->new->decode(
    $tmp->child( '.raider-hall', 'state', '1ivar.queue.json' )->slurp_utf8 );
  is( $queue->[0]{binding}, 'cron:nightly', 'persisted with the mission' );
  delete $hall->raiders->{busy};
  $hall->_spawn_next_in_queue( '1ivar', 'ivar', shift @$queue );
  my ($done) = run_spawns( $hall, 1 );
  is( $done->{session}, $hall->session_bindings->{'cron:nightly'}, 'replayed onto its binding' );
};

subtest 'telegram binds bot + chat, plus the thread' => sub {
  my @spawns;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_emit = sub {};
  local *Langertha::Raider::Hall::spawn = sub { my ( $self, %args ) = @_; push @spawns, \%args };
  my $hall = Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ) );
  my $tg = Langertha::Raider::Hall::Telegram->new( hall => $hall );
  $tg->_workers->{ops} = { token => 'x', allowlist => [42], allowed_chats => [-100],
    routing => { '*' => 'bjorn' }, active => 0 };
  $tg->_handle_update( ops => { update_id => 1, message => {
    chat => { id => 42 }, from => { id => 42 }, text => 'hi' } } );
  $tg->_handle_update( ops => { update_id => 2, message => {
    chat => { id => -100 }, from => { id => 42 }, message_thread_id => 7, text => 'yo' } } );
  is( [ map { $_->{binding} } @spawns ], [ 'telegram:ops:42', 'telegram:ops:-100:7' ], 'binding keys' );
};

subtest 'a cron job fires onto its own binding' => sub {
  my @spawns;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_emit = sub {};
  local *Langertha::Raider::Hall::spawn = sub { my ( $self, %args ) = @_; push @spawns, \%args; {} };
  local *Langertha::Raider::Hall::Cron::_arm = sub {};
  my $hall = Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ) );
  my $cron = Langertha::Raider::Hall::Cron->new( hall => $hall );
  $cron->add_job( id => 'nightly', cron => '0 3 * * *', name => '1bjorn', mission => 'ping' );
  $cron->_fire('nightly');
  is( $spawns[0], { name => '1bjorn', mission => 'ping', binding => 'cron:nightly' }, 'spawned with cron:ID' );
};

{
  package CaptureStream;
  sub new { bless { lines => [] }, shift }
  sub write { push @{ $_[0]{lines} }, JSON::MaybeXS->new->decode( $_[1] ); 1 }
}

subtest 'an ACP session keeps one raider session across prompts' => sub {
  my ( undef, $tmp ) = fake_hall( yml => "raiders:\n  bjorn: {}\n" );
  my $hall = Langertha::Raider::Hall->new( root => $tmp );
  hall_events($hall);
  my $acp = Langertha::Raider::Hall::ACP->new( hall => $hall, port => 0, host => '127.0.0.1' );
  my $stream = CaptureStream->new;
  $acp->_sessions->{'acp-1'} = { stream => $stream, raider_name => 'bjorn' };
  for my $n ( 1, 2 ) {
    $acp->_session_prompt( $stream, $n, { sessionId => 'acp-1', prompt => [ { type => 'text', text => "p$n" } ] } );
    wait_until( $hall, sub { !%{ $hall->raiders } && grep { ( $_->{id} // 0 ) == $n } @{ $stream->{lines} } } );
  }
  my @ids = map { session_flag($_) } @{ argvs() };
  is( scalar @ids, 2, 'both prompts ran with --session' );
  is( $ids[0], $ids[1], 'the same session' );
  is( $hall->session_bindings->{'acp:acp-1'}, $ids[0], 'bound as acp:SESSION' );
  $hall->binding_queues->{'acp:acp-1'} = [ { name => 'bjorn', mission => 'p3', binding => 'acp:acp-1' } ];
  $acp->_forget_session('acp-1');
  ok( !exists $hall->session_bindings->{'acp:acp-1'}, 'the binding ends with the ACP session' );
  ok( !exists $hall->binding_queues->{'acp:acp-1'}, 'so do its waiting prompts' );
  ok( store_of($tmp)->exists( $ids[0] ), 'the journal stays' );
};

subtest 'bin/raider: a hall-made session resumes, a held one exits 4' => sub {
  my $tmp = path( tempdir( CLEANUP => 1 ) );
  my $hall = Langertha::Raider::Hall->new( root => $tmp );
  my $id = $hall->session_for('slot:1ivar');
  my @cmd = ( $^X, '-I'.$repo->child('lib'), $repo->child('bin', 'raider')->stringify,
    '--stream-json', '-e', 'openai', '-k', 'test', '-r', "$tmp", '--session', $id,
    '-o', 'url=http://127.0.0.1:1', '--', 'hi' );
  my $q = join ' ', map { "'$_'" } @cmd;
  my $events = $tmp->child('e.jsonl');
  `$q >'$events' 2>/dev/null </dev/null`;
  is( $? >> 8, 1, 'resumed; the unreachable engine fails the run' );
  my $doc = Langertha::Raider::Hall::Raider->new( id => 'r-1', slot_name => 'r', base_name => 'r',
    mission => 'hi', log_path => $tmp->child('r.log'), events_path => $events )->run_finished;
  is( $doc->{session}{id}, $id, 'run.finished names the hall-made session' );

  my $held = store_of($tmp)->open($id);
  my $err = $tmp->child('err');
  `$q >/dev/null 2>'$err' </dev/null`;
  is( $? >> 8, 4, 'held by another writer: exit 4' );
  like( $err->slurp_utf8, qr/session \Q$id\E is in use/, 'says so' );
};

done_testing;
