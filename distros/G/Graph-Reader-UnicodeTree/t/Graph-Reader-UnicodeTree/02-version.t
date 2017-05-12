# Pragmas.
use strict;
use warnings;

# Modules.
use Graph::Reader::UnicodeTree;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Graph::Reader::UnicodeTree::VERSION, 0.02, 'Version.');
