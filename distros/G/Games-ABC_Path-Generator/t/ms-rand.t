#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use Test::Differences;

use Games::ABC_Path::MicrosoftRand;

{
    my $r = Games::ABC_Path::MicrosoftRand->new(seed => 1);

    # TEST
    is ($r->rand(), 41, "First result for seed 1 is 41.");

    # TEST
    is ($r->rand(), 18_467, "2nd result for seed 1 is 18,467.");

    # TEST
    is ($r->rand(), 6_334, "3rd result for seed 1 is 6,334.");
}

{
    my $r = Games::ABC_Path::MicrosoftRand->new(seed => 24);

    my @array = (0 .. 9);

    my $ret = $r->shuffle(\@array);
    # TEST
    eq_or_diff(
        \@array,
        [1,7,9,8,4,5,3,2,0,6],
        'Array was shuffled.',
    );

    # TEST
    is ($ret, (\@array), 'shuffle returns the same array.');
}
