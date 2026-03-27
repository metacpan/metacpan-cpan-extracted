use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field008;
use Test::More 'tests' => 46;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field008->new;
my $ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field008->new;
$obj->init;
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field008->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb001920818-incorrect_field_008_syntax_quote_mark.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_008', 'Get name (field_008).');
my $errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb001920818', 'Get record id (cnb001920818).');
is($errors->[0]->errors->[0]->error, "Parameter 'date1' has bad value.",
	"Get error (Parameter 'date1' has bad value.).");
is($errors->[0]->errors->[0]->params->{'Value'}, "197?", 'Get error parameter (Value => 197?).');

# Test.
$obj = MARC::Validator::Plugin::Field008->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000295209-incorrect_field_008_syntax_space.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_008', 'Get name (field_008).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000295209', 'Get record id (cnb000295209).');
is($errors->[0]->errors->[0]->error, "Parameter 'date1' has value with space character.",
	"Get error (Parameter 'date1' has value with space character.).");
is($errors->[0]->errors->[0]->params->{'Value'}, "189 ", 'Get error parameter (Value => 189 ).');

# Test.
$obj = MARC::Validator::Plugin::Field008->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb001873805-incorrect_field_008_content-blank.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_008', 'Get name (field_008).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb001873805', 'Get record id (cnb001873805).');
is($errors->[0]->errors->[0]->error, "Field 008 date 1 need to be fill.",
	"Get error (Field 008 date 1 need to be fill.).");
is($errors->[0]->errors->[0]->params->{'Value'}, '080921s        xr ||| g       nn        ',
	'Get error parameter (Value => 080921s        xr ||| g       nn        ).');

# Test.
$obj = MARC::Validator::Plugin::Field008->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb001696044-bad_date2_in_currently_published.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_008', 'Get name (field_008).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb001696044', 'Get record id (cnb001696044).');
is($errors->[0]->errors->[0]->error, "Field 008 date 2 need to be 9999, it's currently published.",
	"Get error (Field 008 date 2 need to be 9999, it's currently published).");
is($errors->[0]->errors->[0]->params->{'Value'}, '061102c19972002xr  x w s     0   b2cze  ',
	'Get error parameter (Value => 061102c19972002xr  x w s     0   b2cze  ).');

# Test.
$obj = MARC::Validator::Plugin::Field008->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('fake2-incorrect_leader.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_008', 'Get name (field_008).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'fake2', 'Get record id (fake2).');
is($errors->[0]->errors->[0]->error, "Bad number in length.",
	"Get error (Bad number in length.).");
is($errors->[0]->errors->[0]->params->{'String'}, 'x1753',
	'Get error parameter (String => x1753).');

# Test.
$obj = MARC::Validator::Plugin::Field008->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('fake3-missing_field_008.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_008', 'Get name (field_008).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'fake3', 'Get record id (fake3).');
is($errors->[0]->errors->[0]->error, "Field 008 is not present.",
	"Get error (Field 008 is not present.).");
