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
is(0,  (lower_bound { $_ <=> 0 } @list), "lower bound 0");
is(0,  (lower_bound { $_ <=> 1 } @list), "lower bound 1");
is(2,  (lower_bound { $_ <=> 2 } @list), "lower bound 2");
is(10, (lower_bound { $_ <=> 4 } @list), "lower bound 4");
is(scalar @list, (lower_bound { $_ <=> 19 } @list), "lower bound 19");

my @in = @list = 1 .. 100;
for my $i (0 .. $#in)
{
    my $j = $in[$i] - 1;
    is($i ? $i - 1 : 0, (lower_bound { $_ - $j } @list), "placed $j");
    is($i, (lower_bound { $_ - $in[$i] } @list), "found $in[$i]");
}
my @lout = ($in[0] - 11 .. $in[0] - 1);
for my $elem (@lout)
{
    is(0, (lower_bound { $_ - $elem } @list), "put smaller $elem in front");
}
my @uout = ($in[-1] + 1 .. $in[-1] + 11);
for my $elem (@uout)
{
    is(scalar @list, (lower_bound { $_ - $elem } @list),, "put bigger $elem at end");
}

leak_free_ok(
    lower_bound => sub {
        my $elem = int(rand(1000)) + 1;
        lower_bound { $_ - $elem } @list;
    }
);

leak_free_ok(
    'lower_bound with stack-growing' => sub {
        my $elem = int(rand(1000));
        lower_bound { grow_stack(); $_ - $elem } @list;
    }
);

leak_free_ok(
    'lower_bound with stack-growing and exception' => sub {
        my $elem = int(rand(1000));
        eval {
            lower_bound { grow_stack(); $_ - $elem or die "Goal!"; $_ - $elem } @list;
        };
    }
);
is_dying('lower_bound without sub' => sub { &lower_bound(42, (1 .. 100)); });

done_testing;


