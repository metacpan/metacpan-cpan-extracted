use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field020;
use Test::More 'tests' => 38;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field020->new;
my $ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field020->new;
$obj->init;
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field020->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb003260113-incorrect_field_020a_isbn_bad.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_020', 'Get name (field_020).');
my $errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb003260113', 'Get record id (cnb003260113).');
is($errors->[0]->errors->[0]->error, "Bad ISBN in 020a field after fixing of checksum.",
	"Get error (Bad ISBN in 020a field after fixing of checksum.).");
is($errors->[0]->errors->[0]->params->{'Value'}, "979-0-706574-00-4", 'Get error parameter (Value => 979-0-706574-00-4).');

# Test.
$obj = MARC::Validator::Plugin::Field020->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb003698545-incorrect_field_020a_isbn_formatting.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_020', 'Get name (field_020).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb003698545', 'Get record id (cnb003698545).');
is($errors->[0]->errors->[0]->error, "Bad ISBN in 020a field, bad formatting.",
	"Get error (Bad ISBN in 020a field, bad formatting.).");
is($errors->[0]->errors->[0]->params->{'Value'}, "80-900-2311-8", 'Get error parameter (Value => 80-900-2311-8).');

# Test.
$obj = MARC::Validator::Plugin::Field020->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb001410157-incorrect_field_020a_isbn_with_extra_characters.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_020', 'Get name (field_020).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb001410157', 'Get record id (cnb001410157).');
is($errors->[0]->errors->[0]->error, "Bad ISBN in 020a field, extra characters.",
	"Get error (Bad ISBN in 020a field, extra characters.).");
is($errors->[0]->errors->[0]->params->{'Value'}, "80-902905-0-7 :", 'Get error parameter (Value => 80-902905-0-7 :).');

# Test.
$obj = MARC::Validator::Plugin::Field020->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('fake1-incorrect_field_020a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_020', 'Get name (field_020).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'fake1', 'Get record id (fake1).');
is($errors->[0]->errors->[0]->error, "Bad ISBN in 020a field.",
	"Get error (Bad ISBN in 020a field.).");
is($errors->[0]->errors->[0]->params->{'Value'}, 'bad', 'Get error parameter (Value => bad).');

# Test.
$obj = MARC::Validator::Plugin::Field020->new;
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000000168-correct_field_020a_isbn_not_present.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_020', 'Get name (field_020).');
$errors = $ret->plugin_errors;
is_deeply(
	$errors,
	[],
	'No errors.',
);
