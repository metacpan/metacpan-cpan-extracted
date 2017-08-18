#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");


use Test::More;
use Test::LMU;

# Normal cases
my @list = (1 .. 300);
is_true(one_u  { 1 == $_ } @list);
is_true(one_u  { 150 == $_ } @list);
is_true(one_u  { 300 == $_ } @list);
is_false(one_u { 0 == $_ } @list);
is_false(one_u { 1 <= $_ } @list);
is_false(one_u { !(127 & $_) } @list);
is_undef(one_u {});

leak_free_ok(
    one_u => sub {
        my $ok  = one_u { 150 <= $_ } @list;
        my $ok2 = one_u { 150 <= $_ } 1 .. 300;
    }
);
is_dying('one_u without sub' => sub { &one_u(42, 4711); });

done_testing;


