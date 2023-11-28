use strict;
use warnings;

use Lego::Part;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Lego::Part->new(
	'design_id' => '3002',
);
is($obj->design_id, '3002', 'Get design ID defined by constructor.');

# Test.
is($obj->design_id('3000'), '3000', 'Get design ID defined by design_id() '.
	'method.');
