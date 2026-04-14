package Test::Google::RestApi::ScopeCheck;

use Test::Unit::Setup;

use HTTP::Tiny ();
use JSON::MaybeXS qw(decode_json);

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_suppress_retries         { 1; }
sub dont_create_mock_spreadsheets { 1; }

# Each entry is a minimal GET that proves both the OAuth scope is granted
# and the API is enabled in Google Cloud Console. A 403 with an activationUrl
# in the response body means the API is not enabled; anything else (including
# 404 for probe URIs) means the API is reachable.
my @API_CHECKS = (
  {
    name  => 'Drive API',
    scope => 'https://www.googleapis.com/auth/drive',
    uri   => 'https://www.googleapis.com/drive/v3/about?fields=user',
  },
  {
    name  => 'Sheets API',
    scope => 'https://www.googleapis.com/auth/spreadsheets',
    uri   => 'https://sheets.googleapis.com/v4/spreadsheets/scope_check_probe',
  },
  {
    name  => 'Calendar API',
    scope => 'https://www.googleapis.com/auth/calendar',
    uri   => 'https://www.googleapis.com/calendar/v3/users/me/calendarList?maxResults=1',
  },
  {
    name  => 'Docs API',
    scope => 'https://www.googleapis.com/auth/documents',
    uri   => 'https://docs.googleapis.com/v1/documents/scope_check_probe',
  },
  {
    name  => 'Gmail API',
    scope => 'https://www.googleapis.com/auth/gmail.modify',
    uri   => 'https://gmail.googleapis.com/gmail/v1/users/me/profile',
  },
  {
    name  => 'Tasks API',
    scope => 'https://www.googleapis.com/auth/tasks',
    uri   => 'https://tasks.googleapis.com/tasks/v1/users/@me/lists?maxResults=1',
  },
);

# Do not call SUPER::startup — that would override Furl::HTTP::connect and
# block the real HTTP calls we need to probe each API.
sub startup : Tests(startup) {
  my $self = shift;
  return;
}

sub check_scopes : Tests(6) {
  my $self = shift;

  SKIP: {
    skip 'Set GOOGLE_RESTAPI_CONFIG to check API scopes and enablement', scalar @API_CHECKS
      unless $ENV{GOOGLE_RESTAPI_CONFIG};

    my %auth_header = @{ mock_rest_api()->auth()->headers() };
    my $ua = HTTP::Tiny->new(timeout => 10);

    for my $check (@API_CHECKS) {
      my $res  = $ua->get($check->{uri}, { headers => \%auth_header });
      my $body = eval { decode_json($res->{content}) } // {};

      my $activation_url = _activation_url($body);
      if ($activation_url) {
        fail "$check->{name} not enabled in Google Cloud Console. Visit:\n  $activation_url";
      } else {
        pass "$check->{name} reachable (HTTP $res->{status})";
      }
    }
  }

  return;
}

sub _activation_url {
  my ($body) = @_;
  my $details = eval { $body->{error}{details} };
  return unless ref $details eq 'ARRAY';
  for my $detail (@$details) {
    my $url = eval { $detail->{metadata}{activationUrl} };
    return $url if $url;
  }
  return;
}

1;
