#
# Copyright (c) homqyy
#
use strict;
use warnings;

use KCP;
use KCP::Test;
use Test::More;

#########################

my $kcp = KCP::new(1);

is($kcp->get_interval, 40, "default interval");

is($kcp->nodelay(interval => 20)->get_interval, 20, "custom value");

done_testing;
