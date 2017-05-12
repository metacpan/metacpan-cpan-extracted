use strict;
use Test::More tests => 6;

BEGIN { use_ok('List::Vectorize') }

my $a = initial_array(5);
my $b = initial_array(5, 1);
my $c = initial_array(5, sub {2});
my $d = initial_array(5, [1, 2]);

is_deeply($a, [undef, undef, undef, undef, undef], 'by default');
is_deeply($b, [1, 1, 1, 1, 1], 'with specified values');
is_deeply($c, [2, 2, 2, 2, 2], 'from function');
is_deeply($d, [[1, 2], [1, 2], [1, 2], [1, 2], [1, 2]], 'from array');
$d->[0]->[0] = 100;
is_deeply($d, [[100, 2], [1, 2], [1, 2], [1, 2], [1, 2]], 'arrays are not initialized from reference, but copy the whole value');
