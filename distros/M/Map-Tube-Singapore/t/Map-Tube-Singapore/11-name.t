use strict;
use warnings;

use Map::Tube::Singapore;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Singapore->new;
my $ret = $metro->name;
is($ret, 'Mass Rapid Transit', 'Get metro name.');
