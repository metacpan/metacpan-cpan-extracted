# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::SaintPetersburg;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::SaintPetersburg->new;
my $ret = $map->xml;
like($ret, qr{saint_petersburg-map\.xml$}, 'Get XML file.');
