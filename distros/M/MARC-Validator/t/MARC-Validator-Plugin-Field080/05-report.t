use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field080;
use Test::More 'tests' => 82;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field080->new;
my $ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field080->new;
$obj->init;
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb000396346-trailing_space_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
my $errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000396346', 'Get record id (cnb000396346).');
is($errors->[0]->errors->[0]->error, "Field 080a has trailing space.",
	"Get error (Field 080a has trailing space.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, "677.062 +65.01] :687.1(082)",
	'Get error parameter (field_080_a => 677.062 +65.01] :687.1(082)).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb003165782-name_is_standalone_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb003165782', 'Get record id (cnb003165782).');
is($errors->[0]->errors->[0]->error, "Field 080a has name standalone.",
	"Get error (Field 080a has name standalone.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('Kružberk (Česko)'),
	'Get error parameter (field_080_a => Kružberk (Česko)).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb001791567-bad_apostrophe_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb001791567', 'Get record id (cnb001791567).');
is($errors->[0]->errors->[0]->error, "Field 080a has bad apostrophe character.",
	"Get error (Field 080a has bad apostrophe character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('81’1'),
	'Get error parameter (field_080_a => 81’1).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb002703924-bad_apostrophe_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb002703924', 'Get record id (cnb002703924).');
is($errors->[0]->errors->[0]->error, "Field 080a has bad apostrophe character.",
	"Get error (Field 080a has bad apostrophe character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('81`35'),
	'Get error parameter (field_080_a => 81`35).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb002880415-bad_apostrophe_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb002880415', 'Get record id (cnb002880415).');
is($errors->[0]->errors->[0]->error, "Field 080a has bad apostrophe character.",
	"Get error (Field 080a has bad apostrophe character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('81&apos;374'),
	'Get error parameter (field_080_a => 81&apos;374).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb002795077-bad_apostrophe_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb002795077', 'Get record id (cnb002795077).');
is($errors->[0]->errors->[0]->error, "Field 080a has bad apostrophe character.",
	"Get error (Field 080a has bad apostrophe character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('81´37-021.6'),
	'Get error parameter (field_080_a => 81´37-021.6).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000037638-bad_quotation_mark_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000037638', 'Get record id (cnb000037638).');
is($errors->[0]->errors->[0]->error, "Field 080a has bad quotation mark character.",
	"Get error (Field 080a has bad quotation mark character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('94(470.23)”1941/1944”'),
	'Get error parameter (field_080_a => 94(470.23)”1941/1944”).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb002220549-bad_quotation_mark_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb002220549', 'Get record id (cnb002220549).');
is($errors->[0]->errors->[0]->error, "Field 080a has bad quotation mark character.",
	"Get error (Field 080a has bad quotation mark character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('355.483(966.2)“1944”'),
	'Get error parameter (field_080_a => 355.483(966.2)“1944”).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000425076-bad_quotation_mark_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000425076', 'Get record id (cnb000425076).');
is($errors->[0]->errors->[0]->error, "Field 080a has bad quotation mark character.",
	"Get error (Field 080a has bad quotation mark character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, qq(32(437)"1918/1938''(061.3)),
	'Get error parameter (field_080_a => 32(437)"1918/1938\'\'(061.3)).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb003713673-bad_quotation_mark_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb003713673', 'Get record id (cnb003713673).');
is($errors->[0]->errors->[0]->error, "Field 080a has bad quotation mark character.",
	"Get error (Field 080a has bad quotation mark character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('017.092:027.53(437.1Ústí n. Labem)\'\'1969"'),
	'Get error parameter (field_080_a => 017.092:027.53(437.1Ústí n. Labem)\'\'1969").');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000990644-bad_dot_character_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000990644', 'Get record id (cnb000990644).');
is($errors->[0]->errors->[0]->error, "Field 080a has bad dot character.",
	"Get error (Field 080a has bad dot character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, '351,7',
	'Get error parameter (field_080_a => 351,7).');
