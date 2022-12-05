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

ok($kcp->nodelay, "null value");

{
    my $s = 1;

    ok(
        $kcp->nodelay(nodelay => 1) &&
        $kcp->nodelay(nodelay => $s),
        "nodelay is numerical"
    );

    invalid_test("nodelay is numerical", $kcp, 'nodelay', nodelay => 10);
}

{
    invalid_test("nodelay isn't numerical", $kcp, 'nodelay', nodelay => '1');
    invalid_test("nodelay isn't numerical", $kcp, 'nodelay', nodelay => '10');
    invalid_test("nodelay isn't numerical", $kcp, 'nodelay', nodelay => 'abcd');
    invalid_test("nodelay isn't numerical", $kcp, 'nodelay', nodelay => '1abc');
    invalid_test("nodelay isn't numerical", $kcp, 'nodelay', nodelay => 'abc4');
}

done_testing;