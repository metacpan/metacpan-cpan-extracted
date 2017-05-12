use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok('List::Vectorize') }

is_deeply(rep(1, 4), [1, 1, 1, 1]) ;
is_deeply(rep([1..4], 4), [[1, 2, 3, 4],
                              [1, 2, 3, 4],
							  [1, 2, 3, 4],
							  [1, 2, 3, 4]]);
is_deeply(rep({a => 1, b => 2}, 3), [{a => 1, b => 2},
                                        {a => 1, b => 2},
										{a => 1, b => 2},]);

my $x1 = rep([1..4], 4);
$x1->[0][0] = 100;
is_deeply($x1, [[100, 2, 3, 4],
                [1, 2, 3, 4],
				[1, 2, 3, 4],
				[1, 2, 3, 4]], 'copy the origin data');
				
$x1 = rep([1..4], 4, 0);
$x1->[0][0] = 100;
is_deeply($x1, [[100, 2, 3, 4],
                [100, 2, 3, 4],
				[100, 2, 3, 4],
				[100, 2, 3, 4]], 'only copy the reference');
				