use strict;
use warnings;
use Test::More tests => 3;
use Test::Fatal;

use EntityModel::Field;

new_ok('EntityModel::Field' => [], 'instantiate with no args');
my $field = new_ok('EntityModel::Field' => [
	name => 'test'
], 'instantiate with %args');
is($field->name, 'test', 'name is correct');
done_testing;

