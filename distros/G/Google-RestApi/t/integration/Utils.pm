package Utils;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib";

use File::Basename;
use File::Temp qw(tempdir);
use Log::Log4perl qw(:easy);
use Term::ANSIColor;
use YAML::Any qw(Dump LoadFile);

use aliased "Google::RestApi";
use aliased "Google::RestApi::SheetsApi4";

use Exporter qw(import);
our @EXPORT_OK = qw(init_logger message start end end_go show_api);

our $spreadsheet_name = 'google_restapi_sheets_testing';

sub init_logger {
  my $logger_conf = $ENV{GOOGLE_RESTAPI_LOGGER};
  Log::Log4perl->init($logger_conf) if defined $logger_conf;
  return;
}

# this is for log4perl.conf to call back to get the log file name.
sub log_file_name { tempdir() . "/google_restapi.log"; }

sub delete_all_spreadsheets {
  shift->delete_all_spreadsheets($spreadsheet_name);
  return;
}

sub spreadsheet {
  my $sheets = Utils::sheets_api();
  return $sheets->create_spreadsheet(title => $spreadsheet_name);
}

sub sheets_api {
  my $api = rest_api(@_);
  return SheetsApi4->new(api => $api);
}

sub rest_api_config {
  my $config_file = $ENV{GOOGLE_RESTAPI_LOGIN}
    or die "No testing config file found: set env var GOOGLE_RESTAPI_LOGIN first";
  return $config_file;
}

# set throttle to 1 if you start getting 403's back from google.
sub rest_api { RestApi->new(@_, config_file => rest_api_config(), throttle => 0); }
sub message { print color(shift), @_, color('reset'), "\n"; }
sub start { message('yellow', @_, ".."); }
sub end { message('green', @_, " Press enter to continue.\n"); <>; }
sub end_go { message('green', @_, "\n"); }

sub show_api {
  my %p = @_;
  my %dump = (
    called           => $p{called},
    response_content => $p{content},
  );
  warn color('magenta'), "Sent request to api:\n", color('reset'), Dump(\%dump);
  return;
}

1;
