use strict;
use warnings;

use Map::Tube::Singapore;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Singapore->new;
my $ret = $map->xml;
like($ret, qr{singapore-map\.xml$}, 'Get XML file.');
