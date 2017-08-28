#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");


use Test::More;
use Test::LMU;
use Tie::Array ();

SCOPE:
{
    my @s = (1001 .. 1200);
    my @d = map { (1 .. 1000) } 0 .. 1;
    my @a = (@d, @s);
    my @u = singleton @a;
    is_deeply(\@u, [@s]);
    my $u = singleton @a;
    is(200, $u);
}

# Test strings
SCOPE:
{
    my @s = ("AA" .. "ZZ");
    my @d = map { ("aa" .. "zz") } 0 .. 1;
    my @a = (@d, @s);
    my @u = singleton @a;
    is_deeply(\@u, [@s]);
    my $u = singleton @a;
    is(scalar @s, $u);
}

# Test mixing strings and numbers
SCOPE:
{
    my @s  = (1001 .. 1200, "AA" .. "ZZ");
    my $fs = freeze(\@s);
    my @d  = map { (1 .. 1000, "aa" .. "zz") } 0 .. 1;
    my @a  = (@d, @s);
    my $fa = freeze(\@a);
    my @u  = singleton map { $_ } @a;
    my $fu = freeze(\@u);
    is_deeply(\@u, [@s]);
    is($fs, freeze(\@s));
    is($fa, freeze(\@a));
    is($fu, $fs);
    my $u = singleton @a;
    is(scalar @s, $u);
}

SCOPE:
{
    my @a;
    tie @a, "Tie::StdArray";
    my @s = (1001 .. 1200, "AA" .. "ZZ");
    my @d = map { (1 .. 1000, "aa" .. "zz") } 0 .. 1;
    @a = (@d, @s);
    my @u = singleton map { $_ } @a;
    is_deeply(\@u, [@s]);
    @a = (@d, @s);
    my $u = singleton @a;
    is(scalar @s, $u);
}

SCOPE:
{
    my @foo = ('a', 'b', '', undef, 'b', 'c', '');
    my @sfoo = ('a', undef, 'c');
    is_deeply([singleton @foo], \@sfoo, 'one undef is supported correctly by singleton');
    @foo = ('a', 'b', '', undef, 'b', 'c', undef);
    @sfoo = ('a', '', 'c');
    is_deeply([singleton @foo], \@sfoo, 'twice undef is supported correctly by singleton');
    is((scalar singleton @foo), scalar @sfoo, 'scalar twice undef is supported correctly by singleton');
}

leak_free_ok(
    singleton => sub {
        my @s = (1001 .. 1200, "AA" .. "ZZ");
        my @d = map { (1 .. 1000, "aa" .. "zz") } 0 .. 1;
        my @a = (@d, @s);
        my @u = singleton @a;
        scalar singleton @a;
    }
);

# This test (and the associated fix) are from Kevin Ryde; see RT#49796
leak_free_ok(
    'singleton with exception in overloading stringify',
    sub {
        eval {
            my $obj = DieOnStringify->new;
            my @u = singleton $obj, $obj;
        };
        eval {
            my $obj = DieOnStringify->new;
            my $u = singleton $obj, $obj;
        };
    }
);

done_testing;


