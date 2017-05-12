use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;

use_ok('Math::Fraction::Egyptian');

local *s_composite = \&Math::Fraction::Egyptian::s_composite;

throws_ok { s_composite(2,11) } qr/unsuitable strategy/;

is_deeply([s_composite(2,21)],[0,1,14,42]);

