use strict;
use warnings;

use List::Zip;
use Test::More;

my @sizes = (2, 5, 10, 50, 100, 500);

subtest 'zips arrays of even size' => sub {
    for my $size (@sizes) {
        # Zip lists that contain the same values so that we end up
        # with a simple test structure.
        #   [ 0 .. 10 ], [ 0 .. 10 ], [ 0 .. 10 ]
        #   [ 0, 0, 0 ], [ 1, 1, 1 ], [ 2, 2, 2 ] etc
        for my $zipped (List::Zip->zip(map { [ 0 .. 10 ] } 1 .. $size)) {
            is $zipped->[0], $zipped->[$_] for 1 .. $#{ $zipped };
        }
    }
};

subtest 'zips arrays of uneven size' => sub {
    for my $size (@sizes) {
        # Create lists with different sizes. Minimum size set to
        # ten. These lists will be truncated to the same size and
        # should therefore be identical when zipped.
        my @zipped = List::Zip->zip(map { [ 0 .. (10 + rand 50) ] } 1 .. $size);

        for (1 .. $#zipped) {
            is scalar @{ $zipped[0] }, scalar @{ $zipped[$_] };
        }
        for my $zipped (@zipped) {
            is $zipped->[0], $zipped->[$_] for 1 .. $#{ $zipped };
        }
    }
};

done_testing;
