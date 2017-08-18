#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");

BEGIN
{
    $INC{'List/MoreUtils.pm'} or *distinct = __PACKAGE__->can("uniq");
}

use Test::More;
use Test::LMU;
use Tie::Array ();

SCOPE:
{
    my @a = map { (1 .. 10) } 0 .. 1;
    my @u = uniq @a;
    is_deeply(\@u, [1 .. 10]);
    my $u = uniq @a;
    is(10, $u);
}

# Test aliases
SCOPE:
{
    my @a = map { (1 .. 10) } 0 .. 1;
    my @u = distinct @a;
    is_deeply(\@u, [1 .. 10]);
    my $u = distinct @a;
    is(10, $u);
}

# Test strings
SCOPE:
{
    my @a = map { ("a" .. "z") } 0 .. 1;
    my @u = uniq @a;
    is_deeply(\@u, ["a" .. "z"]);
    my $u = uniq @a;
    is(26, $u);
}

# Test mixing strings and numbers
SCOPE:
{
    my @a  = ((map { (1 .. 10) } 0 .. 1), (map { ("a" .. "z") } 0 .. 1));
    my $fa = freeze(\@a);
    my @u  = uniq map { $_ } @a;
    my $fu = freeze(\@u);
    is_deeply(\@u, [1 .. 10, "a" .. "z"]);
    is($fa, freeze(\@a));
    is($fu, freeze([1 .. 10, "a" .. "z"]));
    my $u = uniq @a;
    is(10 + 26, $u);
}

SCOPE:
{
    my @a;
    tie @a, "Tie::StdArray";
    @a = ((map { (1 .. 10) } 0 .. 1), (map { ("a" .. "z") } 0 .. 1));
    my @u = uniq @a;
    is_deeply(\@u, [1 .. 10, "a" .. "z"]);
    @a = ((map { (1 .. 10) } 0 .. 1), (map { ("a" .. "z") } 0 .. 1));
    my $u = uniq @a;
    is(10 + 26, $u);
}

SCOPE:
{
    my @foo = ('a', 'b', '', undef, 'b', 'c', '');
    my @ufoo = ('a', 'b', '', undef, 'c');
    is_deeply([uniq @foo], \@ufoo, 'undef is supported correctly');
}

leak_free_ok(
    uniq => sub {
        my @a = map { (1 .. 1000) } 0 .. 1;
        my @u = uniq @a;
        uniq @a[1 .. 100];
    }
);

# This test (and the associated fix) are from Kevin Ryde; see RT#49796
leak_free_ok(
    'uniq with exception in overloading stringify',
    sub {
        eval {
            my $obj = DieOnStringify->new;
            my @u = uniq "foo", $obj, "bar", $obj;
        };
    }
);

done_testing;


