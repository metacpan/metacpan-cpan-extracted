# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use Map::Tube::Kharkiv;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Kharkiv->new;
my $ret = $metro->name;
is($ret, decode_utf8('Харківський метрополітен'), 'Get metro name.');
