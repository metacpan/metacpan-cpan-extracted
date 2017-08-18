#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");


use Test::More;
use Test::LMU;

# Normal cases
my @list = (1 .. 10000);
is_true(all_u  { defined } @list);
is_true(all_u  { $_ > 0 } @list);
is_false(all_u { $_ < 5000 } @list);
is_undef(all_u {});

leak_free_ok(
    all_u => sub {
        my $ok  = all_u { $_ == 5000 } @list;
        my $ok2 = all_u { $_ == 5000 } 1 .. 10000;
    }
);
is_dying('all_u without sub' => sub { &all_u(42, 4711); });

done_testing;


