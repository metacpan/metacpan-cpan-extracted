# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Budapest;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Budapest->new;
my $ret = $map->xml;
like($ret, qr{budapest-map\.xml$}, 'Get XML file.');
