#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use IO::Async::OS;

use Socket qw(
   SOCK_STREAM SOCK_DGRAM SO_TYPE
   AF_INET  pack_sockaddr_in  unpack_sockaddr_in
   AF_INET6 pack_sockaddr_in6 unpack_sockaddr_in6
   AF_UNIX  pack_sockaddr_un  unpack_sockaddr_un
   inet_aton inet_pton inet_ntoa inet_ntop
   INADDR_ANY
);

use POSIX qw( SIGTERM );

SKIP: {
   skip "No IO::Socket::IP", 2 unless eval { require IO::Socket::IP };

   my $S_inet = IO::Async::OS->socket( "inet", "stream" );
   isa_ok( $S_inet, [ "IO::Socket::IP" ], 'IO::Async::OS->socket("inet") isa IO::Socket::IP' );

   SKIP: {
      skip "No AF_INET6", 1 unless eval { socket( my $fh, AF_INET6, SOCK_STREAM, 0 ) };

      my $S_inet6 = IO::Async::OS->socket( "inet6", "stream" );
      isa_ok( $S_inet6, [ "IO::Socket::IP" ], 'IO::Async::OS->socket("inet6") isa IO::Socket::IP' );
   }
}

foreach my $family ( undef, "inet" ) {
   my ( $S1, $S2 ) = IO::Async::OS->socketpair( $family, "stream" )
      or die "Could not socketpair - $!";

   isa_ok( $S1, [ "IO::Socket" ], '$S1 isa IO::Socket' );
   isa_ok( $S2, [ "IO::Socket" ], '$S2 isa IO::Socket' );

   # Due to a bug in IO::Socket, ->socktype may not be set

   is( $S1->sockopt(SO_TYPE), SOCK_STREAM, 'SO_TYPE of $S1 is SOCK_STREAM' );
   is( $S2->sockopt(SO_TYPE), SOCK_STREAM, 'SO_TYPE of $S2 is SOCK_STREAM' );

   $S1->syswrite( "Hello" );
   is( do { my $b; $S2->sysread( $b, 8192 ); $b }, "Hello", '$S1 --writes-> $S2' );

   $S2->syswrite( "Goodbye" );
   is( do { my $b; $S1->sysread( $b, 8192 ); $b }, "Goodbye", '$S2 --writes-> $S1' );

   ( $S1, $S2 ) = IO::Async::OS->socketpair( $family, "dgram" )
      or die "Could not socketpair - $!";

   isa_ok( $S1, [ "IO::Socket" ], '$S1 isa IO::Socket' );
   isa_ok( $S2, [ "IO::Socket" ], '$S2 isa IO::Socket' );

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
is( IO::Async::OS->signum2name( SIGTERM ), "TERM", 'signum2name' );

# RT145759
is( IO::Async::OS->signum2name( IO::Async::OS->signame2num( "ABRT" ) ), "ABRT",
   'signum2name gives correct result for aliased signals' );

is( IO::Async::OS->getfamilybyname( "inet" ),  AF_INET, 'getfamilybyname "inet"' );
is( IO::Async::OS->getfamilybyname( AF_INET ), AF_INET, 'getfamilybyname AF_INET' );

is( IO::Async::OS->getsocktypebyname( "stream" ),    SOCK_STREAM, 'getsocktypebyname "stream"' );
is( IO::Async::OS->getsocktypebyname( SOCK_STREAM ), SOCK_STREAM, 'getsocktypebyname SOCK_STREAM' );

{
   my $sinaddr = pack_sockaddr_in( 56, inet_aton( "1.2.3.4" ) );

   is( [ IO::Async::OS->extract_addrinfo( [ "inet", "stream", 0, $sinaddr ] ) ],
              [ AF_INET, SOCK_STREAM, 0, $sinaddr ],
              'extract_addrinfo( ARRAY )' );

   is( [ IO::Async::OS->extract_addrinfo( {
                  family   => "inet",
                  socktype => "stream",
                  addr     => $sinaddr 
                } ) ],
              [ AF_INET, SOCK_STREAM, 0, $sinaddr ],
              'extract_addrinfo( HASH )' );

   is( [ IO::Async::OS->extract_addrinfo( {
                  family   => "inet",
                  socktype => "stream",
                  ip       => "1.2.3.4",
                  port     => "56",
                } ) ],
              [ AF_INET, SOCK_STREAM, 0, $sinaddr ],
              'extract_addrinfo( HASH ) with inet, ip+port' );

   is( [ IO::Async::OS->extract_addrinfo( {
                  family   => "inet",
                  socktype => "stream",
                  port     => "56",
                } ) ],
              [ AF_INET, SOCK_STREAM, 0, pack_sockaddr_in( 56, INADDR_ANY ) ],
              'extract_addrinfo( HASH ) with inet, port' );

   is( [ IO::Async::OS->extract_addrinfo( {
                  family   => "inet",
                  socktype => "stream",
                } ) ],
              [ AF_INET, SOCK_STREAM, 0, pack_sockaddr_in( 0, INADDR_ANY ) ],
              'extract_addrinfo( HASH ) with inet only' );

   ok( dies { IO::Async::OS->extract_addrinfo( {
                     family  => "inet",
                     host    => "foobar.com",
                   } ) }, 'extract_addrinfo for inet complains about unrecognised key' );

   # ->make_addr_for_peer should rewrite 0.0.0.0 to 127.0.0.1
   my ( $port, $host ) = unpack_sockaddr_in(
      IO::Async::OS->make_addr_for_peer( AF_INET, pack_sockaddr_in( 567, inet_aton( "0.0.0.0" ) ) )
   );
   is( $port,              567,         'make_addr_for_peer preserves AF_INET port' );
   is( inet_ntoa( $host ), "127.0.0.1", 'make_addr_for_peer rewrites INADDR_ANY to _LOCALHOST' );

   ( undef, $host ) = unpack_sockaddr_in(
      IO::Async::OS->make_addr_for_peer( AF_INET, pack_sockaddr_in( 567, inet_aton( "1.2.3.4" ) ) )
   );
   is( inet_ntoa( $host ), "1.2.3.4",   'make_addr_for_peer preserves AF_INET other host' );
}

SKIP: {
   my $sin6addr = eval { Socket::pack_sockaddr_in6( 1234, inet_pton( AF_INET6, "fe80::5678" ) ) };
   skip "No pack_sockaddr_in6", 1 unless defined $sin6addr;

   is( [ IO::Async::OS->extract_addrinfo( {
                  family   => "inet6",
                  socktype => "stream",
                  ip       => "fe80::5678",
                  port     => "1234",
                } ) ],
              [ AF_INET6, SOCK_STREAM, 0, $sin6addr ],
              'extract_addrinfo( HASH ) with inet6, ip+port' );

   # ->make_addr_for_peer should rewrite :: to ::1
   my ( $port, $host ) = unpack_sockaddr_in6(
      IO::Async::OS->make_addr_for_peer( AF_INET6, pack_sockaddr_in6( 567, inet_pton( AF_INET6, "::" ) ) )
   );
   is( $port,                        567,   'make_addr_for_peer preserves AF_INET6 port' );
   is( inet_ntop( AF_INET6, $host ), "::1", 'make_addr_for_peer rewrites IN6ADDR_ANY to _LOCALHOST' );

   ( undef, $host ) = unpack_sockaddr_in6(
      IO::Async::OS->make_addr_for_peer( AF_INET6, pack_sockaddr_in6( 567, inet_pton( AF_INET6, "fe80::1234" ) ) )
   );
   is( inet_ntop( AF_INET6, $host ), "fe80::1234",   'make_addr_for_peer preserves AF_INET6 other host' );
}

SKIP: {
   skip "No pack_sockaddr_un", 1 unless IO::Async::OS->HAVE_SOCKADDR_UN;
   my $sunaddr = pack_sockaddr_un( "foo.sock" );

   is( [ IO::Async::OS->extract_addrinfo( {
                  family   => "unix",
                  socktype => "stream",
                  path     => "foo.sock",
                } ) ],
              [ AF_UNIX, SOCK_STREAM, 0, $sunaddr ],
              'extract_addrinfo( HASH ) with unix, path' );

   # ->make_addr_for_peer should leave address undisturbed
   my ( $path ) = unpack_sockaddr_un(
      IO::Async::OS->make_addr_for_peer( AF_UNIX, pack_sockaddr_un( "/tmp/mysock" ) )
   );
   is( $path, "/tmp/mysock", 'make_addr_for_peer preserves AF_UNIX path' );
}

ok( dies { IO::Async::OS->extract_addrinfo( { family => "hohum" } ) },
   'extract_addrinfo on unrecognised family complains' );

done_testing;
