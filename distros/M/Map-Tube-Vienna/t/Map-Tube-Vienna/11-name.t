# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use Map::Tube::Vienna;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Vienna->new;
my $ret = $metro->name;
is($ret, decode_utf8('U-Bahn Wien'), 'Get metro name.');
