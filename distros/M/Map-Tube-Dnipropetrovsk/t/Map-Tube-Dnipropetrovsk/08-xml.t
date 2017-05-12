# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Dnipropetrovsk;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Dnipropetrovsk->new;
my $ret = $map->xml;
like($ret, qr{dnipropetrovsk-map\.xml$}, 'Get XML file.');
