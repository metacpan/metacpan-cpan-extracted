package Test::Unit::Utils;

use strict;
use warnings;

use FindBin;
use File::Spec::Functions qw( catfile );
use Module::Load qw( load );

use Exporter qw(import);
our @EXPORT_OK = qw(
  fake_uri_responses_file fake_response_json_file fake_config_file fake_token_file
  fake_spreadsheet_id fake_spreadsheet_name fake_spreadsheet_name2
  fake_worksheet_id fake_worksheet_name
  fake_rest_api fake_sheets_api fake_spreadsheet_uri fake_spreadsheet
  fake_worksheet_uri fake_worksheet
  drive_endpoint sheets_endpoint
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub fake_uri_responses_file { catfile( $FindBin::RealBin, qw(etc uri_responses), (shift . ".yaml") ); }
sub fake_response_json_file { catfile( $FindBin::RealBin, qw(etc uri_responses), (shift . ".json") ); }
sub fake_config_file { catfile($FindBin::RealBin, qw(etc rest_config.yaml)); }
sub fake_token_file { catfile($FindBin::RealBin, qw(etc rest_config.token)); }
sub fake_spreadsheet_id { 'fake_spreadsheet_id1'; }
sub fake_spreadsheet_name { 'fake_spreadsheet1'; }
sub fake_spreadsheet_name2 { 'fake_spreadsheet2'; }
sub fake_worksheet_id { 0; }
sub fake_worksheet_name { 'Sheet1'; }

# require these ones so that errors in them don't prevent other tests from running.
sub fake_rest_api { _load_and_new('Google::RestApi', config_file => fake_config_file(), @_); }
sub fake_sheets_api { _load_and_new('Google::RestApi::SheetsApi4', api => fake_rest_api(), @_); }
sub fake_spreadsheet { _load_and_new('Google::RestApi::SheetsApi4::Spreadsheet', sheets_api => fake_sheets_api(), id => fake_spreadsheet_id(), @_); }
sub fake_worksheet { _load_and_new('Google::RestApi::SheetsApi4::Worksheet', spreadsheet => fake_spreadsheet(), id => fake_worksheet_id(), @_); }

sub fake_spreadsheet_uri { load('Google::RestApi::SheetsApi4'); Google::RestApi::SheetsApi4->Spreadsheet_Uri . '/' . fake_spreadsheet_id(); }
sub fake_worksheet_uri { fake_spreadsheet_uri() . "&gid=" . fake_worksheet_id(); }

sub drive_endpoint { Google::RestApi::DriveApi3->Drive_Endpoint; }
sub sheets_endpoint { Google::RestApi::SheetsApi4->Sheets_Endpoint; }

sub _load_and_new {
  my $class = shift;
  load $class;
  return $class->new(@_);
}

1;
