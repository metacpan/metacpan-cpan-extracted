# Pragmas.
use strict;
use warnings;

# Modules.
use Graph::Reader::TGF;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Graph::Reader::TGF->new;
isa_ok($obj, 'Graph::Reader::TGF');
