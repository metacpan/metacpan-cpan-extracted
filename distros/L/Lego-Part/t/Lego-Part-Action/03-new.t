use strict;
use warnings;

use Lego::Part::Action;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Lego::Part::Action->new;
isa_ok($obj, 'Lego::Part::Action');
