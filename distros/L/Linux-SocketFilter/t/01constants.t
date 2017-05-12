#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use Linux::SocketFilter qw( :bpf SKF_AD_OFF SKF_NET_OFF SO_ATTACH_FILTER );

# Just a small selection of the constants; if these are working we'll presume
# the rest are

ok( defined BPF_X, 'BPF_X' );
ok( defined BPF_ALU, 'BPF_ALU' );

ok( defined SKF_AD_OFF, 'SKF_AD_OFF' );
ok( defined SKF_NET_OFF, 'SKF_NET_OFF' );

ok( defined SO_ATTACH_FILTER, 'SO_ATTACH_FILTER' );
