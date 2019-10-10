use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Father::Son::HolySpirit') };

is(amen, 1, "Amen brother");
