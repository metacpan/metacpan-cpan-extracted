use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('List::Vectorize') }

my $x = [2, 5, 1, 3, 4, 7, 10];
my $y = [[2, "a"],
         [5, "g"],
		 [4, "c"],
		 [7, "r"],
		 [10, "e"]];


my $o1 = sort_array($x);
my $o2 = sort_array($x, sub {$_[1] <=> $_[0]});
my $o3 = sort_array($x, sub {$_[0] cmp $_[1]});
my $o4 = sort_array($y, sub { $_[0]->[1] cmp $_[1]->[1] });

is_deeply($o1, [1, 2, 3, 4, 5, 7, 10]);
is_deeply($o2, [10, 7, 5, 4, 3, 2, 1]);
is_deeply($o3, [1, 10, 2, 3, 4, 5, 7]);
is_deeply($o4, [[2, 'a'],
                [4, 'c'],
				[10, 'e'],
				[5, 'g'],
				[7, 'r']]);
