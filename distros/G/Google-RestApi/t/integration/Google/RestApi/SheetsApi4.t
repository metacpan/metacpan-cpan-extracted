#!/usr/bin/perl

use strict;
use warnings;

use YAML::Any qw(Dump);
use Test::Most tests => 5;

use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';

use Utils qw(:all);
init_logger();

my $api = rest_api();

my ($sheets, $spreadsheet, $spreadsheets);
isa_ok $sheets = SheetsApi4->new(api => $api), SheetsApi4, "New sheets API object";
isa_ok $spreadsheet = $sheets->create_spreadsheet(title => spreadsheet_name()), Spreadsheet, "New spreadsheet object";
is_hash $spreadsheets = $sheets->spreadsheets(), "Listing spreadsheets";
is_array $spreadsheets->{files}, "Listing spreadsheet files should return an array";
is $sheets->delete_spreadsheet($spreadsheet->spreadsheet_id()), 1, "Deleting spreadsheet";
