use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field008;
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field008->new;
my $ret = $obj->struct;
is_deeply(
	$ret,
	{},
	'Get struct without init.',
);

# Test.
$obj = MARC::Validator::Plugin::Field008->new;
$obj->init;
$ret = $obj->struct;
is($ret->{'name'}, 'field_008', 'Get struct - name (field_008).');
is($ret->{'module_name'}, 'MARC::Validator::Plugin::Field008', 'Get struct - name (MARC::Validator::Plugin::Field008).');
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
$obj = MARC::Validator::Plugin::Field008->new(
	'error_id_def' => '015a',
);
$obj->init;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb001920818-incorrect_field_008_syntax_quote_mark.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'cnb001920818' => [{
			'error' => "Parameter 'date1' has bad value.",
			'params' => {
				'Value' => '197?',
			},
		}],
	},
	'Get struct - checks (field 008 is syntactically incorrect - >197?<).',
);

# Test.
$obj = MARC::Validator::Plugin::Field008->new(
	'error_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000295209-incorrect_field_008_syntax_space.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'cnb000295209' => [{
			'error' => "Parameter 'date1' has value with space character.",
			'params' => {
				'Value' => '189 ',
			},
		}],
	},
	'Get struct - checks (field 008 is syntactically incorrect - >189 <).',
);

# Test.
$obj = MARC::Validator::Plugin::Field008->new(
	'error_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb001873805-incorrect_field_008_content-blank.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'cnb001873805' => [{
			'error' => "Field 008 date 1 need to be fill.",
			'params' => {
				'Value' => '080921s        xr ||| g       nn        ',
			},
		}],
	},
	'Get struct - checks (field 008 has blank date 1 - >    <).',
);
