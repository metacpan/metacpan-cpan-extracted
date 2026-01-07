package Test::Integration::Utils;

use strict;
use warnings;

use aliased "Google::RestApi";
use aliased "Google::RestApi::SheetsApi4";

use Exporter qw(import);
our @EXPORT_OK = qw(
  rest_api sheets_api config_file
  spreadsheet spreadsheet_name delete_all_spreadsheets
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

# used to clean up spreadsheets after tests are done.
sub delete_all_spreadsheets { shift->delete_all_spreadsheets_by_filters("name = '" . spreadsheet_name() . "'"); }

# standard testing spreadsheet name.
sub spreadsheet_name { 'google_restapi_sheets_integration_testing'; }

# called to create a spreadsheet for use in tests.
sub spreadsheet { sheets_api()->create_spreadsheet(title => spreadsheet_name()); }

# set throttle to 1 if you start getting 403's or 429's back from google.
sub rest_api { RestApi->new(@_, config_file => config_file(), throttle => 1); }

sub sheets_api {
  my $api = rest_api(@_);
  return SheetsApi4->new(api => $api);
}

# point GOOGLE_RESTAPI_CONFIG to a file that contains the OAuth2 access config
# for integration and tutorials to run. unit tests are mocked so is not needed
# for them.
sub config_file {
  my $config_file = $ENV{GOOGLE_RESTAPI_CONFIG}
    or die "No testing config file found: set env var GOOGLE_RESTAPI_CONFIG first";
  return $config_file;
}

1;
