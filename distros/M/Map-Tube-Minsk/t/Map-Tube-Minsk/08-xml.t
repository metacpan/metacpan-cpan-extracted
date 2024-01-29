use strict;
use warnings;

use Map::Tube::Minsk;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Minsk->new;
my $ret = $map->xml;
like($ret, qr{minsk-map\.xml$}, 'Get XML file.');
