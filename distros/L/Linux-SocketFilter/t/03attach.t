#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Linux::SocketFilter qw(
   BPF_RET BPF_IMM pack_sock_filter
   attach_filter detach_filter
);

use IO::Socket::UNIX;

my ( $S1, $S2 ) = IO::Socket->socketpair( AF_UNIX, SOCK_DGRAM, 0 );

defined $S1 or die "Cannot create test socketpair - $!";

my $filter = pack_sock_filter( BPF_RET|BPF_IMM, 0, 0, 4 );

ok( attach_filter( $S1, $filter ), 'attach_filter' );

ok( detach_filter( $S1 ), 'detach_filter' );

ok( $S1->attach_filter( $filter ), 'attach_filter as IO::Socket method' );

ok( $S1->detach_filter, 'detach_filter as IO::Socket method' );
