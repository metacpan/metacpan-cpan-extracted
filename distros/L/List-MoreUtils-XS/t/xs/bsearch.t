#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");


use Test::More;
use Test::LMU;

my @list = my @in = 1 .. 1000;
for my $elem (@in)
{
    ok(scalar bsearch { $_ - $elem } @list);
}
for my $elem (@in)
{
    my ($e) = bsearch { $_ - $elem } @list;
    ok($e == $elem);
}
my @out = (-10 .. 0, 1001 .. 1011);
for my $elem (@out)
{
    my $r = bsearch { $_ - $elem } @list;
    ok(!defined $r);
}

leak_free_ok(
    bsearch => sub {
        my $elem = int(rand(1000)) + 1;
        scalar bsearch { $_ - $elem } @list;
    }
);

leak_free_ok(
    'bsearch with stack-growing' => sub {
        my $elem = int(rand(1000));
        scalar bsearch { grow_stack(); $_ - $elem } @list;
    }
);

leak_free_ok(
    'bsearch with stack-growing and exception' => sub {
        my $elem = int(rand(1000));
        eval {
            scalar bsearch { grow_stack(); $_ - $elem or die "Goal!"; $_ - $elem } @list;
        };
    }
);
is_dying('bsearch without sub' => sub { &bsearch(42, (1 .. 100)); });

done_testing;


