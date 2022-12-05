#
# Copyright (c) homqyy
#
use strict;
use warnings;

use Time::HiRes qw/ gettimeofday usleep /;
use KCP;
use Test::More;

#########################

sub get_current()
{
    my ($seconds, $microseconds) = gettimeofday;

    return $seconds * 1000 + $microseconds;
}

my $kcp = KCP::new(1);

isa_ok($kcp->update(&get_current), "KCP", "update");
usleep(10);
isa_ok($kcp->update(&get_current)->update(&get_current), "KCP", "continous update: 2");

done_testing;