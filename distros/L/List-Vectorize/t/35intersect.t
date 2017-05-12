use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('List::Vectorize') }

my $s1 = ["a", "b", "b", "c", "d"];
my $s2 = ["b", "c", "d", "d", "e"];
my $s3 = ["c", "d", "e", "f", "g"];
my $empty_set = [];
my $intersect1 = intersect($s1, $s2);
my $intersect2 = intersect($s1, $s2, $s3);

is_deeply($intersect1, ["b", "c", "d"], 'intersection of two sets');
is_deeply($intersect2, ["c", "d"], 'intersection of three sets');
is_deeply(intersect($s1, $empty_set), []);
is_deeply(intersect($empty_set, $s1, $s2), []);
