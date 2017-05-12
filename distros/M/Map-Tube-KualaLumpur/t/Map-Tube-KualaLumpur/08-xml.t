# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::KualaLumpur;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::KualaLumpur->new;
my $ret = $map->xml;
like($ret, qr{kuala_lumpur-map\.xml$}, 'Get XML file.');
