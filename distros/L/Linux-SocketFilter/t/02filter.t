#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Linux::SocketFilter qw(
   BPF_RET BPF_IMM
   pack_sock_filter unpack_sock_filter
);

my $filter = pack_sock_filter( BPF_RET|BPF_IMM, 4, 0, 0 );

ok( defined $filter, '$filter defined' );
is( length $filter, 8, '$filter is length 8' );

is_deeply( [ unpack_sock_filter $filter ], 
           [ BPF_RET|BPF_IMM, 4, 0, 0 ],
           'unpack_sock_filter' );
