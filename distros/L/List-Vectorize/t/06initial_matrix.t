use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

my $a = initial_matrix(4, 4);
my $b = initial_matrix(4, 4, 1);
my $c = initial_matrix(4, 4, sub {2});

is_deeply($a, [[undef, undef, undef, undef],
               [undef, undef, undef, undef],
			   [undef, undef, undef, undef],
			   [undef, undef, undef, undef]]);
is_deeply($b, [[1, 1, 1, 1],
               [1, 1, 1, 1],
			   [1, 1, 1, 1],
			   [1, 1, 1, 1]]);
is_deeply($c, [[2, 2, 2, 2],
               [2, 2, 2, 2],
			   [2, 2, 2, 2],
			   [2, 2, 2, 2]]);
			   