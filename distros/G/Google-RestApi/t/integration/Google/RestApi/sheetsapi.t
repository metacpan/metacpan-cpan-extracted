#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../..";
use lib "$FindBin::RealBin/../../../../lib";

use YAML::Any qw(Dump);
use Test::Most tests => 6;

use Utils;
Utils::init_logger();

use aliased "Google::RestApi::SheetsApi4";

my $name = $Utils::spreadsheet_name;
my $api = Utils::rest_api();

my ($sheets, $spreadsheet);
lives_ok sub { $sheets = SheetsApi4->new(api => $api); }, "New sheets object should be created";
lives_ok sub { $spreadsheet = $sheets->create_spreadsheet(title => $name); }, "Creating spreadsheet should succeed";
is ref(my $list = $sheets->spreadsheets()), 'HASH', "Listing spreadsheets should return a hash";
is ref($list->{files}), 'ARRAY', "Listing spreadsheet files should return an array";
lives_ok sub { $sheets->delete_spreadsheet($spreadsheet->spreadsheet_id()); }, "Deleting spreadsheet should succeed";
lives_ok sub { $sheets->delete_all_spreadsheets($name); }, "Deleting all spreadsheets should succeed";
