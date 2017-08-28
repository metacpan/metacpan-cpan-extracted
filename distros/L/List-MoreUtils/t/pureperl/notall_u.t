#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");


use Test::More;
use Test::LMU;

# Normal cases
my @list = (1 .. 10000);
is_true(notall_u  { !defined } @list);
is_true(notall_u  { $_ < 10000 } @list);
is_false(notall_u { $_ <= 10000 } @list);
is_undef(notall_u {});

leak_free_ok(
    notall_u => sub {
        my $ok  = notall_u { $_ == 5000 } @list;
        my $ok2 = notall_u { $_ == 5000 } 1 .. 10000;
    }
);
is_dying('notall_u without sub' => sub { &notall_u(42, 4711); });

done_testing;


