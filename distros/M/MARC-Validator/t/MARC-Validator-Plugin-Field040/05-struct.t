use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field040;
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field040->new;
my $ret = $obj->struct;
is_deeply(
	$ret,
	{},
	'Get struct without init.',
);

# Test.
$obj = MARC::Validator::Plugin::Field040->new;
$obj->init;
$ret = $obj->struct;
is($ret->{'name'}, 'field_040', 'Get struct - name (field_040).');
is($ret->{'module_name'}, 'MARC::Validator::Plugin::Field040', 'Get struct - name (MARC::Validator::Plugin::Field040).');
ok(exists $ret->{'module_version'}, 'Get struct - module version (exists).');
ok(exists $ret->{'datetime'}, 'Get struct - datetime (exists).');
is_deeply(
	$ret->{'checks'},
	{
		'not_valid' => {},
	},
	'Get struct - checks (before processing).',
);

# Test.
$obj = MARC::Validator::Plugin::Field040->new(
	'error_id_def' => '015a',
);
$obj->init;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb002172297-leader_desc_cataloging_form_coolidate_with_rda.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'cnb002172297' => [{
			'error' => "Leader descriptive cataloging form (a) is inconsistent with field 040e description conventions (rda).",
		}],
	},
	'Get struct - checks (leader 018 is a and field 040e is rda).',
);

# Test.
$obj = MARC::Validator::Plugin::Field040->new(
	'error_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('fake2-incorrect_leader.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'fake2' => [{
			'error' => "Bad number in length.",
			'params' => {
				'String' => 'x1753',
			},
		}],
	},
	'Get struct - checks (leader has bad length number - >x1753<).',
);

# Test.
$obj = MARC::Validator::Plugin::Field040->new(
	'error_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('fake4-missing_field_040.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'fake4' => [{
			'error' => "Field 040 isn't present.",
		}],
	},
	'Get struct - checks (field 040 isn\'t present).',
)
