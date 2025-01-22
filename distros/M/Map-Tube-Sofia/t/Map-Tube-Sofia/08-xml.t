use strict;
use warnings;

use Map::Tube::Sofia;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Sofia->new;
my $ret = $map->xml;
like($ret, qr{sofia-map\.xml$}, 'Get XML file.');
