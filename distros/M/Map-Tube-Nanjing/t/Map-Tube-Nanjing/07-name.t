# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use Map::Tube::Nanjing;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Nanjing->new;
my $ret = $metro->name;
is($ret, decode_utf8('南京地铁'), 'Get metro name.');
