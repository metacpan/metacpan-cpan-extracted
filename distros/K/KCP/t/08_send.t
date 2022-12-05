#
# Copyright (c) homqyy
#
use strict;
use warnings;

use KCP;
use Test::More tests => 2;

#########################

sub output
{
    my ($buffer, $user) = @_;

    is(substr($buffer, 24), "\x01\x02\x03\x04", "data is right");
}

my $kcp = KCP::new(1);

ok($kcp->set_output(\&output)
    ->update(10)
    ->send("\x01\x02\x03\x04"), "success to send data");

$kcp->update(10 + $kcp->get_interval);
