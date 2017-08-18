#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");


use Test::More;
use Test::LMU;

my @list = (1, 1, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 6, 7, 7, 7, 8, 8, 9, 9, 9, 9, 9, 11, 13, 13, 13, 17);
is(0,  (upper_bound { $_ <=> 0 } @list), "upper bound 0");
is(2,  (upper_bound { $_ <=> 1 } @list), "upper bound 1");
is(4,  (upper_bound { $_ <=> 2 } @list), "upper bound 2");
is(14, (upper_bound { $_ <=> 4 } @list), "upper bound 4");
is(scalar @list, (upper_bound { $_ <=> 19 } @list), "upper bound 19");

my @in = @list = 1 .. 100;
for my $i (0 .. $#in)
{
    my $j = $in[$i] - 1;
    is($i, (upper_bound { $_ - $j } @list), "placed $j");
    is($i + 1, (upper_bound { $_ - $in[$i] } @list), "found $in[$i]");
}
my @lout = ($in[0] - 11 .. $in[0] - 1);
for my $elem (@lout)
{
    is(0, (upper_bound { $_ - $elem } @list), "put smaller $elem in front");
}
my @uout = ($in[-1] + 1 .. $in[-1] + 11);
for my $elem (@uout)
{
    is(scalar @list, (upper_bound { $_ - $elem } @list),, "put bigger $elem at end");
}

leak_free_ok(
    upper_bound => sub {
        my $elem = int(rand(1000)) + 1;
        upper_bound { $_ - $elem } @list;
    }
);

leak_free_ok(
    'upper_bound with stack-growing' => sub {
        my $elem = int(rand(1000));
        upper_bound { grow_stack(); $_ - $elem } @list;
    }
);

leak_free_ok(
    'upper_bound with stack-growing and exception' => sub {
        my $elem = int(rand(1000));
        eval {
            upper_bound { grow_stack(); $_ - $elem or die "Goal!"; $_ - $elem } @list;
        };
    }
);
is_dying('upper_bound without sub' => sub { &upper_bound(42, (1 .. 100)); });

done_testing;


