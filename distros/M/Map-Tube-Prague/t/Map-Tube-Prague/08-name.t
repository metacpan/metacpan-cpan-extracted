use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Prague;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Prague->new;
my $ret = $metro->name;
is($ret, decode_utf8('Pražské metro'), 'Get metro name.');
