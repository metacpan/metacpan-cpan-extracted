#!/usr/bin/env perl
# ABSTRACT: Error answers from the Telegram Bot API are reported and waited out, never polled at once (k147)

use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Temp qw( tempdir );
use Future;
use HTTP::Response;
use JSON::MaybeXS;

use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::Telegram;

{
  package Test::UA;
  sub new { my $class = shift; bless { gets => 0, queue => [@_] }, $class }
  sub GET { my $s = shift; $s->{gets}++; @{ $s->{queue} } ? Future->done( shift @{ $s->{queue} } ) : Future->new }
}

sub resp {
  my ( $code, $body ) = @_;
  my $r = HTTP::Response->new($code);
  $r->content( encode_json($body) );
  $r->header( 'Content-Type' => 'application/json' );
  return $r;
}

sub run {
  my (@responses) = @_;
  my @events;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_emit = sub { my ( undef, $t, $d ) = @_; push @events, [ $t, $d ] };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $hall = Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ) );
  my $tg = Langertha::Raider::Hall::Telegram->new( hall => $hall );
  my $ua = Test::UA->new(@responses);
  $tg->_workers->{ops} = {
    token => 'secret-token', allowlist => [42], allowed_chats => [], routing => {},
    ua => $ua, offset => 0, active => 1,
  };
  $tg->_poll('ops');
  $hall->loop->loop_once(0.05) for 1 .. 4;
  return ( $tg, $ua, \@events, \@warnings );
}

subtest '401 stops the bot' => sub {
  my ( $tg, $ua, $events, $warn ) = run(
    resp( 401, { ok => JSON->false, error_code => 401, description => 'Unauthorized secret-token' } ) );
  is( $ua->{gets}, 1, 'polled once' );
  ok( !$tg->_workers->{ops}{active}, 'bot deactivated' );
  my ($e) = map { $_->[1] } grep { $_->[0] eq 'telegram.poll_error' } @$events;
  is( $e->{status}, 401, 'status reported' );
  like( $e->{error}, qr/Unauthorized/, 'description reported' );
  unlike( encode_json($events), qr/secret-token/, 'no token in events' );
  unlike( join( '', @$warn ), qr/secret-token/, 'no token in warnings' );
};

subtest '409 waits before polling again' => sub {
  my ( $tg, $ua, $events ) = run(
    resp( 409, { ok => JSON->false, error_code => 409, description => 'Conflict' } ),
    resp( 200, { ok => JSON->true, result => [] } ) );
  is( $ua->{gets}, 1, 'no immediate re-poll' );
  ok( $tg->_workers->{ops}{active}, 'still active' );
  is( [ map { $_->[1]{status} } grep { $_->[0] eq 'telegram.poll_error' } @$events ], [409], 'reported' );
};

subtest '429 honors retry_after' => sub {
  my ( $tg, $ua, $events ) = run(
    resp( 429, { ok => JSON->false, error_code => 429, description => 'Too Many Requests',
                 parameters => { retry_after => 3 } } ) );
  is( $ua->{gets}, 1, 'no immediate re-poll' );
  is( $tg->_workers->{ops}{failures} // 0, 0, 'retry_after, not backoff' );
  is( scalar( grep { $_->[0] eq 'telegram.poll_error' } @$events ), 1, 'reported' );
};

subtest 'a failing update does not stall the offset' => sub {
  no warnings 'redefine';
  local *Langertha::Raider::Hall::Telegram::_handle_update = sub { die "disk full\n" };
  my ( $tg, $ua, $events ) = run(
    resp( 200, { ok => JSON->true, result => [ { update_id => 7 } ] } ) );
  is( $tg->_workers->{ops}{offset}, 8, 'offset advanced' );
  ok( $ua->{gets} >= 1, 'polling continued' );
  my ($e) = map { $_->[1] } grep { $_->[0] eq 'telegram.update_error' } @$events;
  like( $e->{error}, qr/disk full/, 'error visible as event' );
  is( $e->{update_id}, 7, 'for the update' );
};

done_testing;
