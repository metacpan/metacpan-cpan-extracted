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
    my @s  = (1001 .. 1200);
    my @d  = (1 .. 1000);
    my @a  = (@d, @s, @d);
    my $fa = freeze(\@a);
    my @u  = duplicates @a;
    is($fa, freeze(\@a), "duplicates:G_ARRAY leaves numbers untouched");
    is_deeply(\@u, [@d], "duplicates of numbers");
    my $u = duplicates @a;
    is($fa,       freeze(\@a), "duplicates:G_SCALAR leaves numbers untouched");
    is(scalar @d, $u,          "scalar result of duplicates of numbers");
}

# Test strings
SCOPE:
{
    my @s  = ("AA" .. "ZZ");
    my @d  = ("aa" .. "zz");
    my @a  = (@d, @s, @d);
    my $fa = freeze(\@a);
    my @u  = duplicates @a;
    is($fa, freeze(\@a), "duplicates:G_ARRAY leaves numbers untouched");
    is_deeply(\@u, [@d], "duplicates of numbers");
    my $u = duplicates @a;
    is($fa,       freeze(\@a), "duplicates:G_SCALAR leaves numbers untouched");
    is(scalar @d, $u,          "scalar result of duplicates of numbers");
}

# Test mixing strings and numbers
SCOPE:
{
    my @s = (1001 .. 1200, "AA" .. "ZZ");
    my @d = (1 .. 1000,    "aa" .. "zz");
    my $fd = freeze(\@d);
    my @a  = (@d, @s, @d);
    my $fa = freeze(\@a);
    my @u  = duplicates map { $_ } @a;
    my $fu = freeze(\@u);
    is_deeply(\@u, [@d], "duplicates of numbers/strings mixture");
    is($fd, freeze(\@d), "frozen duplicates of numbers/strings mixture");
    is($fa, freeze(\@a), "duplicates:G_ARRAY leaves mixture untouched");
    is($fu, $fd);
    my $u = duplicates @a;
    is($fa,       freeze(\@a), "duplicates:G_SCALAR leaves mixture untouched");
    is(scalar @d, $u,          "scalar result of duplicates of numbers/strings mixture");
}

SCOPE:
{
    my @a;
    tie @a, "Tie::StdArray";
    my @s = (1001 .. 1200, "AA" .. "ZZ");
    my @d = (1 .. 1000,    "aa" .. "zz");
    @a = (@d, @s, @d);
    my $fa = freeze(\@a);
    my @u  = duplicates @a;
    is_deeply(\@u, [@d], "duplicates of tied array of numbers/strings mixture");
    is($fa, freeze(\@a), "duplicates:G_ARRAY leaves mixture untouched");
    @a = (@u, @d);
    $fa = freeze(\@a);
    my $u = duplicates @a;
    is($fa,       freeze(\@a), "duplicates:G_SCALAR leaves mixture untouched");
    is(scalar @d, $u,          "scalar result of duplicates of tied array of numbers/strings mixture");
}

SCOPE:
{
    my @foo = ('a', 'b', '', undef, 'b', 'c', '', undef);
    my @dfoo = ('b', '', undef);
    is_deeply([duplicates @foo], \@dfoo, "two undef's are supported correctly by duplicates");
    @foo = ('a', undef, 'b', '', 'b', 'c', '');
    @dfoo = ('b', '');
    is_deeply([duplicates @foo], \@dfoo, 'one undef is ignored correctly by duplicates');
    is((scalar duplicates @foo), scalar @dfoo, 'scalar one undef is ignored correctly by duplicates');
}

leak_free_ok(
    duplicates => sub {
        my @s = (1001 .. 1200, "AA" .. "ZZ");
        my @d = map { (1 .. 1000, "aa" .. "zz") } 0 .. 1;
        my @a = (@d, @s);
        my @u = duplicates @a;
        scalar duplicates @a;
    }
);

# This test (and the associated fix) are from Kevin Ryde; see RT#49796
leak_free_ok(
    'duplicates with exception in overloading stringify',
    sub {
        eval {
            my $obj = DieOnStringify->new;
            my @foo = ('a', 'b', '', undef, $obj, 'b', 'c', '', undef, $obj);
            my @u   = duplicates @foo;
        };
        eval {
            my $obj = DieOnStringify->new;
            my $u = duplicates 'a', 'b', '', undef, $obj, 'b', 'c', '', undef, $obj;
        };
    }
);

done_testing;



