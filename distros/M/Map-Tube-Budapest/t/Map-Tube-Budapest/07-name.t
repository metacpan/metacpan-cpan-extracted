# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use Map::Tube::Budapest;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Budapest->new;
my $ret = $metro->name;
is($ret, decode_utf8('Budapesti metró'), 'Get metro name.');
