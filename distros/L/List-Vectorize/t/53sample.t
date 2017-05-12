use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('List::Vectorize') }

my $x = [1..10];
ok(sample($x, 5)); 
ok(sample($x, 10, "replace" => 0));
ok(sample($x, 10, "replace" => 1));
ok(sample([0, 1], 10, "p" => [1, 9], "replace" => 1));
