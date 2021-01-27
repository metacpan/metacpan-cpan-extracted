use strict;
use warnings;

use Graph::Reader::UnicodeTree;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Graph::Reader::UnicodeTree::VERSION, 0.03, 'Version.');
