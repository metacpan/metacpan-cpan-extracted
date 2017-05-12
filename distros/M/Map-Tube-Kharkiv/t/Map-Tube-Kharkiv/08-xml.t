# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Kharkiv;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Kharkiv->new;
my $ret = $map->xml;
like($ret, qr{kharkiv-map\.xml$}, 'Get XML file.');
