use strict;
use Test::More tests => 3;

BEGIN {
	use_ok('List::Vectorize');
}

my $x = [1..10];
my $t1 = ["a", "a", "a", "a", "a", "b", "b", "b", "b", "b"];
my $t2 = [1,   0,   1,   0,   1,   0,   1,   0,   1,   0];
my $t3 = [1, 0];

my $a = tapply($x, $t1, sub {max(\@_)});
my $b = tapply($x, $t1, $t2, sub{sum(\@_)});


is_deeply($a, {'a' => 5,
               'b' => 10}, 'one category');
is_deeply($b, {'a|1' => 9,
               'a|0' => 6,
			   'b|1' => 16,
			   'b|0' => 24}, 'two categories');

