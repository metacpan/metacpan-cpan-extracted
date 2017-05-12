use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

my $x = [1..10];

del_array_item($x, 2);
is_deeply($x, [1, 2, 4, 5, 6, 7, 8, 9, 10]);

del_array_item($x, [0, 1]);
is_deeply($x, [4, 5, 6, 7, 8, 9, 10]);

del_array_item($x, [0, 1, 20]);
is_deeply($x, [6, 7, 8, 9, 10]);
