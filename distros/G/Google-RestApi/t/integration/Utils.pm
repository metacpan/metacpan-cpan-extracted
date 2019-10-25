package Utils;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib";

use File::Basename;
use Log::Log4perl qw(:easy);
use Storable;
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
sub log_file_name { "/tmp/$ENV{USER}/google_restapi.log"; }

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

sub rest_api {
  my $config = rest_api_config();
  return RestApi->new(@_, %$config, throttle => 1);
}

sub rest_api_config {
  my $login_file = $ENV{GOOGLE_RESTAPI_LOGIN}
    or die "No testing login file found: set env var GOOGLE_RESTAPI_LOGIN first";
  my $login = eval { LoadFile($login_file); };
  die "Unable to load login file '$login_file': $@" if $@;

  $login->{login} or die "Login config missing from login file '$login_file'";
  $login->{token} or die "Token config missing from login file '$login_file'";

  my $dirname = dirname($login_file);
  my $token_file = "$dirname/$login->{token}";
  my $token = retrieve($token_file);
  $login->{login}->{refresh_token} = $token->{refresh_token};

  return $login->{login};
}

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
