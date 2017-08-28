#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");

BEGIN
{
    $INC{'List/MoreUtils.pm'} or *zip = __PACKAGE__->can("mesh");
}

use Test::More;
use Test::LMU;

SCOPE:
{
    my @x = qw/a b c d/;
    my @y = qw/1 2 3 4/;
    my @z = mesh @x, @y;
    is_deeply(\@z, ['a', 1, 'b', 2, 'c', 3, 'd', 4], "mesh two list with same count of elements");
}

SCOPE:
{
    # alias check
    my @x = qw/a b c d/;
    my @y = qw/1 2 3 4/;
    my @z = zip @x, @y;
    is_deeply(\@z, ['a', 1, 'b', 2, 'c', 3, 'd', 4], "zip two list with same count of elements");
}

SCOPE:
{
    my @a = ('x');
    my @b = ('1', '2');
    my @c = qw/zip zap zot/;
    my @z = mesh @a, @b, @c;
    is_deeply(\@z, ['x', 1, 'zip', undef, 2, 'zap', undef, undef, 'zot'], "mesh three list with increasing count of elements");
}

SCOPE:
{
    # alias check
    my @a = ('x');
    my @b = ('1', '2');
    my @c = qw/zip zap zot/;
    my @z = zip @a, @b, @c;
    is_deeply(\@z, ['x', 1, 'zip', undef, 2, 'zap', undef, undef, 'zot'], "zip three list with increasing count of elements");
}

# Make array with holes
SCOPE:
{
    my @a = (1 .. 10);
    my @d;
    $#d = 9;
    my @z = mesh @a, @d;
    is_deeply(
        \@z,
        [1, undef, 2, undef, 3, undef, 4, undef, 5, undef, 6, undef, 7, undef, 8, undef, 9, undef, 10, undef,],
        "mesh one list with 9 elements with an empty list"
    );
}

leak_free_ok(
    mesh => sub {
        my @x = qw/a b c d e/;
        my @y = qw/1 2 3 4/;
        my @z = mesh @x, @y;
    }
);
is_dying('mesh with a list, not at least two arrays' => sub { &mesh(1, 2); });

done_testing;


