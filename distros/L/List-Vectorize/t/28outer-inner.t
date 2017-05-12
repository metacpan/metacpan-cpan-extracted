use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok('List::Vectorize') }

my $x = [1..4];
my $y = [1..4];
my $z = outer($x, $y);

is_deeply($z, [[1, 2, 3, 4],
               [2, 4, 6, 8],
			   [3, 6, 9, 12],
			   [4, 8, 12, 16]]);

$z = inner($x, $y);
is($z, 30);
			   
$z = outer($x, $y, sub {$_[0]**2 + $_[1]});

is_deeply($z, [[2, 3, 4, 5],
               [5, 6, 7, 8],
			   [10, 11, 12, 13],
			   [17, 18, 19, 20]]);

$z = inner($x, $y, sub {$_[0]**2 + $_[1]});
is($z, 40);

$z = inner([2, 2], [-1, 1]);
is($z, 0, 'direct corss');
