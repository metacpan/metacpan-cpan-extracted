#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use List::Util::Uniq qw(
                           uniq_adj
                           uniq_adj_ci
                           uniq_ci
                        );

subtest "uniq_adj" => sub {
    is_deeply([uniq_adj(1, 2, 4, 4, 4, 2, 4)], [1, 2, 4, 2, 4]);
};

subtest "uniq_adj_ci" => sub {
    is_deeply([uniq_adj   (qw/a b B a b C c/)], [qw/a b B a b C c/]);
    is_deeply([uniq_adj_ci(qw/a b B a b C c/)], [qw/a b a b C/]);
};

subtest "uniq_ci" => sub {
    #is_deeply([uniq   (qw/a b B a b C c/)], [qw/a b B C c/]);
    is_deeply([uniq_ci(qw/a b B a b C c/)], [qw/a b C/]);
};

DONE_TESTING:
done_testing;
