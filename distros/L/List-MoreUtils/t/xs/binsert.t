#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");


use Test::More;
use Test::LMU;

SCOPE: {
    my @list = ();
    is(0, (binsert { $_ cmp "Hello" } "Hello", @list), "Inserting into empty list");
    is(1, (binsert { $_ cmp "world" } "world", @list), "Inserting into one-item list");
}

my @even = map { $_ * 2 } 1 .. 100;
my @odd  = map { $_ * 2 - 1 } 1 .. 100;
my (@expected, @in);

@in = @even;
@expected = mesh @odd, @even;
foreach my $v (@odd)
{
    binsert { $_ <=> $v } $v, @in;
}
is_deeply(\@in, \@expected, "binsert odd elements into even list succeeded");

@in = @even;
@expected = mesh @odd, @even;
foreach my $v (reverse @odd)
{
    binsert { $_ <=> $v } $v, @in;
}
is_deeply(\@in, \@expected, "binsert odd elements reversely into even list succeeded");

@in = @odd;
foreach my $v (@even)
{
    binsert { $_ <=> $v } $v, @in;
}
is_deeply(\@in, \@expected, "binsert even elements into odd list succeeded");

@in = @odd;
foreach my $v (reverse @even)
{
    binsert { $_ <=> $v } $v, @in;
}
is_deeply(\@in, \@expected, "binsert even elements reversely into odd list succeeded");

@in = @even;
@expected = map { $_, $_ } @in;
foreach my $v (@even)
{
    binsert { $_ <=> $v } $v, @in;
}
is_deeply(\@in, \@expected, "binsert existing even elements into even list succeeded");

@in = @even;
@expected = map { $_, $_ } @in;
foreach my $v (reverse @even)
{
    binsert { $_ <=> $v } $v, @in;
}
is_deeply(\@in, \@expected, "binsert existing even elements reversely into even list succeeded");

leak_free_ok(
    'binsert random' => sub {
        my @list = map { $_ * 2 } 1 .. 100;
        my $elem = int(rand(100)) + 1;
        binsert { $_ <=> $elem } $elem, @list;
    },
    'binsert existing random' => sub {
        my @list = map { $_ * 2 } 1 .. 100;
        my $elem = 2 * (int(rand(100)) + 1);
        binsert { $_ <=> $elem } $elem, @list;
    },
    'binsert odd into even' => sub {
        my @list = @even;
        foreach my $elem (@odd)
        {
            binsert { $_ <=> $elem } $elem, @list;
        }
    },
    'binsert even into odd' => sub {
        my @list = @odd;
        foreach my $elem (@even)
        {
            binsert { $_ <=> $elem } $elem, @list;
        }
    },
    'binsert odd into odd' => sub {
        my @list = @odd;
        foreach my $elem (@odd)
        {
            binsert { $_ <=> $elem } $elem, @list;
        }
    },
    'binsert even into even' => sub {
        my @list = @even;
        foreach my $elem (@even)
        {
            binsert { $_ <=> $elem } $elem, @list;
        }
    },
);

leak_free_ok(
    'binsert random with stack-growing' => sub {
        my @list = map { $_ * 2 } 1 .. 100;
        my $elem = int(rand(100)) + 1;
        binsert { grow_stack(); $_ <=> $elem } $elem, @list;
    },
    'binsert odd with stack-growing' => sub {
        my @list = @even;
        foreach my $elem (@odd)
        {
            binsert { grow_stack(); $_ <=> $elem } $elem, @list;
        }
    },
    'binsert even with stack-growing' => sub {
        my @list = @odd;
        foreach my $elem (@even)
        {
            binsert { grow_stack(); $_ <=> $elem } $elem, @list;
        }
    },
);

leak_free_ok(
    'binsert with stack-growing and exception' => sub {
        my @list = map { $_ * 2 } 1 .. 100;
        my $elem = int(rand(100)) + 1;
        eval {
            binsert { grow_stack(); $_ <=> $elem or die "Goal!"; $_ <=> $elem } $elem, @list;
        };
    }
);

is_dying('binsert without sub' => sub { &binsert(42, @even); });

done_testing;


