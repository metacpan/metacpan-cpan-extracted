use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field020;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field020->new;
my $ret = $obj->struct;
is_deeply(
	$ret,
	{},
	'Get struct without init.',
);

# Test.
$obj = MARC::Validator::Plugin::Field020->new;
$obj->init;
$ret = $obj->struct;
is($ret->{'name'}, 'field_020', 'Get struct - name (field_020).');
is($ret->{'module_name'}, 'MARC::Validator::Plugin::Field020', 'Get struct - name (MARC::Validator::Plugin::Field020).');
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
$obj = MARC::Validator::Plugin::Field020->new(
	'error_id_def' => '015a',
);
$obj->init;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb003260113-incorrect_field_020a_isbn_bad.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'cnb003260113' => [{
			'error' => "Bad ISBN in 020a field after fixing of checksum.",
			'params' => {
				'Value' => '979-0-706574-00-4',
			},
		}],
	},
	'Get struct - checks (field 020a ISBN is bad - >979-0-706574-00-4<).',
);

# Test.
$obj = MARC::Validator::Plugin::Field020->new(
	'error_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb003698545-incorrect_field_020a_isbn_formatting.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'cnb003698545' => [{
			'error' => "Bad ISBN in 020a field, bad formatting.",
			'params' => {
				'Value' => '80-900-2311-8',
			},
		}],
	},
	'Get struct - checks (field 020a ISBN has bad fornmatting - >80-900-2311-8<).',
);

# Test.
$obj = MARC::Validator::Plugin::Field020->new(
	'error_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb001410157-incorrect_field_020a_isbn_with_extra_characters.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'cnb001410157' => [{
			'error' => "Bad ISBN in 020a field, extra characters.",
			'params' => {
				'Value' => '80-902905-0-7 :',
			},
		}],
	},
	'Get struct - checks (field 008 ISBN has extra characters - >80-902905-0-7 :<).',
);

# Test.
$obj = MARC::Validator::Plugin::Field020->new(
	'error_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('fake1-incorrect_field_020a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'fake1' => [{
			'error' => "Bad ISBN in 020a field.",
			'params' => {
				'Value' => 'bad',
			},
		}],
	},
	'Get struct - checks (field 008 ISBN is bad - >bad<).',
);

# Test.
$obj = MARC::Validator::Plugin::Field020->new;
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000000168-correct_field_020a_isbn_not_present.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{},
	'Get struct - checks (no issue with field 008).',
);
