#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use List::Permute::Limit qw(permute permute_iter);

sub _permute_iter_as_array {
    my @rows;
    my $iter = permute_iter(@_);
    while (my $row = $iter->()) { push @rows, $row }
    \@rows;
}

is_deeply([permute(items=>[0..3], nitems=>2)],
          [
              [0,0], [0,1], [0,2], [0,3],
              [1,0], [1,1], [1,2], [1,3],
              [2,0], [2,1], [2,2], [2,3],
              [3,0], [3,1], [3,2], [3,3],
          ]);
is_deeply(_permute_iter_as_array(items=>[0..3], nitems=>2),
          [
              [0,0], [0,1], [0,2], [0,3],
              [1,0], [1,1], [1,2], [1,3],
              [2,0], [2,1], [2,2], [2,3],
              [3,0], [3,1], [3,2], [3,3],
          ]);

done_testing;
