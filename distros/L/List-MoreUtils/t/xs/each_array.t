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
    my @a  = (7, 3, 'a', undef, 'r');
    my @b  = qw{ a 2 -1 x };
    my $it = each_array @a, @b;
    my (@r, @idx);
    while (my ($a, $b) = $it->())
    {
        push @r, $a, $b;
        push @idx, $it->('index');
    }

    # Do I segfault? I shouldn't.
    $it->();

    is_deeply(\@r, [7, 'a', 3, 2, 'a', -1, undef, 'x', 'r', undef]);
    is_deeply(\@idx, [0 .. 4]);

    # Testing two iterators on the same arrays in parallel
    @a = (1, 3, 5);
    @b = (2, 4, 6);
    my $i1 = each_array @a, @b;
    my $i2 = each_array @a, @b;
    @r = ();
    while (my ($a, $b) = $i1->() and my ($c, $d) = $i2->())
    {
        push @r, $a, $b, $c, $d;
    }
    is_deeply(\@r, [1, 2, 1, 2, 3, 4, 3, 4, 5, 6, 5, 6]);

    # Input arrays must not be modified
    is_deeply(\@a, [1, 3, 5]);
    is_deeply(\@b, [2, 4, 6]);

    # This used to give "semi-panic: attempt to dup freed string"
    # See: <news:1140827861.481475.111380@z34g2000cwc.googlegroups.com>
    my $ea = each_arrayref([1 .. 26], ['A' .. 'Z']);
    (@a, @b) = ();
    while (my ($a, $b) = $ea->())
    {
        push @a, $a;
        push @b, $b;
    }
    is_deeply(\@a, [1 .. 26]);
    is_deeply(\@b, ['A' .. 'Z']);

    # And this even used to dump core
    my @nums = 1 .. 26;
    $ea = each_arrayref(\@nums, ['A' .. 'Z']);
    (@a, @b) = ();
    while (my ($a, $b) = $ea->())
    {
        push @a, $a;
        push @b, $b;
    }
    is_deeply(\@a, [1 .. 26]);
    is_deeply(\@a, \@nums);
    is_deeply(\@b, ['A' .. 'Z']);
}

SCOPE:
{
    my @a = (7, 3, 'a', undef, 'r');
    my @b = qw/a 2 -1 x/;

    my $it = each_arrayref \@a, \@b;
    my (@r, @idx);
    while (my ($a, $b) = $it->())
    {
        push @r, $a, $b;
        push @idx, $it->('index');
    }

    # Do I segfault? I shouldn't.
    $it->();

    is_deeply(\@r, [7, 'a', 3, 2, 'a', -1, undef, 'x', 'r', undef]);
    is_deeply(\@idx, [0 .. 4]);

    # Testing two iterators on the same arrays in parallel
    @a = (1, 3, 5);
    @b = (2, 4, 6);
    my $i1 = each_array @a, @b;
    my $i2 = each_array @a, @b;
    @r = ();
    while (my ($a, $b) = $i1->() and my ($c, $d) = $i2->())
    {
        push @r, $a, $b, $c, $d;
    }
    is_deeply(\@r, [1, 2, 1, 2, 3, 4, 3, 4, 5, 6, 5, 6]);

    # Input arrays must not be modified
    is_deeply(\@a, [1, 3, 5]);
    is_deeply(\@b, [2, 4, 6]);
}

# Note that the leak_free_ok tests for each_array and each_arrayref
# should not be run until either of them has been called at least once
# in the current perl.  That's because calling them the first time
# causes the runtime to allocate some memory used for the OO structures
# that their implementation uses internally.
leak_free_ok(
    each_array => sub {
        my @a  = (1);
        my $it = each_array @a;
        while (my ($a) = $it->())
        {
        }
    }
);
leak_free_ok(
    each_arrayref => sub {
        my @a  = (1);
        my $it = each_arrayref \@a;
        while (my ($a) = $it->())
        {
        }
    }
);
is_dying('each_array without sub' => sub { &each_array(42, 4711); });
is_dying('each_arrayref without sub' => sub { &each_arrayref(42, 4711); });

done_testing;


