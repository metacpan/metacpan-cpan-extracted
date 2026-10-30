#!/usr/bin/env perl
# ABSTRACT: A client that subscribed over the control socket gets the hall's events, and spawning still answers
use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use IO::Select;
use IO::Socket::UNIX;
use JSON::MaybeXS;
use Test::Raider::Hall qw( fake_hall wait_until );

# The hall used to ask a subscriber's IO::Async::Stream for ->handle, which it
# does not have (only the shim of an ACP session does): the first event after
# a client subscribed died, so spawn answered "command failed" -- while the
# raider had been started.

my $json = JSON::MaybeXS->new;
my ( $hall, $tmp ) = fake_hall( yml => "raiders:\n  bjorn: {}\n" );
$hall->_setup_event_broadcaster;
$hall->_setup_socket;
$hall->protocol;

my $client = IO::Socket::UNIX->new( Peer => $hall->socket_path ) or die "connect: $!";
$client->autoflush(1);
print $client $json->encode({ type => 'subscribe', payload => { filter => 'raider.' } }), "\n";
wait_until( $hall, sub { @{ $hall->{_subscribers} // [] } }, 5 );
is( scalar @{ $hall->{_subscribers} }, 1, 'the client is subscribed' );

my $spawn = $json->decode( do {
  my $cmd = IO::Socket::UNIX->new( Peer => $hall->socket_path ) or die "connect: $!";
  $cmd->autoflush(1);
  print $cmd $json->encode({ type => 'command', payload => { cmd => 'spawn', name => 'bjorn', mission => 'hello' } }), "\n";
  my $reply;
  wait_until( $hall, sub {
    my $sel = IO::Select->new($cmd);
    $reply //= <$cmd> if $sel->can_read(0.05);
    defined $reply;
  }, 10 );
  $reply // '{}';
} );
ok( !$spawn->{error}, 'spawn answers without an error' ) or diag $spawn->{error};
ok( $spawn->{id}, 'and names the run' );

my $line;
wait_until( $hall, sub {
  my $sel = IO::Select->new($client);
  $line //= <$client> if $sel->can_read(0.05);
  defined $line;
}, 10 );
is( $json->decode( $line // '{}' )->{type}, 'raider.spawned', 'the subscriber got raider.spawned' );

wait_until( $hall, sub { !%{ $hall->raiders } }, 30 );
done_testing;
