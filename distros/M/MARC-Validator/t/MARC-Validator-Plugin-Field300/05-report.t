use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field300;
use Test::More 'tests' => 29;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field300->new;
my $ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field300->new;
$obj->init;
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field300->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc = MARC::File::XML->in($data_dir->file('cnb000344109-missing_008_illustrations.xml')->s)->next;
$obj->process($marc);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_300', 'Get name (field_300).');
my $errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000344109', 'Get record id (cnb000344109).');
is($errors->[0]->errors->[0]->error, "Missing ilustrations in field 008.",
	"Get error (Missing ilustrations in field 008.).");
is($errors->[0]->errors->[0]->params->{'material'}, 'book', 'Get param for material (book).');
is($errors->[0]->errors->[0]->params->{'field_008_illustrations'}, '    ',
	'Get param for field 008 illustrations (    ).');
is($errors->[0]->errors->[0]->params->{'field_300_b'}, decode_utf8('43 s. slovníček ;'),
	'Get param for field 300$b (43 s. slovníček ;).');

# Test.
$obj = MARC::Validator::Plugin::Field300->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc = MARC::File::XML->in($data_dir->file('cnb003662591-missing_008_illustrations-not_coded.xml')->s);
$obj->process($marc->next);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_300', 'Get name (field_300).');
$errors = $ret->plugin_errors;
is(@{$errors}, 0, 'Get errors count (0).');

# Test.
$obj = MARC::Validator::Plugin::Field300->new(
	'recommendation' => 1,
	'record_id_def' => '015a',
);
$obj->init;
$marc = MARC::File::XML->in($data_dir->file('cnb003662591-missing_008_illustrations-not_coded.xml')->s);
$obj->process($marc->next);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_300', 'Get name (field_300).');
$errors = $ret->plugin_errors;
is(@{$errors}, 1, 'Get errors count (1).');
is($errors->[0]->record_id, 'cnb003662591', 'Get record id (cnb003662591).');
is($errors->[0]->errors->[0]->error, "Recommended ilustrations in field 008.",
	"Get error (Recommended ilustrations in field 008.).");
is($errors->[0]->errors->[0]->params->{'material'}, 'book', 'Get param for material (book).');
is($errors->[0]->errors->[0]->params->{'field_008_illustrations'}, '||||',
	'Get param for field 008 illustrations (||||).');
is($errors->[0]->errors->[0]->params->{'field_300_b'}, '1 mapa',
	'Get param for field 300$b (1 mapa).');
