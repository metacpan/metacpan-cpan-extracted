package Test::Tutorial::Utils;

# just a common set of utilities for unit and integration tests, and tutorial.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib";

use File::Temp qw(tempdir);
use Log::Log4perl qw(:easy);
use Term::ANSIColor;
use Test::More;
use YAML::Any qw(Dump LoadFile);

use aliased "Google::RestApi";
use aliased "Google::RestApi::SheetsApi4";

use Exporter qw(import);
our @EXPORT_OK = qw(
  rest_api sheets_api
  spreadsheet_name
  message start end end_go show_api
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub rest_api { RestApi->new(@_, config_file => config_file()); }
sub sheets_api { SheetsApi4->new(@_, api => rest_api()); }

# point GOOGLE_RESTAPI_CONFIG to a file that contains the OAuth2 access config
# for integration and tutorials to run. unit tests are mocked so is not needed
# for them.
sub config_file {
  my $config_file = $ENV{GOOGLE_RESTAPI_CONFIG}
    or die "No testing config file found: set env var GOOGLE_RESTAPI_CONFIG first";
  return $config_file;
}

# standard tutorial spreadsheet name.
sub spreadsheet_name { 'google_restapi_sheets_tutorial'; }

# used by tutorial to interact with the user as each step in the tutorial is performed.
sub message { print color(shift), @_, color('reset'), "\n"; }
sub start { message('yellow', @_, ".."); }
sub end { message('green', @_, " Press enter to continue.\n"); <>; }
sub end_go { message('green', @_, "\n"); }

sub show_api {
  my $trans = shift;
  my %dump = (
    request  => $trans->{request},
    response => $trans->{decoded_response},
  );
  warn color('magenta'), "Sent request to api:\n", color('reset'), Dump(\%dump);
  return;
}

1;
