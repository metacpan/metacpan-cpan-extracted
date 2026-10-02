#!/usr/bin/env perl
# ABSTRACT: hall queues across a start, the spawn reply, ACP prompts that wait, stale cron bindings

use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::Hall qw( fake_hall hall_events run_spawns wait_until );
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::ACP;
use Langertha::Raider::Hall::CLI;
use Langertha::Raider::Hall::Raider;
use Langertha::Raider::SessionStore;

clear_engine_env();

my $json = JSON::MaybeXS->new( canonical => 1 );

{
  package CaptureStream;
  sub new { bless { lines => [] }, shift }
  sub write { push @{ $_[0]{lines} }, JSON::MaybeXS->new->decode( $_[1] ); 1 }
}

sub state_file { path( $_[0], '.raider-hall', 'state', $_[1] ) }

sub write_state {
  my ( $tmp, $file, $data ) = @_;
  my $f = state_file( $tmp, $file );
  $f->parent->mkpath;
  $f->spew_utf8( $json->encode($data) );
}

sub messages_of {
  my ( $tmp, $id ) = @_;
  return [ map { $_->{content} } grep { $_->{type} eq 'message' }
    @{ Langertha::Raider::SessionStore->new( root => "$tmp" )->read($id)->events } ];
}

sub busy_slot {
  my ( $hall, $tmp, $slot ) = @_;
  $hall->raiders->{busy} = Langertha::Raider::Hall::Raider->new(
    id => $slot.'-1', pid => 2**22 + 12345, slot_name => $slot, base_name => $slot =~ s/^\d+//r,
    mission => 'm', log_path => $tmp->child('x.log') );
}

sub ran_missions {
  my $log = path( $ENV{FAKE_ARGV_LOG} );
  return [] unless -f $log;
  return [ map { JSON::MaybeXS->new->decode($_)->[-1] } $log->lines ];
}

subtest 'spawn on a busy numbered slot answers with the queue depth' => sub {
  my ( $hall, $tmp ) = fake_hall();
  busy_slot( $hall, $tmp, '1ivar' );
  is( $hall->spawn( name => '1ivar', mission => 'a' ), { queued => 1, slot => '1ivar', queue_depth => 1 },
    'first waiting mission' );
  is( $hall->spawn( name => '1ivar', mission => 'b' ), { queued => 1, slot => '1ivar', queue_depth => 2 },
    'second' );

  my $out = '';
  {
    my $cwd = path('.')->absolute;
    $tmp->child('.raider-hall.socket')->touch;
    chdir $tmp or die $!;
    no warnings 'redefine';
    local *Langertha::Raider::Hall::CLI::_send_command = sub {
      my $stream = CaptureStream->new;
      $hall->protocol;
      $hall->_handle_command( $stream, $_[1]{payload} );
      return $stream->{lines}[0];
    };
    local *STDOUT;
    open STDOUT, '>', \$out or die $!;
    Langertha::Raider::Hall::CLI->main( 'spawn', '1ivar', 'c' );
    chdir $cwd or die $!;
  }
  is( $out, "Mission queued for slot 1ivar (queue depth: 3).\n", 'raider hall spawn prints it' );
};

subtest 'a hall start runs the singleton queue it loaded, in order' => sub {
  my ( undef, $tmp ) = fake_hall();
  write_state( $tmp, '1ivar.queue.json', [ { mission => 'old1' }, { mission => 'old2' } ] );
  my $hall = Langertha::Raider::Hall->new( root => $tmp );
  my $events = hall_events($hall);
  $hall->_drain_singleton_queues;
  is( scalar keys %{ $hall->raiders }, 1, 'the first waiting mission started' );
  is( $hall->spawn( name => '1ivar', mission => 'new' ), { queued => 1, slot => '1ivar', queue_depth => 2 },
    'a new mission waits behind the loaded one' );
  my @done = run_spawns( $hall, 3 );
  is( [ map { $_->{response} } @done ], [ 'answer: old1', 'answer: old2', 'answer: new' ], 'in order' );
  is( messages_of( $tmp, $hall->session_bindings->{'slot:1ivar'} ), [qw( old1 old2 new )],
    'in the slot session' );
  is( $json->decode( state_file( $tmp, '1ivar.queue.json' )->slurp_utf8 ), [], 'queue file drained' );
};

subtest 'a new mission never overtakes a loaded singleton queue' => sub {
  my ( undef, $tmp ) = fake_hall();
  write_state( $tmp, '1ivar.queue.json', [ { mission => 'old' } ] );
  my $hall = Langertha::Raider::Hall->new( root => $tmp );
  is( $hall->spawn( name => '1ivar', mission => 'new' ), { queued => 1, slot => '1ivar', queue_depth => 1 },
    'queued behind the waiting mission, which started' );
  my @done = run_spawns( $hall, 2 );
  is( [ map { $_->{response} } @done ], [ 'answer: old', 'answer: new' ], 'waiting mission first' );
};

subtest 'a new mission never overtakes a loaded binding queue' => sub {
  my ( undef, $tmp ) = fake_hall();
  write_state( $tmp, 'binding_queues.json', { 'cron:nightly' => [
    { name => 'bjorn', mission => 'old1', binding => 'cron:nightly' },
    { name => 'bjorn', mission => 'old2', binding => 'cron:nightly' } ] } );
  my $hall = Langertha::Raider::Hall->new( root => $tmp );
  is( $hall->spawn( name => 'bjorn', mission => 'new', binding => 'cron:nightly' ),
    { queued => 1, slot => 'bjorn', binding => 'cron:nightly', queue_depth => 2 },
    'queued behind the waiting missions, the first of which started' );
  my @done = run_spawns( $hall, 3 );
  is( [ map { $_->{response} } @done ], [ 'answer: old1', 'answer: old2', 'answer: new' ], 'in order' );
  is( messages_of( $tmp, $hall->session_bindings->{'cron:nightly'} ), [qw( old1 old2 new )],
    'in the binding session' );
  is( $hall->binding_queues, {}, 'queue drained' );
};

subtest 'a waiting binding queue follows its missions into a busy slot, in order' => sub {
  my ( undef, $tmp ) = fake_hall();
  write_state( $tmp, 'binding_queues.json', { 'cron:nightly' => [
    { name => '1ivar', mission => 'old1', binding => 'cron:nightly' },
    { name => '1ivar', mission => 'old2', binding => 'cron:nightly' } ] } );
  my $hall = Langertha::Raider::Hall->new( root => $tmp );
  busy_slot( $hall, $tmp, '1ivar' );
  is( $hall->spawn( name => '1ivar', mission => 'new', binding => 'cron:nightly' ),
    { queued => 1, slot => '1ivar', queue_depth => 3 }, 'behind both in the slot queue' );
  is( [ map { $_->{mission} } @{ $hall->singleton_queues->{'1ivar'} } ], [qw( old1 old2 new )],
    'slot queue in order' );
  is( $hall->binding_queues, {}, 'nothing left on the binding' );
};

subtest 'run: drains loaded queues, forgets bindings of removed cron jobs' => sub {
  my ( undef, $tmp ) = fake_hall( yml => "cron:\n  - { id: nightly, name: 1ivar, cron: '0 3 * * *', mission: ping }\n" );
  my $store = Langertha::Raider::SessionStore->new( root => "$tmp" );
  my %id = map { my $s = $store->create; $s->release; ( $_ => $s->id ) } qw( gone nightly tg );
  write_state( $tmp, 'sessions.json', {
    'cron:gone' => $id{gone}, 'cron:nightly' => $id{nightly}, 'telegram:ops:42' => $id{tg} } );
  write_state( $tmp, 'binding_queues.json', {
    'cron:gone' => [ { name => 'bjorn', mission => 'gone-waiting', binding => 'cron:gone' } ] } );
  write_state( $tmp, '1ivar.queue.json', [
    { mission => 'stale', binding => 'cron:gone' }, { mission => 'old' } ] );

  my $hall = Langertha::Raider::Hall->new( root => $tmp );
  my $events = hall_events($hall);
  {
    no warnings 'redefine';
    no strict 'refs';
    local *Langertha::Raider::Hall::_setup_socket = sub {};
    local *Langertha::Raider::Hall::_setup_signal_handlers = sub {};
    local *Langertha::Raider::Hall::_setup_cron = sub {};
    local *{ ref( $hall->loop ).'::run' } = sub {};
    $hall->run;
  }
  my $kept = { 'cron:nightly' => $id{nightly}, 'telegram:ops:42' => $id{tg}, 'slot:1ivar' => T() };
  is( $hall->session_bindings, $kept, 'the removed job lost its binding, the others stay' );
  is( $json->decode( state_file( $tmp, 'sessions.json' )->slurp_utf8 ), $kept, 'in sessions.json too' );
  ok( $store->exists( $id{gone} ), 'its journal stays' );
  is( $hall->binding_queues, {}, 'its waiting mission is dropped' );
  my @done = run_spawns( $hall, 1 );
  is( [ map { $_->{response} } @done ], [ 'answer: old' ], 'the loaded slot queue ran, without the stale mission' );
  is( ran_missions(), [ 'old' ], 'nothing else ran' );
};

sub acp_for {
  my ( $hall, $name ) = @_;
  my $acp = Langertha::Raider::Hall::ACP->new( hall => $hall, port => 0, host => '127.0.0.1' );
  my $stream = CaptureStream->new;
  $acp->_sessions->{s1} = { stream => $stream, raider_name => $name };
  return ( $acp, $stream );
}

sub prompt {
  my ( $acp, $stream, $id, $text ) = @_;
  $acp->_session_prompt( $stream, $id, { sessionId => 's1', prompt => [ { type => 'text', text => $text } ] } );
}

sub reply_to { my ( $stream, $id ) = @_; ( grep { defined $_->{id} && $_->{id} == $id } @{ $stream->{lines} } )[0] }

for my $name (qw( bjorn 1ivar )) {
  subtest "ACP: a waiting prompt ($name) is answered when its run ends" => sub {
    my ( $hall, $tmp ) = fake_hall();
    my ( $acp, $stream ) = acp_for( $hall, $name );
    prompt( $acp, $stream, 1, 'hold' );
    prompt( $acp, $stream, 2, 'p2' );
    wait_until( $hall, sub { 0 }, 0.5 );
    is( reply_to( $stream, 2 ), undef, 'no answer while the prompt waits' );

    path( $ENV{FAKE_RELEASE} )->touch;
    wait_until( $hall, sub { reply_to( $stream, 2 ) && !%{ $hall->raiders } } );
    is( reply_to( $stream, 1 )->{result}, { stopReason => 'end_turn' }, 'the first prompt ended' );
    is( reply_to( $stream, 2 )->{result}, { stopReason => 'end_turn' }, 'the waiting one too, as end_turn' );
    my @lines = @{ $stream->{lines} };
    my ($first) = grep { defined $lines[$_]{id} && $lines[$_]{id} == 1 } 0 .. $#lines;
    my @chunks = map { $_->{params}{update}{content}{text} }
      grep { ( $_->{method} // '' ) eq 'session/update' } @lines[ $first .. $#lines ];
    is( $chunks[-1], 'answer: p2', 'its result reached the client, after the first answer' );
    is( messages_of( $tmp, $hall->session_bindings->{'acp:s1'} ), [qw( hold p2 )], 'in the ACP session' );
  };
}

subtest 'ACP: a waiting prompt whose run starts without its session is answered' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my $events = hall_events($hall);
  my ( $acp, $stream ) = acp_for( $hall, '1ivar' );
  prompt( $acp, $stream, 1, 'hold' );
  prompt( $acp, $stream, 2, 'p2' );
  wait_until( $hall, sub { @{ ran_missions() } } );
  {
    no warnings 'redefine';
    local *Langertha::Raider::Hall::session_for = sub { die "no journal today\n" };
    path( $ENV{FAKE_RELEASE} )->touch;
    wait_until( $hall, sub { grep { $_->[0] eq 'hall.session_error' } @$events } );
  }
  wait_until( $hall, sub { reply_to( $stream, 2 ) && !%{ $hall->raiders } } );
  my ($error) = grep { $_->[0] eq 'hall.session_error' } @$events;
  is( $error->[1]{binding}, 'acp:s1', 'the run lost its binding' );
  ok( $error->[1]{id}, 'hall.session_error names the run' );
  is( ( reply_to( $stream, 2 ) // {} )->{result}, { stopReason => 'end_turn' }, 'the waiting prompt got its answer' );
  my @chunks = map { $_->{params}{update}{content}{text} }
    grep { ( $_->{method} // '' ) eq 'session/update' } @{ $stream->{lines} };
  is( $chunks[-1], 'answer: p2', 'with the output of its run' );
  is( ran_missions(), [qw( hold p2 )], 'both ran' );
};

subtest 'ACP: cancel answers a waiting prompt and drops it' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my ( $acp, $stream ) = acp_for( $hall, '1ivar' );
  prompt( $acp, $stream, 1, 'hold' );
  prompt( $acp, $stream, 2, 'p2' );
  wait_until( $hall, sub { @{ ran_missions() } } );
  $acp->_session_cancel( $stream, 3, { sessionId => 's1' } );
  is( reply_to( $stream, 2 )->{result}, { stopReason => 'cancelled' }, 'the waiting prompt: cancelled' );
  is( [ grep { ( $_->{binding} // '' ) eq 'acp:s1' } @{ $hall->singleton_queues->{'1ivar'} // [] } ], [],
    'gone from the slot queue' );
  is( $hall->binding_queues, {}, 'no binding queue left' );
  wait_until( $hall, sub { reply_to( $stream, 1 ) && !%{ $hall->raiders } } );
  is( reply_to( $stream, 1 )->{result}, { stopReason => 'cancelled' }, 'the running one: cancelled' );
  is( ran_missions(), ['hold'], 'the waiting prompt never ran' );
};

subtest 'a filtered subscriber stays through events it does not want' => sub {
  my ( $hall ) = fake_hall();
  my @got;
  push @{ $hall->{_subscribers} }, { filter => 'raider.',
    stream => Langertha::Raider::Hall::ACP::SubStream->new( cb => sub { push @got, $json->decode( $_[0] )->{type} } ) };
  $hall->_emit( 'session.bound', { binding => 'x', session => 'y' } );
  $hall->_emit( 'raider.queued', { slot => '1ivar' } );
  is( \@got, ['raider.queued'], 'still subscribed after a hall event' );
};

my ( $left_hall, $left_pid );
subtest 'a subtest leaves a raider running' => sub {
  my ( $hall ) = fake_hall();
  my $spawn = $hall->spawn( name => 'bjorn', mission => 'hold' );
  ( $left_hall, $left_pid ) = ( $hall, $spawn->{pid} );
  ok( kill( 0, $left_pid ), 'still running at the end of the subtest' );
};

subtest 'the next hall starts on a quiet loop' => sub {
  my ( $hall ) = fake_hall();
  is( $left_hall->raiders, {}, 'the raider left behind was reaped' );
  ok( !kill( 0, $left_pid ), 'and its process is gone' );
  my @done = run_spawns( $hall, 1, { name => 'bjorn', mission => 'x' } );
  is( [ map { $_->{response} } @done ], [ 'answer: x' ], 'only its own raider.done counts' );
};

done_testing;
