use strict;
use warnings;
use Test2::V0;

# Regression (k27): GET /api/version was in the Ollama route table but had
# no action behind it, so both servers answered 500 after auth. Ollama
# clients probe it first (and some gate features on the version), so it
# must answer Ollama's shape {"version":"x.y.z"} with the Ollama version
# Knarr claims compatibility with -- never Knarr's own version, which an
# Ollama client would misread (Knarr 1.x > any Ollama 0.x). Both
# transports, default and configured version, and the route stays behind
# auth_token like the other model routes. The default is the current Ollama
# release (k28) and the value is digits and dots only (Open WebUI).

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use IO::Async::Loop;
use Net::Async::HTTP;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::PSGI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);
my $handler = Langertha::Knarr::Handler::Code->new( code => sub { 'x' } );

sub both {
  my ($knarr, @headers) = @_;
  $knarr->start;
  my $port = $knarr->_server->read_handle->sockport;
  my $native = $http->do_request( request =>
    HTTP::Request->new( GET => "http://127.0.0.1:$port/api/version", \@headers ) )->get;
  my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app )
    ->request( HTTP::Request->new( GET => 'http://localhost/api/version', \@headers ) );
  return ( native => $native, psgi => $psgi );
}

sub knarr { Langertha::Knarr->new( handler => $handler, loop => $loop, listen => ['127.0.0.1:0'], @_ ) }

{
  my %r = both( knarr() );
  for my $t (qw( native psgi )) {
    is( $r{$t}->code, 200, "$t: /api/version answers 200" );
    like( $r{$t}->header('Content-Type'), qr{\Aapplication/json}, "$t: JSON" );
    is( $json->decode( $r{$t}->decoded_content ), { version => '0.34.4' },
      "$t: Ollama shape with the default compat version" );
  }
  is( $r{psgi}->decoded_content, $r{native}->decoded_content, 'same body on both transports' );
  isnt( $json->decode( $r{native}->decoded_content )->{version}, $Langertha::Knarr::VERSION,
    'not knarr\'s own version' );
}

{
  my %r = both( knarr( ollama_compat_version => '0.13.1' ) );
  is( $json->decode( $r{$_}->decoded_content ), { version => '0.13.1' },
    "$_: configured compat version" ) for qw( native psgi );
}

{
  my @auth = ( auth_token => 's3cret' );
  my %denied = both( knarr(@auth) );
  is( $denied{$_}->code, 401, "$_: /api/version needs the key when auth_token is set" )
    for qw( native psgi );
  my %ok = both( knarr(@auth), Authorization => 'Bearer s3cret' );
  is( $ok{$_}->code, 200, "$_: /api/version with the key" ) for qw( native psgi );
}

{
  my $config = Langertha::Knarr::Config->new( data => { ollama_compat_version => '0.12.9' } );
  is( $config->ollama_compat_version, '0.12.9', 'Config reads ollama_compat_version' );
  local $ENV{KNARR_OLLAMA_COMPAT_VERSION} = '0.11.0';
  is( Langertha::Knarr::Config->new( data => {} )->ollama_compat_version, '0.11.0',
    'Config falls back to KNARR_OLLAMA_COMPAT_VERSION' );
  delete local $ENV{KNARR_OLLAMA_COMPAT_VERSION};
  is( Langertha::Knarr::Config->new( data => {} )->ollama_compat_version, undef,
    'unset means Knarr\'s default applies' );
}

# k28: the value must be digits and dots only. Open WebUI int()s every
# dotted part of /api/version, so a suffix or a "v" would break its
# connection check; refuse it when the config is loaded, not per request.
for my $bad ( '0.34.4-knarr', 'v0.34.4', '0.34', '0.34.4.1', '0.34.x', '' ) {
  like( dies { knarr( ollama_compat_version => $bad ) },
    qr/three dot-separated numbers/, "Knarr refuses compat version '$bad'" );
  my $config = Langertha::Knarr::Config->new( data => {
    models => { m => { engine => 'OpenAI' } }, ollama_compat_version => $bad } );
  like( dies { $config->ollama_compat_version },
    qr/three dot-separated numbers/, "Config croaks on '$bad'" );
  is( [ grep { /ollama_compat_version/ } $config->validate ], [ match qr/three dot-separated/ ],
    "validate reports '$bad'" );
}
{
  local $ENV{KNARR_OLLAMA_COMPAT_VERSION} = '0.34.4+knarr';
  like( dies { Langertha::Knarr::Config->new( data => {} )->ollama_compat_version },
    qr/three dot-separated numbers/, 'the env value is checked too' );
}
is( [ Langertha::Knarr::Config->new( data => {
  models => { m => { engine => 'OpenAI' } }, ollama_compat_version => '0.6.4' } )->validate ],
  [], 'a valid compat version passes validate' );

done_testing;
