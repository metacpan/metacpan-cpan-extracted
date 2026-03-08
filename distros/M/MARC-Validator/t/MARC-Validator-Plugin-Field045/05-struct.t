use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field045;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field045->new;
my $ret = $obj->struct;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field045->new;
$obj->init;
$ret = $obj->struct;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field045->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc = MARC::File::XML->in($data_dir->file('cnb000564501-bad_first_character_on_045a.xml')->s);
$obj->process($marc->next);
$ret = $obj->struct;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_045', 'Get name (field_045).');
my $errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000564501', 'Get record id (cnb000564501).');
is($errors->[0]->errors->[0]->error, "Field 045a has invalid first block.",
	"Get error (Field 045a has invalid first block.).");
is($errors->[0]->errors->[0]->params->{'value'}, '--', 'Get error parameter (value => (--).');
