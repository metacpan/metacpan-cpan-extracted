#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use IO::Async::OS;

use Socket qw(
   AF_INET AF_INET6 AF_UNIX SOCK_STREAM SOCK_DGRAM SO_TYPE
   pack_sockaddr_in pack_sockaddr_in6 pack_sockaddr_un inet_aton inet_pton
   INADDR_ANY
);

use POSIX qw( SIGTERM );

SKIP: {
   skip "No IO::Socket::IP", 2 unless eval { require IO::Socket::IP };

   my $S_inet = IO::Async::OS->socket( "inet", "stream" );
   isa_ok( $S_inet, "IO::Socket::IP", 'IO::Async::OS->socket("inet")' );

   SKIP: {
      skip "No AF_INET6", 1 unless eval { socket( my $fh, AF_INET6, SOCK_STREAM, 0 ) };

      my $S_inet6 = IO::Async::OS->socket( "inet6", "stream" );
      isa_ok( $S_inet6, "IO::Socket::IP", 'IO::Async::OS->socket("inet6")' );
   }
}

foreach my $family ( undef, "inet" ) {
   my ( $S1, $S2 ) = IO::Async::OS->socketpair( $family, "stream" )
      or die "Could not socketpair - $!";

   isa_ok( $S1, "IO::Socket", '$S1 isa IO::Socket' );
   isa_ok( $S2, "IO::Socket", '$S2 isa IO::Socket' );

   # Due to a bug in IO::Socket, ->socktype may not be set

   is( $S1->sockopt(SO_TYPE), SOCK_STREAM, 'SO_TYPE of $S1 is SOCK_STREAM' );
   is( $S2->sockopt(SO_TYPE), SOCK_STREAM, 'SO_TYPE of $S2 is SOCK_STREAM' );

   $S1->syswrite( "Hello" );
   is( do { my $b; $S2->sysread( $b, 8192 ); $b }, "Hello", '$S1 --writes-> $S2' );

   $S2->syswrite( "Goodbye" );
   is( do { my $b; $S1->sysread( $b, 8192 ); $b }, "Goodbye", '$S2 --writes-> $S1' );

   ( $S1, $S2 ) = IO::Async::OS->socketpair( $family, "dgram" )
      or die "Could not socketpair - $!";

   isa_ok( $S1, "IO::Socket", '$S1 isa IO::Socket' );
   isa_ok( $S2, "IO::Socket", '$S2 isa IO::Socket' );

   is( $S1->socktype, SOCK_DGRAM, '$S1->socktype is SOCK_DGRAM' );
   is( $S2->socktype, SOCK_DGRAM, '$S2->socktype is SOCK_DGRAM' );

   $S1->syswrite( "Hello" );
   is( do { my $b; $S2->sysread( $b, 8192 ); $b }, "Hello", '$S1 --writes-> $S2' );

   $S2->syswrite( "Goodbye" );
   is( do { my $b; $S1->sysread( $b, 8192 ); $b }, "Goodbye", '$S2 --writes-> $S1' );
}

{
   my ( $Prd, $Pwr ) = IO::Async::OS->pipepair or die "Could not pipepair - $!";

   $Pwr->syswrite( "Hello" );
   is( do { my $b; $Prd->sysread( $b, 8192 ); $b }, "Hello", '$Pwr --writes-> $Prd' );

   # Writing to $Prd _may_ fail, but some systems might implement this as a
   # socketpair instead. We won't test it just in case
}

{
   my ( $rdA, $wrA, $rdB, $wrB ) = IO::Async::OS->pipequad or die "Could not pipequad - $!";

   $wrA->syswrite( "Hello" );
   is( do { my $b; $rdA->sysread( $b, 8192 ); $b }, "Hello", '$wrA --writes-> $rdA' );

   $wrB->syswrite( "Goodbye" );
   is( do { my $b; $rdB->sysread( $b, 8192 ); $b }, "Goodbye", '$wrB --writes-> $rdB' );
}

is( IO::Async::OS->signame2num( 'TERM' ), SIGTERM, 'signame2num' );

is( IO::Async::OS->getfamilybyname( "inet" ),  AF_INET, 'getfamilybyname "inet"' );
is( IO::Async::OS->getfamilybyname( AF_INET ), AF_INET, 'getfamilybyname AF_INET' );

is( IO::Async::OS->getsocktypebyname( "stream" ),    SOCK_STREAM, 'getsocktypebyname "stream"' );
is( IO::Async::OS->getsocktypebyname( SOCK_STREAM ), SOCK_STREAM, 'getsocktypebyname SOCK_STREAM' );

{
   my $sinaddr = pack_sockaddr_in( 56, inet_aton( "1.2.3.4" ) );

   is_deeply( [ IO::Async::OS->extract_addrinfo( [ "inet", "stream", 0, $sinaddr ] ) ],
              [ AF_INET, SOCK_STREAM, 0, $sinaddr ],
              'extract_addrinfo( ARRAY )' );

   is_deeply( [ IO::Async::OS->extract_addrinfo( {
                  family   => "inet",
                  socktype => "stream",
                  addr     => $sinaddr 
                } ) ],
              [ AF_INET, SOCK_STREAM, 0, $sinaddr ],
              'extract_addrinfo( HASH )' );

   is_deeply( [ IO::Async::OS->extract_addrinfo( {
                  family   => "inet",
                  socktype => "stream",
                  ip       => "1.2.3.4",
                  port     => "56",
                } ) ],
              [ AF_INET, SOCK_STREAM, 0, $sinaddr ],
              'extract_addrinfo( HASH ) with inet, ip+port' );

   is_deeply( [ IO::Async::OS->extract_addrinfo( {
                  family   => "inet",
                  socktype => "stream",
                  port     => "56",
                } ) ],
              [ AF_INET, SOCK_STREAM, 0, pack_sockaddr_in( 56, INADDR_ANY ) ],
              'extract_addrinfo( HASH ) with inet, port' );

   is_deeply( [ IO::Async::OS->extract_addrinfo( {
                  family   => "inet",
                  socktype => "stream",
                } ) ],
              [ AF_INET, SOCK_STREAM, 0, pack_sockaddr_in( 0, INADDR_ANY ) ],
              'extract_addrinfo( HASH ) with inet only' );

   ok( exception { IO::Async::OS->extract_addrinfo( {
                     family  => "inet",
                     host    => "foobar.com",
                   } ) }, 'extract_addrinfo for inet complains about unrecognised key' );
}

SKIP: {
   my $sin6addr = eval { Socket::pack_sockaddr_in6( 1234, inet_pton( AF_INET6, "fe80::5678" ) ) };
   skip "No pack_sockaddr_in6", 1 unless defined $sin6addr;

   is_deeply( [ IO::Async::OS->extract_addrinfo( {
                  family   => "inet6",
                  socktype => "stream",
                  ip       => "fe80::5678",
                  port     => "1234",
                } ) ],
              [ AF_INET6, SOCK_STREAM, 0, $sin6addr ],
              'extract_addrinfo( HASH ) with inet6, ip+port' );
}

SKIP: {
   skip "No pack_sockaddr_un", 1 unless IO::Async::OS->HAVE_SOCKADDR_UN;
   my $sunaddr = pack_sockaddr_un( "foo.sock" );

   is_deeply( [ IO::Async::OS->extract_addrinfo( {
                  family   => "unix",
                  socktype => "stream",
                  path     => "foo.sock",
                } ) ],
              [ AF_UNIX, SOCK_STREAM, 0, $sunaddr ],
              'extract_addrinfo( HASH ) with unix, path' );
}

ok( exception { IO::Async::OS->extract_addrinfo( { family => "hohum" } ) },
   'extract_addrinfo on unrecognised family complains' );

done_testing;
