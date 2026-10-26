use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field080;
use Test::More 'tests' => 189;
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
is($errors->[0]->errors->[0]->params->{'position'}, 7,
	'Get error parameter (position => 7).');

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
is($errors->[0]->errors->[0]->params->{'position'}, 0,
	'Get error parameter (position => 0).');

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
is($errors->[0]->errors->[0]->params->{'position'}, 2,
	'Get error parameter (position => 2).');

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
is($errors->[0]->errors->[0]->params->{'position'}, 2,
	'Get error parameter (position => 2).');

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
is($errors->[0]->errors->[0]->params->{'position'}, 2,
	'Get error parameter (position => 2).');

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
is($errors->[0]->errors->[0]->params->{'position'}, 2,
	'Get error parameter (position => 2).');

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
is($errors->[0]->errors->[0]->params->{'position'}, 10,
	'Get error parameter (position => 10).');

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
is($errors->[0]->errors->[0]->params->{'position'}, 14,
	'Get error parameter (position => 14).');

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
is($errors->[0]->errors->[0]->params->{'position'}, 17,
	'Get error parameter (position => 17).');

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
is($errors->[0]->errors->[0]->params->{'position'}, 34,
	'Get error parameter (position => 34).');

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
is($errors->[0]->errors->[0]->params->{'position'}, 3,
	'Get error parameter (position => 3).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000608258-trailing_space_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000608258', 'Get record id (cnb000608258).');
is($errors->[0]->errors->[0]->error, "Field 080a has trailing space.",
	"Get error (Field 080a has trailing space.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, '784.71- 044.357',
	'Get error parameter (field_080_a => 784.71- 044.357).');
is($errors->[0]->errors->[0]->params->{'position'}, 7,
	'Get error parameter (position => 7).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000452844-trailing_space_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000452844', 'Get record id (cnb000452844).');
is($errors->[0]->errors->[0]->error, "Field 080a has trailing space.",
	"Get error (Field 080a has trailing space.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, '885-93-343.4 = 393',
	'Get error parameter (field_080_a => 885-93-343.4 = 393).');
is($errors->[0]->errors->[0]->params->{'position'}, 12,
	'Get error parameter (position => 12).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb003501382-missing_opening_parenthesis_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb003501382', 'Get record id (cnb003501382).');
is($errors->[0]->errors->[0]->error, "Field 080a has missing opening parenthesis '('.",
	"Get error (Field 080a has missing opening parenthesis '('.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, '086.7)08',
	'Get error parameter (field_080_a => 086.7)08).');
is($errors->[0]->errors->[0]->params->{'position'}, 0,
	'Get error parameter (position => 0).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb001705841-missing_closing_parenthesis_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb001705841', 'Get record id (cnb001705841).');
is($errors->[0]->errors->[0]->error, "Field 080a has missing closing parenthesis ')'.",
	"Get error (Field 080a has missing closing parenthesis ')'.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, '(035',
	'Get error parameter (field_080_a => (035).');
is($errors->[0]->errors->[0]->params->{'position'}, 4,
	'Get error parameter (position => 4).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb002156781-extra_closing_parenthesis_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb002156781', 'Get record id (cnb002156781).');
is($errors->[0]->errors->[0]->error, "Field 080a has extra closing parenthesis ')'.",
	"Get error (Field 080a has extra closing parenthesis ')'.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, '(437.3))',
	'Get error parameter (field_080_a => (437.3))).');
is($errors->[0]->errors->[0]->params->{'position'}, 7,
	'Get error parameter (position => 7).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000457509-missing_closing_quotation_mark_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000457509', 'Get record id (cnb000457509).');
is($errors->[0]->errors->[0]->error, "Field 080a has missing closing quotation mark '\"'.",
	"Get error (Field 080a has missing closing quotation mark '\"'.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, '016:794.1"1960/1972',
	'Get error parameter (field_080_a => 016:794.1"1960/1972).');
is($errors->[0]->errors->[0]->params->{'position'}, 19,
	'Get error parameter (position => 19).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000638859-extra_opening_parenthesis_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000638859', 'Get record id (cnb000638859).');
is($errors->[0]->errors->[0]->error, "Field 080a has extra opening parenthesis '('.",
	"Get error (Field 080a has extra opening parenthesis '('.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, '(94(437)',
	'Get error parameter (field_080_a => (94(437)).');
is($errors->[0]->errors->[0]->params->{'position'}, 0,
	'Get error parameter (position => 0).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000494927-bad_year_in_time_auxiliary_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000494927', 'Get record id (cnb000494927).');
is($errors->[0]->errors->[0]->error, "Field 080a has invalid year in time auxiliary.",
	"Get error (Field 080a has invalid year in time auxiliary.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, '929.3:378.961(437.11)"1657/178.3=71',
	'Get error parameter (field_080_a => 929.3:378.961(437.11)"1657/178.3=71).');
is($errors->[0]->errors->[0]->params->{'position'}, 27,
	'Get error parameter (position => 27).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('fake5-bad_hyphen_character_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'fake5', 'Get record id (fake5).');
is($errors->[0]->errors->[0]->error, "Field 080a has bad hyphen character.",
	"Get error (Field 080a has bad hyphen character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('821‑93'),
	'Get error parameter (field_080_a => 821‑93).');
is($errors->[0]->errors->[0]->params->{'position'}, 3,
	'Get error parameter (position => 3).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb003786604-extra_dash_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb003786604', 'Get record id (cnb003786604).');
is($errors->[0]->errors->[0]->error, "Field 080a has extra dash character.",
	"Get error (Field 080a has extra dash character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('27--243.37'),
	'Get error parameter (field_080_a => 27--243.37).');
is($errors->[0]->errors->[0]->params->{'position'}, 3,
	'Get error parameter (position => 3).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb003070764-extra_dot_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb003070764', 'Get record id (cnb003070764).');
is($errors->[0]->errors->[0]->error, "Field 080a has extra dot character.",
	"Get error (Field 080a has extra dot character.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('578.82./.83'),
	'Get error parameter (field_080_a => 578.82./.83).');
is($errors->[0]->errors->[0]->params->{'position'}, 6,
	'Get error parameter (position => 6).');

# Test.
$obj = MARC::Validator::Plugin::Field080->new(
	'record_id_def' => '015a',
);
$obj->init;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000404267-missing_operator_in_080a.xml')->s)->next;
$obj->process($marc_record);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_080', 'Get name (field_080).');
$errors = $ret->plugin_errors;
is($errors->[0]->record_id, 'cnb000404267', 'Get record id (cnb000404267).');
is($errors->[0]->errors->[0]->error, "Field 080a has missing operator.",
	"Get error (Field 080a has missing operator.).");
is($errors->[0]->errors->[0]->params->{'field_080_a'}, decode_utf8('323.22(437)"1939/1945":943.7"1939/1945"940.5:329.15(437)(082)'),
	'Get error parameter (field_080_a => 323.22(437)"1939/1945":943.7"1939/1945"940.5:329.15(437)(082)).');
is($errors->[0]->errors->[0]->params->{'position'}, 39,
	'Get error parameter (position => 39).');
