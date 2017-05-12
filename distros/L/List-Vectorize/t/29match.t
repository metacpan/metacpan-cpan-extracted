use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('List::Vectorize') }

my $x = ["a", "b", "c", "d"];
my $y = ["b", "c", "d", "e"];

my $m = match($x, $y);

is_deeply($m, [1, 2, 3]);
