#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");


use Test::More;
use Test::LMU;

my @list = (1, 1, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 6, 7, 7, 7, 8, 8, 9, 9, 9, 9, 9, 11, 13, 13, 13, 17);
is_deeply([0,  0],  [equal_range { $_ <=> 0 } @list], "equal range 0");
is_deeply([0,  2],  [equal_range { $_ <=> 1 } @list], "equal range 1");
is_deeply([2,  4],  [equal_range { $_ <=> 2 } @list], "equal range 2");
is_deeply([10, 14], [equal_range { $_ <=> 4 } @list], "equal range 4");
is_deeply([(scalar @list) x 2], [equal_range { $_ <=> 19 } @list], "equal range 19");

my @in = @list = 1 .. 100;
leak_free_ok(
    equal_range => sub {
        my $elem = int(rand(101)) + 1;
        equal_range { $_ - $elem } @list;
    }
);

leak_free_ok(
    'equal_range with stack-growing' => sub {
        my $elem = int(rand(101));
        equal_range { grow_stack(); $_ - $elem } @list;
    }
);

leak_free_ok(
    'equal_range with stack-growing and exception' => sub {
        my $elem = int(rand(101));
        eval {
            equal_range { grow_stack(); $_ - $elem or die "Goal!"; $_ - $elem } @list;
        };
    }
);
is_dying('equal_range without sub' => sub { &equal_range(42, (1 .. 100)); });

done_testing;


