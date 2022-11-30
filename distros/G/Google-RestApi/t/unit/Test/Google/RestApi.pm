package Test::Google::RestApi;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi';
use aliased 'Google::RestApi::Auth::OAuth2Client';

use parent 'Test::Unit::TestBase';

# init_logger($DEBUG);

sub _constructor : Tests(3) {
  my $self = shift;

  throws_ok sub { RestApi->new(config_file => 'x'); }, qr/did not pass type constraint/i, 'Constructor from bad config file should throw';
  ok my $api = RestApi->new(config_file => fake_config_file()), 'Constructor from proper config_file should succeed';
  isa_ok $api, RestApi, 'Constructor returns';

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
  
  $self->_fake_http_auth();

  my $api = fake_rest_api();
  throws_ok sub { $api->api(uri => 'x'); }, qr/did not pass type constraint/i, 'Bad uri should throw';

  # this should return '{}' from fake_http_response
  $self->_fake_http_response();
  is_valid $api->api(uri => 'https://x'), EmptyHashRef, 'Get 200';
  is_valid_n $api->transaction(), %valid_trans, 'Transaction 200';
  
  is_valid $api->api(uri => 'https://x', headers => [qw(joe fred)]), EmptyHashRef, 'Get 200 headers';
  is_valid_n $api->transaction(), %valid_trans, 'Transaction headers 200';
  is join(' ', @{ $api->transaction()->{request}->{headers} }), 'joe fred', "Headers are valid"; 

  $api->api(uri => 'https://x', params => { fred => 'joe' });
  is $api->transaction()->{request}->{uri}, 'https://x?fred=joe', 'Build uri using params';
  
  throws_ok sub {
    $api->api(uri => 'https://x', params => { fred => { joe => 'pete' } });
  }, qr/did not pass type constraint/i, 'Bad params should throw';

  # error messages are filled in corresponding to the codes in the _fake_http_response subroutine.
  $self->_fake_http_response(code => 400);
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Bad request/i, 'Get 400 should throw';
  $valid_trans{error} = StrMatch[qr/400 Bad request/i];
  is_valid_n $api->transaction(), %valid_trans, 'Transaction 400';

  $self->_fake_http_response(code => 429);
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Too many requests/i, 'Get 429 should throw';
  $valid_trans{error} = StrMatch[qr/429 Too many requests/i];
  $valid_trans{tries} = Int->where('$_ == 4');
  is_valid_n $api->transaction(), %valid_trans, 'Transaction 429';

  $self->_fake_http_response(code => 500);
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Server error/i, 'Get 500 should throw';
  $valid_trans{error} = StrMatch[qr/500 Server error/i];
  is_valid_n $api->transaction(), %valid_trans, 'Transaction 500';

  $self->_fake_http_response(code => "die");
  throws_ok sub { $api->api(uri => 'https://x') }, qr/Furl died/i, 'Request that dies should throw';
  $valid_trans{response} = 0;
  $valid_trans{decoded_response} = 0;
  $valid_trans{error} = StrMatch[qr/Furl died/i];
  is_valid_n $api->transaction(), %valid_trans, 'Transaction dies';
  
  return;
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
  $auth{auth}->{token_file} = fake_token_file();
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

sub api_callback : Tests(8) {
  my $self = shift;

  $self->_fake_http_auth();
  my $api = fake_rest_api();
  my $trans = 0;

  $api->api_callback( sub { ++$trans; } );

  $self->_fake_http_response();
  $api->api(uri => 'https://x');
  is $trans, 1, "Api callback 200 called";
  
  $self->_fake_http_response(code => 429);
  eval { $api->api(uri => 'https://x') };
  is $trans, 2, "Api callback 429 called";

  $self->_fake_http_response(code => 500);
  eval { $api->api(uri => 'https://x') };
  is $trans, 3, "Api callback 500 called";

  $self->_fake_http_response(code => "die");
  eval { $api->api(uri => 'https://x'); }; # will throw, don't care.
  is $trans, 4, "Api callback die called";

  $self->_fake_http_response();
  $api->api_callback(sub { die 'x'; });
  lives_ok sub { $api->api(uri => 'https://x'); }, "Api callback that dies should allow api to live";
  
  is ref($api->api_callback(sub {})), 'CODE', "New sub returns previous coderef";
  is ref($api->api_callback()), 'CODE', "Empty sub returns second previous coderef";
  is $api->api_callback(), undef, "Second empty sub returns undef";

  return;
}

sub max_attempts : Tests(4) {
  my $self = shift;

  my $api = fake_rest_api();
  is $api->max_attempts(), 4, "Max attempts default is 4";
  is $api->max_attempts(1), 1, "Setting max attempts to 1 is 1";
  is $api->max_attempts(), 1, "Querying max attempts default is still 1";
  is $api->max_attempts(0), 4, "Setting max attempts default is 4";
  
  return;
}

1;
