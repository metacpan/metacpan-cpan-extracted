package Arbitrary::Test::Package;

use strict;
use warnings;
use Forks::Super::Tie::Enum;
use Test::More tests => 4;

# unit tests for Forks::Super::Tie::Enum, for scalars that take on a limited
# number of (case-insensitive) values

my $my_favorite_color;
tie $my_favorite_color, 'Forks::Super::Tie::Enum', 
	'red', 'green', 'blue', 'yellow';

ok($my_favorite_color eq "red");

$my_favorite_color = "yellow";
ok($my_favorite_color eq "yellow");

$my_favorite_color = "Green";
ok($my_favorite_color eq "green");

$my_favorite_color = "Modern";
ok($my_favorite_color eq "green");

