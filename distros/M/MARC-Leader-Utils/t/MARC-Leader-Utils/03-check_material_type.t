use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Leader::Utils qw(check_material_type);
use Readonly;
use Test::More 'tests' => 9;
use Test::NoWarnings;

Readonly::Array our @BAD_MATERIAL_TYPES => (
	'foo',
);
Readonly::Array our @RIGHT_MATERIAL_TYPES => qw(book computer_file continuing_resource map
	mixed_material music visual_material);

# Test.
my $ret;
foreach my $material_type (@RIGHT_MATERIAL_TYPES) {
	$ret = check_material_type($material_type);
	is($ret, 1, 'Check right material type ('.$material_type.')');
}

# Test.
foreach my $material_type (@BAD_MATERIAL_TYPES) {
	$ret = check_material_type($material_type);
	is($ret, 0, 'Check bad material type ('.$material_type.')');
}
