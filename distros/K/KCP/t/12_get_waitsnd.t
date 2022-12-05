#
# Copyright (c) homqyy
#
use strict;
use warnings;

use KCP;
use KCP::Test;
use Test::More tests => 2;

#########################

my $kcp = KCP::new(1)->update(10);

is($kcp->get_waitsnd, 0, "no waitsnd");

$kcp->send("123");
$kcp->send("123");
$kcp->send("123");
$kcp->update(10 + $kcp->get_interval);

is($kcp->get_waitsnd, 3, "waitsnd");