use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok('List::Vectorize') }

my $a = ["a", "b", "c", "d"];
my $b = [1, 2, 3, 4];

my $p1 = paste($a, $b);
my $p2 = paste($a, 1, "");
my $p3 = paste($a, $b, "-");
my $p4 = paste($a, $b, $a);
my $p5 = paste($a, $b, $a, 3, "");

is_deeply($p1, ["a|1", "b|2", "c|3", "d|4"], 'paste two vectors');
is_deeply($p2, ["a1", "b1", "c1", "d1"], 'paste vector and scalar');
is_deeply($p3, ["a-1", "b-2", "c-3", "d-4"], 'paste with seperator');
is_deeply($p4, ["a|1|a", "b|2|b", "c|3|c", "d|4|d"], 'paste three vectors');
is_deeply($p5, ["a1a3", "b2b3", "c3c3", "d4d3"], 'paste three vectors and one scalar, with seperator');
