# Pragmas.
use strict;
use warnings;

# Modules.
use Graph::Reader::TGF;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Graph::Reader::TGF::VERSION, 0.03, 'Version.');
