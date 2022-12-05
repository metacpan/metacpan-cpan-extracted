#
# Copyright (c) homqyy
#
use strict;
use warnings;

use KCP;
use Test::More;

#########################


my $kcp = KCP::new(2);

{
    my $conv="\x01\x00\x00\x00";
    is($kcp->get_conv($conv), 1, "parse scalar");
}

is($kcp->get_conv("\x01\x00\x00\x00"), 1, "parse literal");

is($kcp->get_conv(), 2, "self");

done_testing;