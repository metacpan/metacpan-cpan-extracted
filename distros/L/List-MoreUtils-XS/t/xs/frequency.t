#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");


use Test::More;
use Test::LMU;
use Tie::Array ();

SCOPE:
{
    my @s  = (1001 .. 1200);
    my @d  = (1 .. 1000);
    my @a  = (@d, @s, @d);
    my %e  = ((map { $_ => 2 } @d), map { $_ => 1 } @s);
    my $fa = freeze(\@a);
    my %f  = frequency @a;
    is($fa, freeze(\@a), "frequency:G_ARRAY leaves numbers untouched");
    is_deeply(\%f, {%e}, "frequency of numbers");
    my $f = frequency @a;
    is($fa,            freeze(\@a), "frequency:G:SCALAR leaves numbers untouched");
    is(scalar keys %e, $f,          "scalar result of frequency of numbers");
}

# Test strings
SCOPE:
{
    my @s  = ("AA" .. "ZZ");
    my @d  = ("aa" .. "zz");
    my @a  = (@d, @s, @d);
    my $fa = freeze(\@a);
    my %e  = ((map { $_ => 2 } @d), map { $_ => 1 } @s);
    my %f  = frequency @a;
    is($fa, freeze(\@a), "frequency:G_ARRAY leaves strings untouched");
    is_deeply(\%f, {%e}, "frequency of strings");
    my $f = frequency @a;
    is($fa,            freeze(\@a), "frequency:G_SCALAR leaves strings untouched");
    is(scalar keys %e, $f,          "scalar result of frequency of strings");
}

# Test mixing strings and numbers
SCOPE:
{
    my @s = (1001 .. 1200, "AA" .. "ZZ");
    my @d = (1 .. 1000,    "aa" .. "zz");
    my @a = (@d, @s, @d);
    my %e  = ((map { $_ => 2 } @d), map { $_ => 1 } @s);
    my $fa = freeze(\@a);
    my %f  = frequency @a;
    is($fa, freeze(\@a), "frequency:G_ARRAY leaves number/strings mixture untouched");
    is_deeply(\%f, {%e}, "frequency of number/strings mixture");
    my $f = frequency @a;
    is($fa,            freeze(\@a), "frequency:G_SCALAR leaves number/strings mixture untouched");
    is(scalar keys %e, $f,          "scalar result of frequency of number/strings mixture");
}

SCOPE:
{
    my @a;
    tie @a, "Tie::StdArray";
    my @s = (1001 .. 1200, "AA" .. "ZZ");
    my @d = (1 .. 1000,    "aa" .. "zz");
    @a = (@d, @s, @d);
    my $fa = freeze(\@a);
    my %e  = ((map { $_ => 2 } @d), map { $_ => 1 } @s);
    my %f  = frequency @a;
    is($fa, freeze(\@a), "frequency:G_ARRAY leaves tied array of number/strings mixture untouched");
    is_deeply(\%f, {%e}, "frequency of tied array of number/strings mixture");
    my $f = frequency @a;
    is($fa,            freeze(\@a), "frequency:G_SCALAR leaves tied array of number/strings mixture untouched");
    is(scalar keys %e, $f,          "scalar result of frequency of tied array of number/strings mixture");
}

SCOPE:
{
    my @foo = ('a', 'b', '', undef, 'b', 'c', '', undef);
    my %e = (
        a  => 1,
        b  => 2,
        '' => 2,
        c  => 1
    );
    my @f = frequency @foo;
    my $seen_undef;
    ref $f[-2] and ref $f[-2] eq "SCALAR" and not defined ${$f[-2]} and (undef, $seen_undef) = splice @f, -2, 2, ();
    my %f = @f;
    is_deeply(\%f, \%e, "stuff around undef's is supported correctly by frequency");
    is($seen_undef, 2, "two undef's are supported correctly by frequency");
}

leak_free_ok(
    frequency => sub {
        my @s = (1001 .. 1200, "AA" .. "ZZ");
        my @d = map { (1 .. 1000, "aa" .. "zz") } 0 .. 1;
        my @a = (@d, @s);
        my %f = frequency @a;
    },
    'scalar frequency' => sub {
        my @s = (1001 .. 1200, "AA" .. "ZZ");
        my @d = map { (1 .. 1000, "aa" .. "zz") } 0 .. 1;
        my @a = (@d, @s);
        my $f = frequency @a;
    }
);

leak_free_ok(
    'frequency with exception in overloading stringify',
    sub {
        eval {
            my $obj = DieOnStringify->new;
            my @foo = ('a', 'b', '', undef, $obj, 'b', 'c', '', undef, $obj);
            my %f   = frequency @foo;
        };
        eval {
            my $obj = DieOnStringify->new;
            my $f = frequency 'a', 'b', '', undef, $obj, 'b', 'c', '', undef, $obj;
        };
    }
);

done_testing;


