#!/usr/bin/env perl
# ABSTRACT: When the https connection to the Telegram Bot API cannot load its modules, the hall's bots fail loud instead of hanging (k109)

use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Temp qw( tempdir );

# Net::Async::HTTP loads IO::Async::SSL only when it opens an https
# connection. When that load dies, the connection slot for the host stays
# taken and every later request to it waits forever (k107): Hall::Telegram
# runs one connection per bot, so the bot would go silent.
my %blocked;
unshift @INC, sub {
  my ( undef, $file ) = @_;
  die "Can't locate $file in \@INC (blocked by the test)\n" if $blocked{$file};
  return;
};

use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::Telegram;

plan skip_all => 'IO/Async/SSL.pm is already loaded, it cannot be made to fail'
  if $INC{'IO/Async/SSL.pm'};

subtest 'IO::Async::SSL cannot load' => sub {
  local $blocked{'IO/Async/SSL.pm'} = 1;
  my @events;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_emit = sub { my ( undef, $type, $data ) = @_; push @events, [ $type, $data ] };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $hall = Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ) );
  my $tg = Langertha::Raider::Hall::Telegram->new( hall => $hall );
  $tg->_start_bot( ops => { token => 'secret-token', allowlist => [42] } );

  my $worker = $tg->_workers->{ops};
  ok( !$worker->{poll_future}, 'no poll request was sent' );
  ok( !$worker->{active}, 'the bot stopped polling' );

  my ($error) = map { $_->[1] } grep { $_->[0] eq 'telegram.poll_error' } @events;
  ok( $error, 'telegram.poll_error emitted' ) or return;
  is( $error->{bot}, 'ops', 'for the bot' );
  like( $error->{error}, qr/IO::Async::SSL/, 'naming the module' );
  like( $error->{error}, qr{https://api\.telegram\.org}, 'and the target' );
  unlike( $error->{error}, qr/secret-token/, 'without the token' );
  like( join( '', @warnings ), qr/Telegram bot ops: .*IO::Async::SSL/, 'and warned' );

  my $res = $tg->send_message( bot => 'ops', chat_id => 42, text => 'hi' );
  like( $res->{error}, qr/IO::Async::SSL/, 'a reply is an error naming the module' );
  ok( !$res->{future}, 'and sends nothing' );
  ok( !%{ $worker->{send_futures} // {} }, 'nothing in flight' );
};

done_testing;
