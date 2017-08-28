#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");


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


