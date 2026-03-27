use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Plugin::Field655;
use Test::More 'tests' => 15;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Plugin::Field655->new;
my $ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors without init.');

# Test.
$obj = MARC::Validator::Plugin::Field655->new;
$obj->init;
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
is(scalar @{$ret->plugin_errors}, 0, 'No errors with init, without process.');

# Test.
$obj = MARC::Validator::Plugin::Field655->new(
	'record_id_def' => '015a',
);
$obj->init;
my $marc = MARC::File::XML->in($data_dir->file('cnb000038388-comics_no_in_field_008.xml')->s);
$obj->process($marc->next);
$ret = $obj->report;
isa_ok($ret, 'Data::MARC::Validator::Report::Plugin');
ok(defined $ret->module_name, 'Module name is defined.');
ok(defined $ret->version, 'Version is defined.');
is($ret->name, 'field_655', 'Get name (field_655).');
my $errors = $ret->plugin_errors;
is(@{$errors}, 1, 'Get errors count (1).');
is($errors->[0]->record_id, 'cnb000038388', 'Get record id (cnb000038388).');
is($errors->[0]->errors->[0]->error, "Missing comics nature of content in field 008.",
	"Get error (Missing comics nature of content in field 008.).");
is($errors->[0]->errors->[0]->params->{'field_008_nature_of_content'}, '    ',
	'Get error parameter (field_008_nature_of_content => (    ).');
is($errors->[0]->errors->[0]->params->{'field_655_a'}, 'komiksy',
	'Get error parameter (field_655_a => (komiksy).');
is($errors->[0]->errors->[0]->params->{'material'}, 'book', 'Get error parameter (material => (book).');
