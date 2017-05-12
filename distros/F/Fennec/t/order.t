#!/usr/bin/env perl
package Test::Order;
use strict;
use warnings;

use Fennec parallel => 0, test_sort => 'ordered';

my @seen;

for my $num ( 1 .. 20 ) {
    tests "$num" => sub {
        push @seen => $num;
        is_deeply(
            \@seen,
            [1 .. $num],
            "Ordered through $num",
        );
    };
}

done_testing;
