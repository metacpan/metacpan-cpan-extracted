use strict;
use warnings;

use Map::Tube::Kiev;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Kiev->new;
my $ret = $map->xml;
like($ret, qr{kiev-map\.xml$}, 'Get XML file.');
