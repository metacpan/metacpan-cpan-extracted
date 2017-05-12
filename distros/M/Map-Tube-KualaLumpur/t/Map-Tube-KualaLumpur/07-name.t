# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::KualaLumpur;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::KualaLumpur->new;
my $ret = $metro->name;
is($ret, 'Rapid Rail', 'Get metro name.');
