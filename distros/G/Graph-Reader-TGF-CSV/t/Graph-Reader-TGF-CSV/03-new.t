use strict;
use warnings;

use Graph::Reader::TGF::CSV;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Graph::Reader::TGF::CSV->new;
isa_ok($obj, 'Graph::Reader::TGF::CSV');
