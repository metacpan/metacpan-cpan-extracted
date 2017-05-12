use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

my $s1 = ["a", "a", "b", "c", "d"];
my $s2 = ["b", "c", "e", "d", "e"];
my $s3 = ["c", "e", "g", "c", "e"];
my $u1 = union($s1, $s2);
my $u2 = union($s1, $s2, $s3);

is_deeply($u1, ["a", "b", "c", "d", "e"]);
is_deeply($u2, ["a", "b", "c", "d", "e", "g"]);
