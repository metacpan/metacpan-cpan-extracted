package Test::Unit::Utils;

use strict;
use warnings;

use FindBin;
use aliased "Google::RestApi";
use aliased "Google::RestApi::SheetsApi4";
use aliased "Google::RestApi::SheetsApi4::Spreadsheet";
use aliased "Google::RestApi::SheetsApi4::Worksheet";

use Exporter qw(import);
our @EXPORT_OK = qw(
  fake_uri_responses_file fake_response_json_file fake_config_file fake_token_file
  fake_rest_api fake_sheets_api
  fake_spreadsheet fake_spreadsheet_name fake_spreadsheet_name2 fake_spreadsheet_id fake_spreadsheet_uri
  fake_worksheet fake_worksheet_name fake_worksheet_id fake_worksheet_uri
  fake_sheets_config_file fake_config_sheets_api fake_config_spreadsheet fake_config_worksheet
  drive_endpoint sheets_endpoint
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub fake_uri_responses_file { "$FindBin::RealBin/etc/uri_responses/" . shift . ".yaml"; }
sub fake_response_json_file { "$FindBin::RealBin/etc/uri_responses/" . shift . ".json"; }
sub fake_config_file { "$FindBin::RealBin/etc/rest_config.yaml"; }
sub fake_token_file { "$FindBin::RealBin/etc/rest_config.token"; }
sub fake_rest_api { RestApi->new(config_file => fake_config_file(), @_); }
sub fake_sheets_api { SheetsApi4->new(api => fake_rest_api(), @_); }
sub fake_spreadsheet { Spreadsheet->new(sheets_api => fake_sheets_api(), id => fake_spreadsheet_id(), @_); }
sub fake_spreadsheet_id { 'fake_spreadsheet_id1'; }
sub fake_spreadsheet_name { 'fake_spreadsheet1'; }
sub fake_spreadsheet_name2 { 'fake_spreadsheet2'; }
sub fake_spreadsheet_uri { SheetsApi4->Spreadsheet_Uri . '/' . fake_spreadsheet_id(); }
sub fake_worksheet { Worksheet->new(spreadsheet => fake_spreadsheet(), id => fake_worksheet_id(), @_); }
sub fake_worksheet_id { 0; }
sub fake_worksheet_name { 'Sheet1'; }
sub fake_worksheet_uri { fake_spreadsheet_uri() . "&gid=" . fake_worksheet_id(); }

sub fake_sheets_config_file { "$FindBin::RealBin/etc/sheets_config.yaml"; }
sub fake_config_sheets_api { fake_sheets_api(sheets_config => fake_sheets_config_file(), @_); }
sub fake_config_spreadsheet { fake_spreadsheet(sheets_api => fake_config_sheets_api(), config_id => 'customers', @_); }
sub fake_config_worksheet {
  my $ws0 = fake_worksheet(spreadsheet => fake_config_spreadsheet(), config_id => 'addresses', @_);
  $ws0->enable_header_col(1);
  return $ws0;
}

sub sheets_endpoint { SheetsApi4->Sheets_Endpoint; }

1;
