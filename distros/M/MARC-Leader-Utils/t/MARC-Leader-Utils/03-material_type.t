use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Leader;
use MARC::Leader::Utils qw(material_type);
use Test::MockObject;
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Test.
my $leader_string = '     nam a22        4500';
my $leader = MARC::Leader->new->parse($leader_string);
my $ret = material_type($leader);
is($ret, 'book', 'Get material type (book).');

# Test.
$leader_string = '     nkm a22      a 4500';
$leader = MARC::Leader->new->parse($leader_string);
$ret = material_type($leader);
is($ret, 'visual_material', 'Get material type (visual_material).');

# Test.
$leader_string = '     ncm a22      i 4500';
$leader = MARC::Leader->new->parse($leader_string);
$ret = material_type($leader);
is($ret, 'music', 'Get material type (music).');

# Test.
$leader_string = '     nmm a22      a 4500';
$leader = MARC::Leader->new->parse($leader_string);
$ret = material_type($leader);
is($ret, 'computer_file', 'Get material type (computer_file).');

# Test.
$leader_string = '     nas a22        4500';
$leader = MARC::Leader->new->parse($leader_string);
$ret = material_type($leader);
is($ret, 'continuing_resource', 'Get material type (continuing_resource).');

# Test.
$leader_string = '     nem a22     2  4500';
$leader = MARC::Leader->new->parse($leader_string);
$ret = material_type($leader);
is($ret, 'map', 'Get material type (map).');

# Test.
eval {
	material_type();
};
is($EVAL_ERROR, "Leader object must be a Data::MARC::Leader instance.\n",
	"Leader object must be a Data::MARC::Leader instance (undef).");
clean();

# Test.
eval {
	material_type('bad');
};
is($EVAL_ERROR, "Leader object must be a Data::MARC::Leader instance.\n",
	"Leader object must be a Data::MARC::Leader instance (string).");
clean();

# Test.
my $mock = Test::MockObject->new;
eval {
	material_type($mock);
};
is($EVAL_ERROR, "Leader object must be a Data::MARC::Leader instance.\n",
	"Leader object must be a Data::MARC::Leader instance (bad object).");
clean();
