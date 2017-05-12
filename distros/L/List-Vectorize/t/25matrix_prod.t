use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('List::Vectorize') }

my $m = [[1,2],[3,4]];
my $m2 = matrix_prod($m, $m);

is_deeply($m2, [[7, 10],
                [15, 22]]);

my $m3 = matrix_prod($m, $m, $m);

is_deeply($m3, [[37, 54],
                [81, 118]]);

my $x = [[1, 2, 3],
         [4, 5, 6]];
my $y = [[1, 2],
         [3, 4],
		 [5, 6]];

is_deeply(matrix_prod($x, $y), [[22, 28],
                                [49, 64]]);
is_deeply(matrix_prod($y, $x), [[9, 12, 15],
                                [19, 26, 33],
								[29, 40, 51]]);
																