use strict;
use warnings;

use File::Find::Rule::DjVu;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($File::Find::Rule::DjVu::VERSION, 0.01, 'Version.');
