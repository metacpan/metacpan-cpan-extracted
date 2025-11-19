use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field035;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field035->new;
my $ret = $obj->struct;
is_deeply(
	$ret,
	{},
	'Get struct without init.',
);

# Test.
$obj = MARC::Validator::Plugin::Field035->new;
$obj->init;
$ret = $obj->struct;
is($ret->{'name'}, 'field_035', 'Get struct - name (field_035).');
is($ret->{'module_name'}, 'MARC::Validator::Plugin::Field035', 'Get struct - name (MARC::Validator::Plugin::Field035).');
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
$obj = MARC::Validator::Plugin::Field035->new(
	'error_id_def' => '015a',
);
$obj->init;
my $marc = MARC::File::XML->in($data_dir->file('cnb000545093-cnb001214971-duplicite_035a.xml')->s);
$obj->process($marc->next);
$obj->process($marc->next);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'cnb001214971' => [{
			'error' => 'Bad system control number in 035a field.',
			'params' => {
				'duplicate_to' => 'cnb000545093',
				'value' => '(OCoLC)51768478',
			},
		}],
	},
	'Get struct - checks (field 035 $a is duplicite to another record).',
);
