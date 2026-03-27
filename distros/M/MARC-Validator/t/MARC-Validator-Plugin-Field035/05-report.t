use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field035;
use Test::More 'tests' => 20;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field035->new;
my $ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field035->new;
$obj->init;
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field035->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc = MARC::File::XML->in($data_dir->file('cnb000545093-cnb001214971-duplicite_035a.xml')->s);
$obj->process($marc->next);
$obj->process($marc->next);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_035', 'Get name (field_035).');
my $errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb001214971', 'Get record id (cnb001214971).');
is($errors->[0]->errors->[0]->error, "Bad system control number in 035a field.",
	"Get error (Bad system control number in 035a field.).");
is($errors->[0]->errors->[0]->params->{'duplicate_to'}, 'cnb000545093', 'Get error parameter (duplicate_to => cnb000545093).');
is($errors->[0]->errors->[0]->params->{'value'}, '(OCoLC)51768478', 'Get error parameter (value => (OCoLC)51768478).');

# Test.
$obj = MARC::Validator::Plugin::Field035->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc = MARC::File::XML->in($data_dir->file('cnb000008190-duplicates_in_035a_fields.xml')->s);
$obj->process($marc->next);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_035', 'Get name (field_035).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000008190', 'Get record id (cnb000008190).');
is($errors->[0]->errors->[0]->error, "Duplicate system control number in 035a field.",
	"Get error (Duplicate system control number in 035a field.).");
is($errors->[0]->errors->[0]->params->{'Value'}, '(OCoLC)39406753', 'Get error parameter (Value => (OCoLC)39406753).');
