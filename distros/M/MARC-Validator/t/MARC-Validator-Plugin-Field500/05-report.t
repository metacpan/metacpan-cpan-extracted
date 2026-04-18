use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field500;
use Test::More 'tests' => 35;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field500->new;
my $ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field500->new;
$obj->init;
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field500->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc = MARC::File::XML->in($data_dir->file('cnb003160105-bad_book_material_index-500a.xml')->s);
$obj->process($marc->next);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_500', 'Get name (field_500).');
my $errors = $ret->plugin_errors;
is(@{$errors}, 1, 'Get errors count (1).');
is($errors->[0]->record_id, 'cnb003160105', 'Get record id (cnb003160105).');
is($errors->[0]->errors->[0]->error, "Missing index in field 008.",
	"Get error (Missing index in field 008.).");
is($errors->[0]->errors->[0]->params->{'field_008_index'}, '0',
	'Get error parameter (field_008_index => (0).');
is($errors->[0]->errors->[0]->params->{'field_500_a'}, decode_utf8('Obsahuje rejstřík'),
	'Get error parameter (field_500_a => (Obsahuje rejstřík).');
is($errors->[0]->errors->[0]->params->{'material'}, 'book', 'Get error parameter (material => (book).');

# Test.
$obj = MARC::Validator::Plugin::Field500->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc = MARC::File::XML->in($data_dir->file('cnb003239939-bad_map_material_index-500a.xml')->s);
$obj->process($marc->next);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_500', 'Get name (field_500).');
$errors = $ret->plugin_errors;
is(@{$errors}, 1, 'Get errors count (1).');
is($errors->[0]->record_id, 'cnb003239939', 'Get record id (cnb003239939).');
is($errors->[0]->errors->[0]->error, "Missing index in field 008.",
	"Get error (Missing index in field 008.).");
is($errors->[0]->errors->[0]->params->{'field_008_index'}, '0',
	'Get error parameter (field_008_index => (0).');
is($errors->[0]->errors->[0]->params->{'field_500_a'}, decode_utf8('Obsahuje rejstřík'),
	'Get error parameter (field_500_a => (Obsahuje rejstřík).');
is($errors->[0]->errors->[0]->params->{'material'}, 'map', 'Get error parameter (material => (map).');

# Test.
$obj = MARC::Validator::Plugin::Field500->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc = MARC::File::XML->in($data_dir->file('cnb003310078-not_index-500a.xml')->s);
$obj->process($marc->next);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_500', 'Get name (field_500).');
$errors = $ret->plugin_errors;
is(@{$errors}, 0, 'Get errors count (0).');

# Test.
$obj = MARC::Validator::Plugin::Field500->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc = MARC::File::XML->in($data_dir->file('cnb003592608-not_index-500a.xml')->s);
$obj->process($marc->next);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_500', 'Get name (field_500).');
$errors = $ret->plugin_errors;
is(@{$errors}, 0, 'Get errors count (0).');
