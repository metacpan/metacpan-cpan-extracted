use strict;
use warnings;

use Math::Float32 qw(:all);

use Test::More;

cmp_ok($Math::Float32::VERSION, '==', '0.02', "We have Math-Float32-0.02");

if($Math::Float32::broken_signed_zero) {
  warn "\n This system does not correctly support negative zero.\n";
}


done_testing();
