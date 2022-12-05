#
# Copyright (c) homqyy
#
use strict;
use warnings;

use KCP;
use KCP::Test;
use Test::More tests => 6;

#########################

my $kcp = KCP::new(1);

# sndwnd
is($kcp->sndwnd, 32, "get sndwnd default");

is($kcp->sndwnd(64), 32, "set sndwnd success");
is($kcp->sndwnd, 64, "check set sndwnd value");

# rcvwnd
is($kcp->rcvwnd, 128, "get rcvwnd default");

is($kcp->rcvwnd(512), 128, "set rcvwnd success");
is($kcp->rcvwnd, 512, "check set rcvwnd value");