use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('Geo::Coder::Ja', ':all');
}

can_ok('Geo::Coder::Ja', 'load');
can_ok('Geo::Coder::Ja', 'set_encoding');
can_ok('Geo::Coder::Ja', 'geocode_location');
can_ok('Geo::Coder::Ja', 'geocode_postcode');
