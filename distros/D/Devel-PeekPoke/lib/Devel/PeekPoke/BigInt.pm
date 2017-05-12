package # hide from PAUSE
  Devel::PeekPoke::BigInt;

use strict;
use warnings;

use base 'Math::BigInt';

sub as_unmarked_hex { substr ( shift->as_hex, 2 ) }

1;
