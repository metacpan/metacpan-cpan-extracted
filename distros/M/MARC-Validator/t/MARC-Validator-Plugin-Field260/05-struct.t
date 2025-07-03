use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field260;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field260->new;
my $ret = $obj->struct;
is_deeply(
	$ret,
	{},
	'Get struct without init.',
);

# Test.
$obj = MARC::Validator::Plugin::Field260->new;
$obj->init;
$ret = $obj->struct;
is($ret->{'name'}, 'field_260', 'Get struct - name (field_260).');
is($ret->{'module_name'}, 'MARC::Validator::Plugin::Field260', 'Get struct - name (MARC::Validator::Plugin::Field260).');
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
$obj = MARC::Validator::Plugin::Field260->new;
$obj->init;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb001880327-incorrect_260c.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->struct;
is_deeply(
	$ret->{'checks'}->{'not_valid'},
	{
		'cnb001880327' => [{
			'error' => 'Bad year in parenthesis in MARC field 260 $c.',
			'params' => {
				'Value' => '(1861)',
			},
		}],
	},
	'Get struct - checks (field 260 $c has year in parenthesis).',
);
