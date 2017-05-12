use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok('List::Vectorize') }

my $x = [2, 5, 4, 7, 10];
my $z = [[2, "a"],
         [5, "g"],
		 [4, "c"],
		 [7, "r"],
		 [10, "e"]];

my $o1 = order($x);
my $o2 = order($x, sub {$_[1] <=> $_[0]});
my $o3 = order($x, sub {$_[0] cmp $_[1]});
my $o4 = order($z, sub { $_[0]->[1] cmp $_[1]->[1] });

is_deeply($o1, [0, 2, 1, 3, 4]);
is_deeply($o2, [4, 3, 1, 2, 0]);
is_deeply($o3, [4, 0, 2, 1, 3]);
is_deeply($o4, [0, 2, 4, 1, 3]);

is_deeply(subset(subset($x, order($x)), order(order($x))), $x, "'x[order(x)][order(order(x))]' is 'x' itself (omg!)");
