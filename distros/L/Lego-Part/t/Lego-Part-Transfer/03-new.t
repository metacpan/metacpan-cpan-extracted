use strict;
use warnings;

use Lego::Part::Transfer;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Lego::Part::Transfer->new;
isa_ok($obj, 'Lego::Part::Transfer');
