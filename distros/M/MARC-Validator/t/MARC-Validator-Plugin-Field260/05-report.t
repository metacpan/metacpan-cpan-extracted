use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field260;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field260->new;
my $ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field260->new;
$obj->init;
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field260->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb001880327-incorrect_260c.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_260', 'Get name (field_260).');
my $errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb001880327', 'Get record id (cnb001880327).');
is($errors->[0]->errors->[0]->error, "Bad year in parenthesis in MARC field 260 \$c.",
	"Get error (Bad year in parenthesis in MARC field 260 \$c.).");
is($errors->[0]->errors->[0]->params->{'Value'}, '(1861)', 'Get error parameter (Value => (1861)).');
