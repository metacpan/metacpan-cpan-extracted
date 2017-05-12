use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

my $s1 = seq(1, 10);
my $s2 = seq(1, 10, 2);
my $s3 = seq(5, -5, 3);

is_deeply($s1, [1..10]);
is_deeply($s2, [1, 3, 5, 7, 9]);
is_deeply($s3, [5, 2, -1, -4]);
