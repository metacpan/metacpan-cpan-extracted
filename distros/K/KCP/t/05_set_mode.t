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

ok(
    $kcp->set_mode("normal") &&
    $kcp->set_mode("fast"),
    "valid mode"
);

invalid_test("invalid mode", $kcp, "set_mode", "aaa");

done_testing;
