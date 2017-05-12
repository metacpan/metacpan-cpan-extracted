use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('List::Vectorize') }

my $m = [[1,2,3],
         [4,5,6]];
		 
my $t = t($m);
is_deeply($t, [[1, 4],
               [2, 5],
			   [3, 6]]);
