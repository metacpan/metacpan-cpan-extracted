# Pragmas.
use strict;
use warnings;

# Modules.
use Lego::Part;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Lego::Part->new(
	'color' => 'red',
	'element_id' => '300221',
);
is($obj->color, 'red', 'Get color defined by constructor.');

# Test.
is($obj->color('green'), 'green', 'Get color defined by color() method.');
