use strict;
use warnings;

use Data::MARC::Leader;
use English;
use Error::Pure::Utils qw(clean);
use MARC::Leader;
use Test::MockObject;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = MARC::Leader->new;
my $data = Data::MARC::Leader->new(
	'bibliographic_level' => 'm',
	'char_coding_scheme' => 'a',
	'data_base_addr' => 541,
	'descriptive_cataloging_form' => 'i',
	'encoding_level' => ' ',
	'impl_def_portion_len' => '0',
	'indicator_count' => '2',
	'length' => 2200,
	'length_of_field_portion_len' => '4',
	'multipart_resource_record_level' => ' ',
	'starting_char_pos_portion_len' => '5',
	'status' => 'c',
	'subfield_code_count' => '2',
	'type' => 'e',
	'type_of_control' => ' ',
	'undefined' => '0',
);
my $ret = $obj->serialize($data);
is($ret, '02200cem a2200541 i 4500', 'Serialize leader object.');

# Test.
$obj = MARC::Leader->new;
eval {
	$obj->serialize('bad');
};
is($EVAL_ERROR, "Bad 'Data::MARC::Leader' instance to serialize.\n",
	"Bad 'Data::MARC::Leader' instance to serialize (string).");
clean();

# Test.
$obj = MARC::Leader->new;
eval {
	$obj->serialize(Test::MockObject->new);
};
is($EVAL_ERROR, "Bad 'Data::MARC::Leader' instance to serialize.\n",
	"Bad 'Data::MARC::Leader' instance to serialize (bad object).");
clean();
