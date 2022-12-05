#
# Copyright (c) homqyy
#
use strict;
use warnings;

use KCP;
use Test::More tests => 4;

#########################

sub scalar_output
{
    my ($buffer, $user) = @_;

    is($user, "\x01\x00\x00\x00", "user is scalar");
}

sub ref_output
{
    my ($buffer, $user) = @_;

    is(${$user}, "\x01\x00\x00\x00", "user is ref");
}

my $user="\x01\x00\x00\x00";

{
    my $kcp = KCP::new(1, $user);

    ok($kcp->set_output(\&scalar_output), "set_output for scalar user");

    $kcp->update(10)->send("123");
    $kcp->update(10 + $kcp->get_interval);
}

{
    my $kcp = KCP::new(1, \$user);

    ok($kcp->set_output(\&ref_output), "set_output for ref user");

    $kcp->update(10)->send("123");
    $kcp->update(10 + $kcp->get_interval);
}