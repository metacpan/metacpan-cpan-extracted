use strict;
use Test;
BEGIN { plan tests => 6 }

use Dunce::time;

my $t1 = time;
ok($t1, qr/^\d+$/);
ok($t1 + 0 == $t1);
ok($t1 - 0 == $t1);
ok($t1 * 1 == $t1);
ok($t1 / 1 == $t1);

my $t2 = time + 100_000_000;
my @num_compared = sort { $a <=> $b } $t1, $t2;
ok("@num_compared", "$t1 $t2");






	





