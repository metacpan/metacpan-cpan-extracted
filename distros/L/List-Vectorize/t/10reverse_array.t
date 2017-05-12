use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('List::Vectorize') }

my $x = [2, 5, 1, 3, 4, 7, 10];
my $o = reverse_array($x);

is_deeply($o, [10, 7, 4, 3, 1, 5, 2]);
