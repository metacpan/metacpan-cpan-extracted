use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok('List::Vectorize') }

my $x = [5, 6, 8, 2, 10];
my $y = [[2, "a"],
         [5, "g"],
		 [4, "c"],
		 [7, "r"],
		 [10, "e"]];

my $o1 = rank($x);
my $o2 = rank($x, sub {$_[1] <=> $_[0]});
my $o3 = rank($x, sub {$_[0] cmp $_[1]});
my $o4 = rank($y, sub { $_[0]->[1] cmp $_[1]->[1] });

is_deeply($o1, [2, 3, 4, 1, 5]);
is_deeply($o2, [4, 3, 2, 5, 1]);
is_deeply($o3, [3, 4, 5, 2, 1]);
is_deeply($o4, [1, 4, 2, 5, 3]);

my $z = [1, 2, 2, 3, 3, 4];
my $o5 = rank($z);
is_deeply($o5, [1, 2.5, 2.5, 4.5, 4.5, 6]);
