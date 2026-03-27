use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field040;
use Test::More 'tests' => 24;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field040->new;
my $ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field040->new;
$obj->init;
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field040->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb002172297-leader_desc_cataloging_form_coolidate_with_rda.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_040', 'Get name (field_040).');
my $errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb002172297', 'Get record id (cnb002172297).');
is($errors->[0]->errors->[0]->error, "Leader descriptive cataloging form (a) is inconsistent with field 040e description conventions (rda).",
	"Get error (Leader descriptive cataloging form (a) is inconsistent with field 040e description conventions (rda).).");

# Test.
$obj = MARC::Validator::Plugin::Field040->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('fake2-incorrect_leader.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_040', 'Get name (field_040).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'fake2', 'Get record id (fake2).');
is($errors->[0]->errors->[0]->error, "Bad number in length.",
	"Get error (Bad number in length.).");
is($errors->[0]->errors->[0]->params->{'String'}, 'x1753', 'Get error parameter (String => x1753).');

# Test.
$obj = MARC::Validator::Plugin::Field040->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('fake4-missing_field_040.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_040', 'Get name (field_040).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'fake4', 'Get record id (fake4).');
is($errors->[0]->errors->[0]->error, "Field 040 isn't present.",
	"Get error (Field 040 isn't present.).");
