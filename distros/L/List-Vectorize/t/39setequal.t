use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

my $s1 = ["a", "b", "c", "d"];
my $s2 = ["b", "c", "d", "e"];
my $e = setequal($s1, $s2);

is($e, 0);

$s1 = ["b", "c", "d"];
$s2 = ["b", "c", "d"];
$e = setequal($s1, $s2);

is($e, 1);

$s1 = ["b", "c", "d", "g"];
$s2 = ["b", "c", "d"];
$e = setequal($s1, $s2);

is($e, 0);
