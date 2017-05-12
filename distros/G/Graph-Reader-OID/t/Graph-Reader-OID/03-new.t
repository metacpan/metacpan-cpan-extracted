# Pragmas.
use strict;
use warnings;

# Modules.
use Graph::Reader::OID;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Graph::Reader::OID->new;
isa_ok($obj, 'Graph::Reader::OID');
