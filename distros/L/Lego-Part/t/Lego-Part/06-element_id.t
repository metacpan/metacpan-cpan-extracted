use strict;
use warnings;

use Lego::Part;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Lego::Part->new(
	'element_id' => '300221',
);
is($obj->element_id, '300221', 'Get element ID defined by constructor.');

# Test.
is($obj->element_id('123'), '123', 'Get element ID defined by element_id() '.
	'method.');
