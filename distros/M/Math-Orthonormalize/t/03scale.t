use strict;
use warnings;

use Test::More tests => 5;

use_ok('Math::Orthonormalize', ':all');
use Math::Symbolic qw/:all/;

is_deeply(scale(1, [1]), [1]);
is_deeply(scale(2, [0,1,2]), [0,2,4]);
is_deeply(scale(-1, [-1,0,1,2]), [1,0,-1,-2]);

my $vec = [map {parse_from_string($_)} qw(x y z)];
my $res = [map {2*parse_from_string($_)} qw(x y z)];
ok(
	not grep {not $_->is_identical(shift @{$res})} @{scale(2, $vec)}
);

