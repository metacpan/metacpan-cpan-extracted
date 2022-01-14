#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Future::IO::Impl;

use Future::IO;
use Future::IO::Impl::UV;

use IO::Socket::INET;
use Socket qw( AF_INET SOCK_STREAM );

# stolen from UV/t/lib/UVTestHelpers.pm
sub socketpair_inet_stream
{
    my ($rd, $wr);

    # Maybe socketpair(2) can do it?
    ($rd, $wr) = IO::Socket->socketpair(AF_INET, SOCK_STREAM, 0)
        and return ($rd, $wr);

    # If not, go the long way round
    my $listen = IO::Socket::INET->new(
        LocalHost => "127.0.0.1",
        LocalPort => 0,
        Listen    => 1,
    ) or die "Cannot listen - $@";

    $rd = IO::Socket::INET->new(
        PeerHost => $listen->sockhost,
        PeerPort => $listen->sockport,
    ) or die "Cannot connect - $@";

    $wr = $listen->accept or die "Cannot accept - $!";

    return ($rd, $wr);
}

# write-after-read
{
   my ( $S1, $S2 ) = socketpair_inet_stream;

   $S1->syswrite( "INPUT\n" );

   my $f = Future::IO->sysread( $S2, 8192 )->then( sub {
      my ( $in ) = @_;
      is( $in, "INPUT\n", '->sysread data' );

      Future::IO->syswrite( $S2, "OUTPUT\n" );
   });

   is( $f->get, 7, '$f returns syswrite length' );

   my $buf;
   $S1->sysread( $buf, 8192 );
   is( $buf, "OUTPUT\n", '->syswrite data came back' );
}

# read-after-write
{
   my ( $S1, $S2 ) = socketpair_inet_stream;

   my $f = Future::IO->syswrite( $S2, "OUTPUT\n" )->then( sub {
      Future::IO->sysread( $S2, 8192 );
   });

   $S1->syswrite( "INPUT\n" );

   is( $f->get, "INPUT\n", '$f returns sysread result' );

   my $buf;
   $S1->sysread( $buf, 8192 );
   is( $buf, "OUTPUT\n", '->syswrite data came back' );
}

done_testing;
