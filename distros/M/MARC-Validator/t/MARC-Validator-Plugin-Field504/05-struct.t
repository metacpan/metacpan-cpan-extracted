use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field504;
use Test::More 'tests' => 15;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field504->new;
my $ret = $obj->struct;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field504->new;
$obj->init;
$ret = $obj->struct;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field504->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc = MARC::File::XML->in($data_dir->file('cnb000119080-bad_book_material_index.xml')->s);
$obj->process($marc->next);
$ret = $obj->struct;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_504', 'Get name (field_504).');
my $errors = $ret->plugin_errors;
is(@{$errors}, 1, 'Get errors count (1).');
is($errors->[0]->record_id, 'cnb000119080', 'Get record id (cnb000119080).');
is($errors->[0]->errors->[0]->error, "Missing index in field 008.",
	"Get error (Missing index in field 008.).");
is($errors->[0]->errors->[0]->params->{'field_008_index'}, '0',
	'Get error parameter (field_008_index => (0).');
is($errors->[0]->errors->[0]->params->{'field_504_a'}, decode_utf8('Obsahuje bibliografické odkazy a rejstřík'),
	'Get error parameter (field_504_a => (Obsahuje bibliografické odkazy a rejstřík).');
is($errors->[0]->errors->[0]->params->{'material'}, 'book', 'Get error parameter (material => (book).');
