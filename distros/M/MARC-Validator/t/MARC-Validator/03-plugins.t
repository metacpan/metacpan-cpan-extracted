use strict;
use warnings;

use MARC::Validator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my @ret = MARC::Validator->plugins;
ok((scalar @ret) >= 3, 'Get count of plugins (>=3).');
