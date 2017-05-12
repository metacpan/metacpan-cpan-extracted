use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

my $a1 = [1, 2, 3];
my $a2 = [1, 2, 3];

my $is = is_array_identical($a1, $a2) + 0;
is($is, 1);

del_array_item($a2, 1);
$is = is_array_identical($a1, $a2) + 0;
is($is , 0);
