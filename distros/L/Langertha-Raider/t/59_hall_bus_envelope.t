#!/usr/bin/env perl
# ABSTRACT: The hall bus envelope (version, seq, time, ts), canonical JSON on the bus and the control socket, and events that had no test (ADR 0033, k171)

use strict;
use warnings;
use Test2::V0;
use Future;
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::Hall qw( fake_hall hall_events run_spawns wait_until );
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::ACP;
use Langertha::Raider::Hall::ACP::SubStream;
use Langertha::Raider::Hall::Telegram;

clear_engine_env();

my $canonical = JSON::MaybeXS->new( canonical => 1 );

{
  package RawStream;
  sub new { bless { lines => [] }, shift }
  sub write { my ( $s, $l ) = @_; chomp $l; push @{ $s->{lines} }, $l; 1 }
}

# Every line as the hall wrote it, from a subscriber of the whole bus.
sub subscribe_raw {
  my ( $hall ) = @_;
  my @raw;
  push @{ $hall->{_subscribers} //= [] }, { filter => '',
    stream => Langertha::Raider::Hall::ACP::SubStream->new( cb => sub { push @raw, $_[0] } ) };
  return \@raw;
}

sub is_canonical {
  my ( $line, $name ) = @_;
  is( $line, $canonical->encode( $canonical->decode($line) ), $name );
}

subtest 'every event carries the version 1 envelope, with seq counting per hall' => sub {
  my ( $hall ) = fake_hall( yml => "raiders:\n  bjorn: {}\n" );
  my $raw = subscribe_raw($hall);
  $hall->_emit( 'session.bound', { binding => 'x', session => 'y' } );
  run_spawns( $hall, 1, { name => 'bjorn', mission => 'hello' } );
  my @events = map { $canonical->decode($_) } @$raw;
  ok( @events >= 3, 'events arrived' );
  is( [ map { $_->{type} } @events[ 0 .. 2 ] ], [qw( session.bound raider.spawned raider.done )], 'in order' );
  is( [ map { $_->{seq} } @events ], [ 1 .. scalar @events ], 'seq is 1, 2, 3 ...' );
  for my $e (@events) {
    is( $e->{version}, 1, $e->{type}.': version 1' );
    like( $e->{time}, qr/^\d+(?:\.\d+)?(?:e[-+]?\d+)?$/i, $e->{type}.': time in epoch seconds' );
    is( $e->{ts}, int $e->{time}, $e->{type}.': ts stays, the whole seconds of time' );
  }
  ok( ( grep { $_->{time} != int $_->{time} } @events ), 'time is a float, not whole seconds' );
  is_canonical( $_, 'bus line in canonical JSON' ) for @$raw;

  my ( $other ) = fake_hall( yml => "raiders:\n  bjorn: {}\n" );
  my $other_raw = subscribe_raw($other);
  $other->_emit( 'session.bound', { binding => 'x', session => 'y' } );
  is( $canonical->decode( $other_raw->[0] )->{seq}, 1, 'a new hall counts from 1' );
};

subtest 'control-socket answers are canonical JSON' => sub {
  my ( $hall ) = fake_hall( yml => "raiders:\n  ivar: { provider: intranet }\n  bjorn: {}\n" );
  $hall->protocol;
  my $stream = RawStream->new;
  $hall->_handle_command( $stream, { cmd => 'status' } );
  $hall->_handle_command( $stream, { cmd => 'spawn', name => 'ivar', mission => 'go' } );
  $hall->_handle_command( $stream, { cmd => 'nope' } );
  my $spawn = $hall->spawn( name => 'bjorn', mission => 'hold' );
  $hall->_handle_command( $stream, { cmd => 'ps' } );
  $hall->_handle_command( $stream, { cmd => 'attach', id => $spawn->{id} } );
  path( $ENV{FAKE_RELEASE} )->touch;
  wait_until( $hall, sub { !%{ $hall->raiders } } );
  is( scalar @{ $stream->{lines} }, 5, 'five answers' );
  is_canonical( $_, 'answer in canonical JSON' ) for @{ $stream->{lines} };
  my $refused = $canonical->decode( $stream->{lines}[1] );
  is( $refused->{status}, 'refused', 'spawn answers status refused' );
  is( $refused->{reason}, 'provider_not_stored', 'with the reason' );
  like( $refused->{error}, qr/^raider ivar: provider alias 'intranet' is not stored/, 'and the error' );
  is( $canonical->decode( $stream->{lines}[2] ), { error => 'unknown command: nope' }, 'errors too' );
};

subtest 'acp.started names host and port' => sub {
  my ( $hall ) = fake_hall();
  my $acp = Langertha::Raider::Hall::ACP->new( hall => $hall, port => 0, host => '127.0.0.1' );
  my $port = $acp->start;
  $acp->stop;
  my ($e) = map { $_->[1] } grep { $_->[0] eq 'acp.started' } @{ hall_events($hall) };
  is( $e->{host}, '127.0.0.1', 'host' );
  is( $e->{port}, $port, 'the port it listened on' );
  ok( $port > 0, 'a real port for port 0' );
};

subtest 'telegram.send_error when a reply cannot be sent' => sub {
  my ( $hall ) = fake_hall();
  {
    package FailUA;
    sub new { bless {}, shift }
    sub do_request { Future->fail("connection refused\n") }
  }
  my $tg = Langertha::Raider::Hall::Telegram->new( hall => $hall );
  $tg->_workers->{ops} = { token => 't', allowlist => [42], allowed_chats => [], routing => {},
    ua => FailUA->new, offset => 0, active => 1 };
  no warnings 'redefine';
  local *Langertha::Raider::Hall::Telegram::_connect_error = sub { return };
  my $res = $tg->send_message( bot => 'ops', chat_id => 42, text => 'hi' );
  ok( $res->{ok}, 'the send was started' );
  my ($e) = map { $_->[1] } grep { $_->[0] eq 'telegram.send_error' } @{ hall_events($hall) };
  ok( $e, 'telegram.send_error emitted' );
  is( $e->{bot}, 'ops', 'bot' );
  is( $e->{chat_id}, 42, 'chat_id' );
  like( $e->{error}, qr/connection refused/, 'error' );
};

# Last: shutdown arms a timer that stops the shared loop.
subtest 'hall.stopping on shutdown' => sub {
  my ( $hall ) = fake_hall();
  my $raw = subscribe_raw($hall);
  $hall->shutdown;
  my ($e) = map { $canonical->decode($_) } @$raw;
  is( $e->{type}, 'hall.stopping', 'hall.stopping' );
  is( $e->{version}, 1, 'in the envelope' );
};

done_testing;
