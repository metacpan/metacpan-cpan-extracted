# Pragmas.
use strict;
use warnings;

# Modules.
use Graph::Reader::UnicodeTree;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Graph::Reader::UnicodeTree->new;
isa_ok($obj, 'Graph::Reader::UnicodeTree');
