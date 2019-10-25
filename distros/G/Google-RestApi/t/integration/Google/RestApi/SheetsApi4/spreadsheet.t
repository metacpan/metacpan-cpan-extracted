#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../..";
use lib "$FindBin::RealBin/../../../../../lib";

use YAML::Any qw(Dump);
use Test::Most tests => 16;

use aliased "Google::RestApi::SheetsApi4";

use Utils;
Utils::init_logger();

my $name = $Utils::spreadsheet_name;
my $sheets = Utils::sheets_api();
my $spreadsheet = $sheets->create_spreadsheet(title => $name);

my ($id, $uri);
my $qr_id = SheetsApi4->Spreadsheet_Id;
my $qr_uri = SheetsApi4->Spreadsheet_Uri;

like $id = $spreadsheet->spreadsheet_id(), qr/$qr_id/, "Should find spreadsheet ID";
like $uri = $spreadsheet->spreadsheet_uri(), qr/$qr_uri/, "Should find spreadsheet URI";
like $name = $spreadsheet->spreadsheet_name(), qr/^$name$/, "Should find spreadsheet name";

delete @$spreadsheet{qw(id uri)};
$spreadsheet->{name} = $name;
like $spreadsheet->spreadsheet_id(), qr/$qr_id/, "Should find spreadsheet ID when URI is missing";

delete @$spreadsheet{qw(id name)};
$spreadsheet->{uri} = $uri;
like $spreadsheet->spreadsheet_id(), qr/$qr_id/, "Should find spreadsheet ID when name is missing";

delete @$spreadsheet{qw(uri name)};
$spreadsheet->{id} = $id;
like $spreadsheet->spreadsheet_uri(), qr/$qr_uri/, "Should find spreadsheet URI when name is missing";

delete @$spreadsheet{qw(uri id)};
$spreadsheet->{name} = $name;
like $spreadsheet->spreadsheet_uri(), qr/$qr_uri/, "Should find spreadsheet URI when ID is missing";

delete @$spreadsheet{qw(name uri)};
$spreadsheet->{id} = $id;
like $spreadsheet->spreadsheet_name(), qr/^$name$/, "Should find spreadsheet name when URI is missing";

delete @$spreadsheet{qw(name id)};
$spreadsheet->{uri} = $uri;
like $spreadsheet->spreadsheet_name(), qr/^$name$/, "Should find spreadsheet name when ID is missing";

my $properties;
lives_ok sub { $properties = $spreadsheet->properties('title') }, "Retreiving properties should live";
is $properties->{title}, $name, "Title property should be the correct name";

my $worksheets;
lives_ok sub { $worksheets = $spreadsheet->worksheet_properties('title') }, "Retreiving worksheets should live";
is ref($worksheets), 'ARRAY', "Retreiving worksheets should be an array";
is ref($worksheets->[0]), 'HASH', "First worksheet should be a hash";
is $worksheets->[0]->{title}, 'Sheet1', "First worksheet title should be 'Sheet1'";

lives_ok sub { $spreadsheet->delete_spreadsheet(); }, "Deleting spreadsheet should succeed";

$sheets->delete_all_spreadsheets($name);
