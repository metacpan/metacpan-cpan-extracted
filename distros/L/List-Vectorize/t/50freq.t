use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

my $a = ["a", "a", "a", "b", "b", "b", "c", "c"];
my $t = freq($a);

is_deeply($t, {a => 3,
               b => 3,
			   c => 2});

my $b = [1, 1, 2, 2, 1, 1, 2, 2];
$t = freq($a, $b);

is_deeply($t, {'a|1' => 2,
               'a|2' => 1,
			   'b|1' => 2,
			   'b|2' => 1,
			   'c|2' => 2});
