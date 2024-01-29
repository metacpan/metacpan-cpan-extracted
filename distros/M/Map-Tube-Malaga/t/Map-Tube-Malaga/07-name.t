use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Malaga;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Malaga->new;
my $ret = $metro->name;
is($ret, decode_utf8('Metro de Málaga'), 'Get metro name.');
