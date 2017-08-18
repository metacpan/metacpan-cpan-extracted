#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");


use Test::More;
use Test::LMU;

# The null set should return zero
my $null_scalar = false {};
my @null_list   = false {};
is($null_scalar, 0, 'false(null) returns undef');
is_deeply(\@null_list, [0], 'false(null) returns undef');

# Normal cases
my @list = (1 .. 10000);
is(10000, false { not defined } @list);
is(0,     false { defined } @list);
is(1,     false { $_ > 1 } @list);

leak_free_ok(
    false => sub {
        my $n  = false { $_ == 5000 } @list;
        my $n2 = false { $_ == 5000 } 1 .. 10000;
    }
);
is_dying('false without sub' => sub { &false(42, 4711); });

done_testing;


