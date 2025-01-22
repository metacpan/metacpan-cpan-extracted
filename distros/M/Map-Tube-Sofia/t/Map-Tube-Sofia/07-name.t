use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Sofia;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Sofia->new;
my $ret = $metro->name;
is($ret, decode_utf8('Софийско метро'), 'Get metro name.');
