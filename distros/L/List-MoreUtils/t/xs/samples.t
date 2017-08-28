#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");


use Test::More;
use Test::LMU;

SCOPE:
{
    my @l = (1 .. 100);
    my @s = samples 10, @l;
    is(scalar @s, 10, "samples stops correctly after 10 integer probes");
    my @u = uniq @s;
    is(scalar @u, 10, "samples doesn't add any integer twice");
}

SCOPE:
{
    my @l = (1 .. 10);
    my @s = samples 10, @l;
    is(scalar @s, 10, "samples delivers 10 out of 10 when used as shuffle");
    my @u = uniq grep {defined $_ } @s;
    is(scalar @u, 10, "samples doesn't add any integer twice");
}

SCOPE:
{
    my @l = ('AA' .. 'ZZ');
    my @s = samples 10, @l;
    is(scalar @s, 10, "samples stops correctly after 10 strings probes");
    my @u = uniq @s;
    is(scalar @u, 10, "samples doesn't add any string twice");
}

is_dying('to much samples' => sub { my @l = (1 .. 3); samples 5, @l });
SKIP:
{
    $INC{'List/MoreUtils/XS.pm'} or skip "PurePerl will not fail here ...", 1;
    is_dying('samples without list' => sub { samples 5 });
}

done_testing;


