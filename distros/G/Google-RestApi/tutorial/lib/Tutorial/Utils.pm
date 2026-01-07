package Tutorial::Utils;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib";

use File::Temp qw(tempdir);
use Log::Log4perl qw(:easy get_logger);
use Term::ANSIColor;
use Test::More;
use YAML::Any qw(Dump LoadFile);

use aliased "Google::RestApi";
use aliased "Google::RestApi::SheetsApi4";

use Exporter qw(import);
our @EXPORT_OK = qw(
  rest_api sheets_api
  spreadsheet_name
  message start end end_go start_note
  show_api
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub rest_api { RestApi->new(@_, config_file => config_file()); }
sub sheets_api { SheetsApi4->new(@_, api => rest_api()); }

# point GOOGLE_RESTAPI_CONFIG to a file that contains the OAuth2 access config
# for integration and tutorials to run. unit tests are mocked so is not needed
# for them.
sub config_file {
  my $config_file = $ENV{GOOGLE_RESTAPI_CONFIG} or do {
    message('red', "No testing config file found: set env var GOOGLE_RESTAPI_CONFIG first.");
    message('yellow', "Run 'bin/google_restapi_oauth_token_creator' and set your env var 'GOOGLE_RESTAPI_CONFIG' " .
        "to point to the config file it creates (e.g. 'GOOGLE_RESTAPI_CONFIG=~/.google/sheets.yaml $0'. " .
        "Taking you to the perldoc now.");
    end();
    exec 'perldoc ../../bin/google_restapi_oauth_token_creator';
  };
  return $config_file;
}

# standard tutorial spreadsheet name.
sub spreadsheet_name { 'google_restapi_sheets_tutorial'; }

# used by tutorial to interact with the user as each step in the tutorial is performed.
sub message { print color(shift), @_, color('reset'), "\n"; }
sub start { message('yellow', @_, ".."); }
sub end { message('green', @_, " Press enter to continue.\n"); <>; }
sub end_go { message('green', @_, "\n"); }

sub start_note {
  my $spreadsheet_name = spreadsheet_name();
  end(
    "NOTE:\n" .
    "Before running this script, you must have already run @_.\n" .
    "If more than one spreadsheet exists called '$spreadsheet_name', you must run 99_delete_all and start over again with 10_spreadsheet.pl."
  );
  return;
}

sub show_api {
  my $trans = shift;

  # if debug logging is turned on no sense in repeating the same info.
  my $logger = get_logger();
  return if $logger->level() <= $DEBUG;

  my %dump = (
    request  => $trans->{request},
    response => $trans->{decoded_response},
  );
  warn color('magenta'), "Sent request to api:\n", color('reset'), Dump(\%dump);
  return;
}

1;
