#!/usr/bin/env perl
# ABSTRACT: raider.refused for a mission the hall refuses, on every surface, also on a queue pull (ADR 0033, k171)

use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
my $HOME = isolate_home();
use Test::Raider::Hall qw( fake_hall hall_events wait_until );
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::ACP;
use Langertha::Raider::Hall::Telegram;

clear_engine_env();

# One stored binding: 'acme' is an alias the hall accepts.
sub store_acme {
  path($HOME)->child('.raider')->mkpath;
  path($HOME)->child( '.raider', 'config.yml' )->spew_utf8( YAML::PP->new->dump_string({
    providers => { acme => { origin => 'https://provider.example:443', fingerprint => 'x' } },
  }) );
}
store_acme();

{
  package CaptureStream;
  sub new { bless { lines => [] }, shift }
  sub write { push @{ $_[0]{lines} }, JSON::MaybeXS->new->decode( $_[1] ); 1 }
}

sub ran_missions {
  my $log = path( $ENV{FAKE_ARGV_LOG} );
  return [] unless -f $log;
  return [ map { JSON::MaybeXS->new->decode($_)->[-1] } $log->lines ];
}

sub refused_events { [ map { $_->[1] } grep { $_->[0] eq 'raider.refused' } @{ hall_events( $_[0] ) } ] }

sub slot_log {
  my ( $tmp, $slot ) = @_;
  my $f = $tmp->child( '.raider-hall', 'logs', $slot.'.log' );
  return -f $f ? $f->slurp_utf8 : '';
}

# Every reason code, from the check that refuses the entry.
for my $case (
  [ provider_not_alias   => "{ provider: provider.example }", qr/is no alias/ ],
  [ provider_with_engine => "{ provider: acme, engine: anthropic }", qr/provider and engine exclude each other/ ],
  [ provider_not_stored  => "{ provider: intranet }", qr/provider alias 'intranet' is not stored/ ],
) {
  my ( $reason, $entry, $match ) = @$case;
  subtest "raider.refused: $reason" => sub {
    my ( $hall, $tmp ) = fake_hall( yml => "raiders:\n  ivar: $entry\n" );
    my $res = $hall->spawn( name => 'ivar', mission => 'go' );
    is( $res->{status}, 'refused', 'the spawn answers status refused' );
    is( $res->{reason}, $reason, 'with the reason code' );
    like( $res->{error}, qr/^raider ivar: /, 'and keeps its error' );
    like( $res->{error}, $match, 'naming why' );
    my $events = refused_events($hall);
    is( scalar @$events, 1, 'one raider.refused' );
    my $e = $events->[0];
    is( $e->{status}, 'refused', 'status' );
    is( $e->{slot}, 'ivar', 'slot' );
    is( $e->{name}, 'ivar', 'name' );
    is( $e->{reason}, $reason, 'reason' );
    like( $e->{error}, $match, 'error is the human text' );
    unlike( $e->{error}, qr/^raider ivar:/, 'without the name in front' );
    ok( exists $e->{queued} && !$e->{queued}, 'queued is false' );
    ok( !exists $e->{binding}, 'no binding for a plain-name mission without one' );
    ok( !exists $e->{id} && !exists $e->{pid}, 'no run id, no pid: nothing ran' );
    is( ran_missions(), [], 'the raider never started' );
    like( slot_log( $tmp, 'ivar' ), qr/^\[hall\] raider ivar refused: \Q$e->{error}\E; mission not run$/m,
      'the slot log line in the form of the result line' );
  };
}

subtest 'raider.refused: provider_config (home config unreadable)' => sub {
  path($HOME)->child( '.raider', 'config.yml' )->spew_utf8("providers: 42\n");
  my ( $hall, $tmp ) = fake_hall( yml => "raiders:\n  ivar: { provider: acme }\n" );
  my $res = $hall->spawn( name => 'ivar', mission => 'go' );
  is( $res->{reason}, 'provider_config', 'the spawn answers provider_config' );
  my ($e) = @{ refused_events($hall) };
  is( $e->{reason}, 'provider_config', 'and so does the event' );
  like( $e->{error}, qr/providers/, 'naming the config problem' );
  store_acme();
};

subtest 'a numbered slot names its binding' => sub {
  my ( $hall ) = fake_hall( yml => "raiders:\n  ivar: { provider: intranet }\n" );
  $hall->spawn( name => '1ivar', mission => 'go' );
  my ($e) = @{ refused_events($hall) };
  is( $e->{slot}, '1ivar', 'slot' );
  is( $e->{name}, 'ivar', 'name' );
  is( $e->{binding}, 'slot:1ivar', 'the slot binding' );
};

# A slot whose raider entry turns bad while a mission waits: the mission is
# refused when it is pulled from the queue.
sub turn_bad { $_[0]->config->{raiders}{ivar} = { provider => 'intranet' } }

subtest 'refused on a slot queue pull: queued is true' => sub {
  my ( $hall, $tmp ) = fake_hall( yml => "raiders:\n  ivar: {}\n" );
  $hall->spawn( name => '1ivar', mission => 'hold' );
  is( $hall->spawn( name => '1ivar', mission => 'p2', binding => 'acp:q' )->{queued}, 1, 'p2 waits' );
  turn_bad($hall);
  path( $ENV{FAKE_RELEASE} )->touch;
  wait_until( $hall, sub { @{ refused_events($hall) } && !%{ $hall->raiders } } );
  my ($e) = @{ refused_events($hall) };
  ok( $e->{queued}, 'queued is true' );
  is( $e->{binding}, 'acp:q', 'the mission binding' );
  is( ran_missions(), ['hold'], 'p2 never ran' );
};

subtest 'refused on a binding queue pull: queued is true' => sub {
  my ( $hall ) = fake_hall( yml => "raiders:\n  ivar: {}\n" );
  $hall->spawn( name => 'ivar', mission => 'hold', binding => 'acp:b' );
  ok( $hall->spawn( name => 'ivar', mission => 'p2', binding => 'acp:b' )->{queued}, 'p2 waits for the binding' );
  turn_bad($hall);
  path( $ENV{FAKE_RELEASE} )->touch;
  wait_until( $hall, sub { @{ refused_events($hall) } && !%{ $hall->raiders } } );
  my ($e) = @{ refused_events($hall) };
  ok( $e->{queued}, 'queued is true' );
  is( $e->{binding}, 'acp:b', 'binding' );
  is( $hall->binding_queues, {}, 'nothing left waiting' );
};

#### ACP

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

subtest 'ACP: a refused prompt is a -32000 at once' => sub {
  my ( $hall ) = fake_hall( yml => "raiders:\n  ivar: { provider: intranet }\n" );
  my ( $acp, $stream ) = acp_for( $hall, 'ivar' );
  prompt( $acp, $stream, 1, 'go' );
  my $r = reply_to( $stream, 1 );
  is( $r->{error}{code}, -32000, 'JSON-RPC error -32000' );
  like( $r->{error}{message}, qr/^spawn failed: raider ivar: provider alias 'intranet' is not stored/, 'with the error' );
};

for my $name (qw( ivar 1ivar )) {
  subtest "ACP: a waiting prompt ($name) refused on its queue pull is a -32000, not a hang" => sub {
    my ( $hall ) = fake_hall( yml => "raiders:\n  ivar: {}\n" );
    my ( $acp, $stream ) = acp_for( $hall, $name );
    prompt( $acp, $stream, 1, 'hold' );
    prompt( $acp, $stream, 2, 'p2' );
    prompt( $acp, $stream, 3, 'p3' );
    wait_until( $hall, sub { @{ ran_missions() } } );
    is( reply_to( $stream, 2 ), undef, 'p2 waits' );
    turn_bad($hall);
    path( $ENV{FAKE_RELEASE} )->touch;
    wait_until( $hall, sub { reply_to( $stream, 3 ) && !%{ $hall->raiders } }, 15 );
    is( reply_to( $stream, 1 )->{result}, { stopReason => 'end_turn' }, 'the running prompt ended normally' );
    my $r = reply_to( $stream, 2 ) // {};
    is( $r->{error}{code}, -32000, 'the waiting one: -32000' );
    like( $r->{error}{message}, qr/^spawn failed: raider ivar: provider alias 'intranet' is not stored/,
      'with the refusal' );
    is( ( reply_to( $stream, 3 ) // {} )->{error}{code}, -32000, 'the one behind it, too' );
    is( ran_missions(), ['hold'], 'neither ran' );
    is( $acp->_sessions->{s1}{waiting}, [], 'no prompt left waiting' );
  };
}

#### Cron

subtest 'cron: a refused occurrence is raider.refused on cron:ID' => sub {
  my ( $hall ) = fake_hall( yml => "raiders:\n  ivar: { provider: intranet }\n" );
  my $cron = $hall->cron_scheduler;
  $cron->_jobs->{nightly} = { id => 'nightly', cron => '0 0 1 1 *', name => 'ivar', mission => 'go', coalesce => 0 };
  $cron->_fire('nightly');
  $cron->cancel_job('nightly');
  my ($e) = @{ refused_events($hall) };
  is( $e->{binding}, 'cron:nightly', 'binding cron:ID' );
  is( $e->{reason}, 'provider_not_stored', 'reason' );
  my ($fired) = map { $_->[1] } grep { $_->[0] eq 'cron.fired' } @{ hall_events($hall) };
  ok( $fired && !exists $fired->{raider_id}, 'cron.fired names no raider' );
};

#### Telegram

subtest 'telegram: the chat gets a short reply without details, also on a queue pull' => sub {
  my ( $hall ) = fake_hall( yml => "raiders:\n  ivar: { provider: intranet }\n" );
  my @sent;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::Telegram::send_message = sub { my ( undef, %a ) = @_; push @sent, \%a; { ok => 1 } };
  my %target = ( bot => 'ops', chat_id => 42, message_thread_id => 7 );
  $hall->spawn( name => 'ivar', mission => 'go', telegram => \%target, binding => 'telegram:ops:42:7' );
  is( scalar @sent, 1, 'one reply' );
  is( { %{ $sent[0] }, text => undef }, { %target, text => undef }, 'into the chat and topic of the mission' );
  is( $sent[0]{text}, 'mission not started (configuration), see the hall log', 'the short text' );
  unlike( $sent[0]{text}, qr/intranet|config\.yml|provider/, 'no alias, no path' );
  is( refused_events($hall)->[0]{binding}, 'telegram:ops:42:7', 'the event names the chat binding' );

  @sent = ();
  $hall->config->{raiders}{ivar} = {};
  $hall->spawn( name => '1ivar', mission => 'hold', telegram => \%target, binding => 'telegram:ops:42:7' );
  ok( $hall->spawn( name => '1ivar', mission => 'p2', telegram => \%target, binding => 'telegram:ops:42:7' )->{queued},
    'p2 waits' );
  turn_bad($hall);
  path( $ENV{FAKE_RELEASE} )->touch;
  wait_until( $hall, sub { @sent && !%{ $hall->raiders } } );
  is( scalar @sent, 1, 'the refused queue pull gets the reply too' );
  is( $sent[0]{chat_id}, 42, 'in the same chat' );
};

subtest 'telegram: a mission that runs gets no refusal reply' => sub {
  my ( $hall ) = fake_hall( yml => "raiders:\n  ivar: {}\n" );
  my @sent;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::Telegram::send_message = sub { push @sent, 1; { ok => 1 } };
  $hall->spawn( name => 'ivar', mission => 'x', telegram => { bot => 'ops', chat_id => 42 }, binding => 'telegram:ops:42' );
  wait_until( $hall, sub { !%{ $hall->raiders } } );
  is( \@sent, [], 'nothing sent by the hall' );
  is( refused_events($hall), [], 'no raider.refused' );
};

done_testing;
