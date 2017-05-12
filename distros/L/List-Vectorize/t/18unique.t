use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

my $x = ["a", "a", "b", "b", "c"];
my $y = unique($x);

is_deeply($y, ["a", "b", "c"]);

$x = ["b", "a", "b", "a", "c"];
$y = unique($x);
is_deeply($y, ["b", "a", "c"]);

