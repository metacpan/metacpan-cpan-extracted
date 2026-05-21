package Test::Google::RestApi;

use Test::Unit::Setup;

use HTTP::Status qw( :constants );
use Encode qw( encode is_utf8 );

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi';
use aliased 'Google::RestApi::Auth::OAuth2Client';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_suppress_retries { 1; }
sub dont_create_mock_spreadsheets { 1; }

sub startup : Tests(startup) {
  my $self = shift;
  $self->SUPER::startup(@_);
  $self->mock_auth;
  return;
}

sub _constructor : Tests(8) {
  my $self = shift;

  throws_ok sub { RestApi->new(config_file => 'x'); }, qr/did not pass type constraint/i, 'Constructor from bad config file should throw';
  ok my $api = RestApi->new(config_file => mock_config_file()), 'Constructor from proper config_file should succeed';
  isa_ok $api, RestApi, 'Constructor returns';

  # config file with google_restapi key and extra app-level keys should work.
  my $google_restapi_config = _write_temp_config({
    my_app         => { db => 'mydb' },
    google_restapi => {
      auth => {
        class         => 'OAuth2Client',
        client_id     => 'x',
        client_secret => 'x',
        token_file    => mock_token_file(),
      },
    },
  });
  ok $api = RestApi->new(config_file => $google_restapi_config),
    'Constructor with google_restapi key and extra keys should succeed';
  isa_ok $api->auth(), OAuth2Client, 'Auth resolved from google_restapi config';
  ok !exists $api->{my_app}, 'App-level keys outside google_restapi are not passed through';

  # log4perl_config in the config file should be accepted and resolved.
  # Use a quiet config so initializing Log4perl here doesn't spam subsequent tests.
  require FindBin;
  require File::Spec;
  my $log4perl_conf = File::Spec->catfile($FindBin::RealBin, 'etc', 'log4perl_quiet.conf');
  my $log4perl_config = _write_temp_config({
    google_restapi => {
      auth => {
        class         => 'OAuth2Client',
        client_id     => 'x',
        client_secret => 'x',
        token_file    => mock_token_file(),
      },
      log4perl_config => $log4perl_conf,
    },
  });
  ok $api = RestApi->new(config_file => $log4perl_config),
    'Constructor with log4perl_config should succeed';
  ok Log::Log4perl::initialized(), 'Log4perl initialized from log4perl_config';

  return;
}

my @_temp_configs;

sub _write_temp_config {
  my ($data, $dir) = @_;
  require File::Basename;
  require File::Temp;
  require YAML::Any;
  require FindBin;
  require File::Spec;
  $dir //= File::Spec->catdir($FindBin::RealBin, 'etc');
  my $fh = File::Temp->new(SUFFIX => '.yaml', DIR => $dir, UNLINK => 1);
  print $fh YAML::Any::Dump($data);
  $fh->flush();
  push @_temp_configs, $fh;  # keep object alive; deleted at program end
  return $fh->filename();
}

sub auth : Tests(4) {
  my $self = shift;

  my %auth = (
    auth => {
      class         => 'x',
      client_id     => 'x',
      client_secret => 'x',
      token_file    => 'x',
    },
  );

  my $api = RestApi->new(%auth);
  throws_ok sub { $api->auth(); }, qr/you may need to install/i, 'Bad auth class should throw';
  $auth{auth}->{class} = 'OAuth2Client';

  $api = RestApi->new(%auth);
  throws_ok sub { $api->auth() }, qr/unable to resolve/i, 'Bad token file should throw';

  $auth{auth}->{class} = 'OAuth2Client';
  $auth{auth}->{token_file} = mock_token_file();
  $api = RestApi->new(%auth);
  isa_ok $api->auth(), OAuth2Client, 'Proper token file should be found';

  %auth = (
    auth => {
      class        => 'ServiceAccount',
      account_file => 'x',
      scope        => ['x'],
    },
  );

  $api = RestApi->new(%auth);
  throws_ok sub { $api->auth()->account_file() }, qr/unable to resolve/i, 'Bad account file should throw';

  return;
}

# token_file path resolution: absolute paths pass through, bare names resolve
# against the auth config_file's dir first, then the main config_file's dir.
sub auth_token_file_paths : Tests(4) {
  my $self = shift;

  require File::Basename;
  require File::Spec;
  my $token_name = File::Basename::basename(mock_token_file());

  my $main_abs = _write_temp_config({
    auth => {
      class         => 'OAuth2Client',
      client_id     => 'x',
      client_secret => 'x',
      token_file    => mock_token_file(),
    },
  });
  isa_ok RestApi->new(config_file => $main_abs)->auth(), OAuth2Client,
    'Absolute token_file in main YAML resolves';

  my $main_rel = _write_temp_config({
    auth => {
      class         => 'OAuth2Client',
      client_id     => 'x',
      client_secret => 'x',
      token_file    => $token_name,
    },
  });
  isa_ok RestApi->new(config_file => $main_rel)->auth(), OAuth2Client,
    'Relative token_file in main YAML resolves against main config dir';

  # Separate auth config_file in same dir as the token; main config elsewhere.
  # Token must resolve against the auth config_file's dir.
  my $auth_with_token = _write_temp_config({
    client_id     => 'x',
    client_secret => 'x',
    token_file    => $token_name,
  });
  my $main_elsewhere = _write_temp_config({
    auth => { class => 'OAuth2Client', config_file => $auth_with_token },
  }, File::Spec->tmpdir);
  isa_ok RestApi->new(config_file => $main_elsewhere)->auth(), OAuth2Client,
    'Relative token_file resolves against auth config_file dir';

  # Separate auth config_file in a dir that does NOT contain the token; main
  # config in the dir that does. Token must fall back to main config dir.
  my $auth_elsewhere = _write_temp_config({
    client_id     => 'x',
    client_secret => 'x',
    token_file    => $token_name,
  }, File::Spec->tmpdir);
  my $main_with_token = _write_temp_config({
    auth => { class => 'OAuth2Client', config_file => $auth_elsewhere },
  });
  isa_ok RestApi->new(config_file => $main_with_token)->auth(), OAuth2Client,
    'Relative token_file falls back to main config dir when auth dir lacks it';

  return;
}

sub api : Tests(16) {
  my $self = shift;
  
  my %valid_trans = (
    tries            => Int->where('$_ == 1'),
    request          => HashRef,
    response         => InstanceOf['Furl::Response'],
    decoded_response => HashRef,
    error            => 0,
  );
  
  my $api = mock_rest_api();
  throws_ok sub { $api->api(uri => 'x'); }, qr/did not pass type constraint/i, 'Bad uri should throw';

  # this should return '{}' from mock_http_response
  $self->mock_http_response();
  is_valid $api->api(uri => 'https://x'), EmptyHashRef, 'Get HTTP_OK';
  is_valid_n $api->transaction(), %valid_trans, 'Transaction HTTP_OK';
  
  is_valid $api->api(uri => 'https://x', headers => [qw(joe fred)]), EmptyHashRef, 'Get HTTP_OK headers';
  is_valid_n $api->transaction(), %valid_trans, 'Transaction headers HTTP_OK';
  is join(' ', @{ $api->transaction()->{request}->{headers} }), 'joe fred', "Headers are valid"; 

  $api->api(uri => 'https://x', params => { fred => 'joe' });
  is $api->transaction()->{request}->{uri}, 'https://x?fred=joe', 'Build uri using params';
  
  throws_ok sub {
    $api->api(uri => 'https://x', params => { fred => { joe => 'pete' } });
  }, qr/did not pass type constraint/i, 'Bad params should throw';

  # error messages are filled in corresponding to the codes in the mock_http_response subroutine.
  $self->mock_http_response(code => HTTP_BAD_REQUEST);
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Bad request/i, 'Get HTTP_BAD_REQUEST should throw';
  $valid_trans{error} = StrMatch[qr/400 Bad request/i];
  is_valid_n $api->transaction(), %valid_trans, 'Transaction HTTP_BAD_REQUEST';

  $self->mock_http_response(code => HTTP_TOO_MANY_REQUESTS);
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Too many requests/i, 'Get HTTP_TOO_MANY_REQUESTS should throw';
  $valid_trans{error} = StrMatch[qr/429 Too many requests/i];
  $valid_trans{tries} = Int->where('$_ == 4');
  is_valid_n $api->transaction(), %valid_trans, 'Transaction HTTP_TOO_MANY_REQUESTS';

  $self->mock_http_response(code => HTTP_INTERNAL_SERVER_ERROR);
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Server error/i, 'Get HTTP_INTERNAL_SERVER_ERROR should throw';
  $valid_trans{error} = StrMatch[qr/500 Internal server error/i];
  is_valid_n $api->transaction(), %valid_trans, 'Transaction HTTP_INTERNAL_SERVER_ERROR';

  $self->mock_http_response(code => "die");
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Furl died/i, 'Request that dies should throw';
  $valid_trans{response} = 0;
  $valid_trans{decoded_response} = 0;
  $valid_trans{error} = StrMatch[qr/Furl died/i];
  is_valid_n $api->transaction(), %valid_trans, 'Transaction dies';
  
  return;
}

sub api_callback : Tests(8) {
  my $self = shift;

  my $api = mock_rest_api();
  my $trans = 0;

  $api->api_callback( sub { ++$trans; } );

  $self->mock_http_response();
  $api->api(uri => 'https://x');
  is $trans, 1, "Api callback HTTP_OK called";
  
  $self->mock_http_response(code => HTTP_TOO_MANY_REQUESTS);
  eval { $api->api(uri => 'https://x') };
  is $trans, 2, "Api callback HTTP_TOO_MANY_REQUESTS called";

  $self->mock_http_response(code => HTTP_INTERNAL_SERVER_ERROR);
  eval { $api->api(uri => 'https://x') };
  is $trans, 3, "Api callback HTTP_INTERNAL_SERVER_ERROR called";

  $self->mock_http_response(code => "die");
  eval { $api->api(uri => 'https://x'); }; # will throw, don't care.
  is $trans, 4, "Api callback die called";

  $self->mock_http_response();
  $api->api_callback(sub { die 'x'; });
  lives_ok sub { $api->api(uri => 'https://x'); }, "Api callback that dies should allow api to live";
  
  is ref($api->api_callback(sub {})), 'CODE', "New sub returns previous coderef";
  is ref($api->api_callback()), 'CODE', "Empty sub returns second previous coderef";
  is $api->api_callback(), undef, "Second empty sub returns undef";

  return;
}

sub refresh_auth_on_401 : Tests(5) {
  my $self = shift;

  my $api = mock_rest_api();

  # 401 followed by 200: should succeed after one token refresh.
  my $call_count = 0;
  $self->_sub_override('Furl', 'request', sub {
    return Furl::Response->new(1, 401, 'Unauthorized', [], '{}') if ++$call_count == 1;
    return Furl::Response->new(1, 200, 'OK', [], '{}');
  });

  lives_ok sub { $api->api(uri => 'https://x') }, '401 recovered after token refresh';
  is $call_count, 2, 'Request attempted twice after 401';
  is $api->transaction()->{tries}, 2, 'Transaction records 2 tries';

  # Persistent 401: should fail without re-retrying indefinitely.
  $call_count = 0;
  $self->_sub_override('Furl', 'request', sub {
    $call_count++;
    return Furl::Response->new(1, 401, 'Unauthorized', [], '{}');
  });

  throws_ok sub { $api->api(uri => 'https://x') }, qr/Unauthorized/i, 'Persistent 401 still throws';
  is $call_count, 2, 'Request attempted exactly twice for persistent 401';

  return;
}

sub max_attempts : Tests(4) {
  my $self = shift;

  my $api = mock_rest_api();
  is $api->max_attempts(), 4, "Max attempts default is 4";
  is $api->max_attempts(1), 1, "Setting max attempts to 1 is 1";
  is $api->max_attempts(), 1, "Querying max attempts default is still 1";
  is $api->max_attempts(0), 4, "Setting max attempts default is 4";

  return;
}

# Covers: outgoing request header declares UTF-8, request bodies are emitted
# as UTF-8 bytes (not doubly-encoded / not Latin-1), and UTF-8 response bodies
# round-trip back to correctly-flagged Perl strings.
sub utf8_content_type_header : Tests(2) {
  my $self = shift;

  my $captured_req;
  $self->_sub_override('Furl', 'request', sub {
    (undef, $captured_req) = @_;
    return Furl::Response->new(1, 200, 'OK', [], '{}');
  });

  my $api = mock_rest_api();
  $api->api(method => 'post', uri => 'https://x', content => { k => 'v' });

  is $captured_req->header('Content-Type'), 'application/json; charset=utf-8',
    'Content-Type header declares UTF-8 charset';

  # No body, no Content-Type header should be set.
  $api->api(uri => 'https://x');
  is $captured_req->header('Content-Type'), undef,
    'No Content-Type header when there is no request body';

  return;
}

sub utf8_request_body_encodes : Tests(3) {
  my $self = shift;

  my $captured_req;
  $self->_sub_override('Furl', 'request', sub {
    (undef, $captured_req) = @_;
    return Furl::Response->new(1, 200, 'OK', [], '{}');
  });

  my $api = mock_rest_api();
  my $input = "caf\x{e9} \x{65e5}\x{672c}\x{8a9e} \x{1f3b5}";  # café 日本語 🎵
  $api->api(method => 'post', uri => 'https://x', content => { title => $input });

  my $body = $captured_req->content();
  ok !is_utf8($body), 'Request body is bytes (utf8 flag off)';

  # The body should contain the input re-encoded as UTF-8 bytes. Decoding them
  # back yields the original characters.
  my $decoded_body = eval { Encode::decode('UTF-8', $body, Encode::FB_CROAK) };
  ok !$@, 'Request body decodes as valid UTF-8';
  like $decoded_body, qr/\Q$input\E/,
    'Request body preserves non-ASCII characters (caf\x{e9} 日本語 🎵)';

  return;
}

sub utf8_response_decodes : Tests(4) {
  my $self = shift;

  my $expected = "caf\x{e9} \x{65e5}\x{672c}\x{8a9e} \x{1f3b5}";  # café 日本語 🎵
  my $json_text = qq({"title":"$expected","count":3});
  my $body_bytes = encode('UTF-8', $json_text);

  $self->_sub_override('Furl', 'request', sub {
    return Furl::Response->new(
      1, 200, 'OK',
      ['Content-Type' => 'application/json; charset=utf-8'],
      $body_bytes,
    );
  });

  my $api = mock_rest_api();
  my $got = $api->api(uri => 'https://x');

  is $got->{title}, $expected, 'Non-ASCII response value decodes to original characters';
  ok is_utf8($got->{title}), 'Decoded response string has utf8 flag set';
  is length($got->{title}), length($expected),
    'Decoded string length is in characters, not bytes';
  is $got->{count}, 3, 'ASCII fields alongside non-ASCII also decode correctly';

  return;
}

sub utf8_roundtrip_mixed_scripts : Tests(2) {
  my $self = shift;

  # Latin-1 diacritics, CJK, RTL (Hebrew + Arabic), and a 4-byte emoji.
  my %sent = (
    latin  => "caf\x{e9} na\x{ef}ve r\x{e9}sum\x{e9}",
    cjk    => "\x{65e5}\x{672c}\x{8a9e} \x{4e2d}\x{6587}",
    rtl    => "\x{5e9}\x{5dc}\x{5d5}\x{5dd} \x{645}\x{631}\x{62d}\x{628}\x{627}",
    emoji  => "\x{1f3b5}\x{1f3a7}\x{1f4fb}",
    ascii  => "plain",
  );

  my $captured_req;
  $self->_sub_override('Furl', 'request', sub {
    (undef, $captured_req) = @_;
    # Echo the request body back as the response, simulating a server that
    # preserves what we sent.
    my $bytes = $captured_req->content();
    return Furl::Response->new(
      1, 200, 'OK',
      ['Content-Type' => 'application/json; charset=utf-8'],
      $bytes,
    );
  });

  my $api = mock_rest_api();
  my $got = $api->api(method => 'post', uri => 'https://x', content => \%sent);

  is_deeply $got, \%sent, 'Mixed-script structure round-trips unchanged';
  ok is_utf8($got->{cjk}), 'Returned CJK string has utf8 flag set';

  return;
}

1;
