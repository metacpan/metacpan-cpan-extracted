#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use IO::Async::Test;

use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::SSL;
use IO::Async::Stream;
use IO::Async::Protocol::Stream;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

my ( $server_sock, $client_sock ) = IO::Async::OS->socketpair or
   die "Cannot socketpair - $!";

$server_sock->blocking( 0 );
$client_sock->blocking( 0 );

my @server_lines;
my $server_proto = IO::Async::Protocol::Stream->new(
   transport => IO::Async::Stream->new( handle => $server_sock ),
   on_read => sub {
      my ( $self, $buffref, $closed ) = @_;
      push @server_lines, $1 while $$buffref =~ s/^(.*)\n//;
      return 0;
   },
);
$loop->add( $server_proto );

my @client_lines;
my $client_proto = IO::Async::Protocol::Stream->new(
   transport => IO::Async::Stream->new( handle => $client_sock ),
   on_read => sub {
      my ( $self, $buffref, $closed ) = @_;
      push @client_lines, $1 while $$buffref =~ s/^(.*)\n//;
      return 0;
   },
);
$loop->add( $client_proto );

my ( $server_upgraded, $client_upgraded );

$server_proto->SSL_upgrade(
   SSL_server => 1,
   SSL_key_file  => "t/privkey.pem",
   SSL_cert_file => "t/server.pem",

   on_upgraded => sub { $server_upgraded++ },
   on_error => sub { die "Test failed early - $_[-1]" },
);

$client_proto->SSL_upgrade(
   SSL_verify_mode => 0,
   on_upgraded => sub { $client_upgraded++ },
   on_error => sub { die "Test failed early - $_[-1]" },
);

wait_for { $server_upgraded and $client_upgraded };

ok( 1, "Sockets upgraded" );

# Gutwrenching but no other easy way to do this
is( $server_proto->transport->{reader}, \&IO::Async::SSL::sslread,  '$server_proto->transport has SSL reader' );
is( $server_proto->transport->{writer}, \&IO::Async::SSL::sslwrite, '$server_proto->transport has SSL writer' );
is( $client_proto->transport->{reader}, \&IO::Async::SSL::sslread,  '$client_proto->transport has SSL reader' );
is( $client_proto->transport->{writer}, \&IO::Async::SSL::sslwrite, '$client_proto->transport has SSL writer' );

$server_proto->write( "Send a line\n" );

wait_for { @client_lines };

is( $client_lines[0], "Send a line", 'Line received by client' );

$client_proto->write( "Reply a line\n" );

wait_for { @server_lines };

is( $server_lines[0], "Reply a line", 'Line received by server' );

done_testing;
