package Test::Unit::TestBase;

# the '_' subroutines are considered 'protected', not 'private', so child classes will call them.

use Test::Unit::Setup;

use File::Slurp qw(read_file);
use Hash::Merge qw(merge);
use Mock::MonkeyPatch;
use Module::Load qw(load);
use Try::Tiny;
use YAML::Any qw(LoadFile);

use Test::Unit::UriResponse;

use parent 'Test::Class';

sub setup : Tests(setup) {
  my $self = shift;

  # temp storage to fake spreadsheet cells, set by post_*, used by get_* in etc/uri_responses.
  $self->{cell_values} = {};

  # ensure that we don't send any network traffic to google during our unit tests.
  # this can happen if we don't have 'Furl::request' overridden with a canned response.
  $self->_fake('http_connection', 'Furl::HTTP', 'connect',
    sub { die "For testing you need to set _fake_http_response"; }
  );

  return;
}

sub teardown : Tests(teardown) { shift->_unfake(); return; }

sub _uri_responses {
  my $self = shift;
  $self->{responses_by_uri} = {};
  foreach my $response_file (@_) {
    my $response_yaml;
    try {
      $response_yaml = LoadFile(fake_uri_responses_file($response_file));
    } catch {
      my $err = $_;
      LOGDIE "Unable to load responses file '$response_file': $err";
    };
    $self->{responses_by_uri} = merge($self->{responses_by_uri}, $response_yaml);
  }
  return;
}

# don't send any auth request to google, just use blank headers.
# TODO: see if some other non-G::R routine can be faked so this doesn't have to be
# 'required' in the tests.
sub _fake_http_auth {
  my $self = shift;
  $self->_fake('http_auth', 'Google::RestApi::Auth::OAuth2Client', 'headers', sub { []; });
  return;
}

# TODO: same as above.
sub _fake_http_no_retries {
  my $self = shift;
  $self->_fake('http_no_retries', 'Google::RestApi', 'max_attempts', sub { 1; });
  return;
}

# for the next call to the network, respond appropriately. this is currently
# more flexible than the below uri matching, but requires that you respond
# properly to the uri you're submitting, something a little harder to track
# than the uri matching pattern. you could easily respond to a delete request
# with spreadsheet properties or something, and it won't be obvious unless
# you turn on debug and check. with uri matching, it's all laid out for you:
# when you send this uri, respond with this json... a lot easier. so only
# use this when testing basic stuff like error checking and whatnot.
sub _fake_http_response {
  my $self = shift;
  my $p = validate_named(\@_,
    code     => Int|StrMatch[qr/^die$/], { default => 200 },
    response => Str, { default => '{}' },
    message  => Str, { optional => 1 },
  );

  my %messages = (
    200 => 'OK',
    400 => 'Bad request',
    429 => 'Too many requests',
    500 => 'Server error',
    die => 'Furl died',
  );

  my $code = $p->{code};
  my $response = $p->{response};
  my $message = ($p->{message} || $messages{$code}) or die "Message missing for code $code";

  $response = read_file($response) if -f $response;
  
  my $sub = $code eq 'die' ?
    sub { die $message; }
      :
    sub { Furl::Response->new(1, $code, $message, [], $response); };

  $self->_fake('http_response', 'Furl', 'request', $sub);
  # this allows the tests to check on rest failures without having to wait for retries.
  # sets the right part of retry::backoff to only wait for .1 seconds between retries.
  # otherwise unit tests take ages to run.
  $self->_fake('http_response', 'Algorithm::Backoff::Exponential', '_failure', sub { 0.1; });

  return;
}

# do a series of fake responses if an api call requires more than one transaction sent
# to the network. the last response remains for any further calls. utilize the 'api_callback'
# feature of RestApi to hand in each response in the array.
# TODO: this is probably not needed since we have uri matching below. keeping it for a while.
sub _fake_http_responses {
  my $self = shift;
  my ($api, @responses) = @_;

  my $response = shift @responses;
  if ($response) {
    $self->_fake_http_response(%$response);
    # kinda recursive in a round-about way.
    $api->api_callback( sub { $self->_fake_http_responses($api, @responses); } );
  } else {
    $api->api_callback();
  }

  return;
}

# intercept furl's call to the network and see if the uri and content match something
# that's already been registered previously. see etc/uri_responses.
sub _fake_http_response_by_uri {
  my $self = shift;

  die "No responses registered" if !$self->{responses_by_uri};  

  my $sub = sub {
    my ($furl, $req) = @_;  # $furl is furl's $self.
    my $uri_response = Test::Unit::UriResponse->new(
      request     => $req,
      responses   => $self->{responses_by_uri},
      cell_values => $self->{cell_values},
    );
    my ($response_json, $code, $message) = $uri_response->response();
    return Furl::Response->new(1, $code, $message, [], $response_json);
  };

  $self->_fake('http_response', 'Furl', 'request', $sub);
  $self->_fake('http_response', 'Algorithm::Backoff::Exponential', '_failure', sub { 0.1; });

  return;
}

sub _fake {
  my $self = shift;
  my ($group, $module, $sub, $code) = @_;

  # warn("Faking $group => $module => $sub");
  load($module);   # module must be loaded before you can fake it.

  # if we don't restore this first, things go a bit haywire, like the
  # destructor runs after we do the fake below and resets what we
  # just faked.
  my $fake = $self->{fakes}->{$group}->{$module}->{$sub};
  $fake->restore() if $fake;

  $self->{fakes}->{$group}->{$module}->{$sub} = Mock::MonkeyPatch->patch("${module}::${sub}" => $code);
  # warn("Faked modules after fake:\n" . Dump($self->{fakes}));

  return;
}

# delete the references so the modules get restored.
sub _unfake {
  my $self = shift;
  my ($group) = @_;
  if ($group) {
    delete $self->{fakes}->{$group};
    # warn("Faked modules after unfake:\n" . Dump($self->{fakes}));
  } else {
    delete $self->{fakes};
    # warn("All fakes removed.");
  }
  return;
}

1;
