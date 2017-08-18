#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");

BEGIN
{
    $INC{'List/MoreUtils.pm'} or *first_index = __PACKAGE__->can("firstidx");
}

use Test::More;
use Test::LMU;

my @list = (1 .. 10000);
is(4999, (firstidx { $_ >= 5000 } @list),  "firstidx");
is(-1,   (firstidx { not defined } @list), "invalid firstidx");
is(0,    (firstidx { defined } @list),     "real firstidx");
is(-1, (firstidx {}), "empty firstidx");

SKIP:
{
    # Test the alias
    is(4999, first_index { $_ >= 5000 } @list);
    is(-1,   first_index { not defined } @list);
    is(0,    first_index { defined } @list);
    is(-1, first_index {});
}

leak_free_ok(
    firstidx => sub {
        my $i  = firstidx { $_ >= 5000 } @list;
        my $i2 = firstidx { $_ >= 5000 } 1 .. 10000;
    }
);
is_dying('firstidx without sub' => sub { &firstidx(42, 4711); });

done_testing;


