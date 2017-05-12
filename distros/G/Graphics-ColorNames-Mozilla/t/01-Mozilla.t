use Test;

BEGIN { plan tests => 3, todo => [ ] }

use strict;
use Carp;

use Graphics::ColorNames::Mozilla 0.10, qw( NamesRgbTable );
ok(1);

my %table = %{Graphics::ColorNames::Mozilla->NamesRgbTable()};
ok(1);

ok(keys %table, 146);
