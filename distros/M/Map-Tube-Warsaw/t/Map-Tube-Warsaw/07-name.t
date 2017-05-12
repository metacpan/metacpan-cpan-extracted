# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use Map::Tube::Warsaw;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Warsaw->new;
my $ret = $metro->name;
is($ret, decode_utf8('Metro w Warszawie'), 'Get metro name.');
