
use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok('Math::Goedel'); }

is(Math::Goedel::enc(9), 512);
is(Math::Goedel::enc(81), 768);
is(Math::Goedel::enc(230), 108);

is(Math::Goedel::enc(q/9/), 512);
is(Math::Goedel::enc(q/81/), 768);
is(Math::Goedel::enc(q/230/), 108);

