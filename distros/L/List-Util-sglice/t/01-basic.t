#!perl

use strict;
use warnings;
use Test::More 0.98;

use List::Util::sglice qw(
                           sglice
                        );

subtest "param: num_to_remove" => sub {
    my @ary;

    @ary = (1..10);
    is_deeply([sglice {$_%2==0} @ary, 2], [2,4]);
    is_deeply(\@ary, [1,3,5,6,7,8,9,10]);

    @ary = (1..10);
    is_deeply([sglice {$_%2==0} @ary, -2], [8,10]);
    is_deeply(\@ary, [1,2,3,4,5,6,7,9]);
};

subtest "code params" => sub {
    my @ary;

    @ary = (1..10);
    is_deeply([sglice {$_[0]<=4} @ary], [1..4]);
    is_deeply(\@ary, [5,6,7,8,9,10]);

    @ary = (1..10);
    is_deeply([sglice {$_[1]<=4} @ary], [1..5]);
    is_deeply(\@ary, [6,7,8,9,10]);
};

subtest "return values" => sub {
    my @ary;

    @ary = (1..10); is_deeply([sglice {$_%2==0} @ary], [2,4,6,8,10]);
    @ary = (1..10); is_deeply(scalar(sglice {$_%2==0} @ary), 10);
};

DONE_TESTING:
done_testing;
