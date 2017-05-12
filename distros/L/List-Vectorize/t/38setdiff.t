use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('List::Vectorize') }

my $s1 = ["a", "b", "c", "d", "f"];
my $s2 = ["b", "c", "d", "e"];
my $s = setdiff($s1, $s2);

is_deeply($s, ["a", "f"]);
