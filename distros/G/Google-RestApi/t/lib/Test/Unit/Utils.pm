package Test::Unit::Utils;

use strict;
use warnings;

use FindBin;
use File::Spec::Functions qw( catfile );
use Module::Load qw( load );

use Exporter qw(import);
our @EXPORT_OK = qw(
  mock_config_file mock_token_file
  mock_spreadsheet_name mock_spreadsheet_name2
  mock_worksheet_id mock_worksheet_name
  mock_rest_api mock_sheets_api
  drive_endpoint sheets_endpoint
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub mock_config_file { $ENV{GOOGLE_RESTAPI_CONFIG} ? $ENV{GOOGLE_RESTAPI_CONFIG} : catfile($FindBin::RealBin, qw(etc rest_config.yaml)); }
sub mock_token_file { catfile($FindBin::RealBin, qw(etc rest_config.token)); }
sub mock_spreadsheet_name { 'mock_spreadsheet1'; }
sub mock_spreadsheet_name2 { 'mock_spreadsheet2'; }
sub mock_worksheet_id { 0; }
sub mock_worksheet_name { 'Sheet1'; }

# require these ones so that errors in them don't prevent other tests from running.
sub mock_rest_api { _load_and_new('Google::RestApi', config_file => mock_config_file(), @_); }
sub mock_sheets_api { _load_and_new('Google::RestApi::SheetsApi4', api => mock_rest_api(), @_); }

sub drive_endpoint { $Google::RestApi::DriveApi3::Drive_Endpoint; }
sub sheets_endpoint { $Google::RestApi::SheetsApi4::Sheets_Endpoint; }

sub _load_and_new {
  my $class = shift;
  load $class;
  return $class->new(@_);
}

1;
