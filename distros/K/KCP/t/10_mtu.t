#
# Copyright (c) homqyy
#
use strict;
use warnings;

use KCP;
use KCP::Test;
use Test::More tests => 4;

#########################

my $kcp = KCP::new(1);

is($kcp->mtu, 1400, "get default");

is($kcp->mtu(1500), 1400, "set success");
is($kcp->mtu, 1500, "check set value");

invalid_test('invalid mtu', $kcp, 'mtu', 10);