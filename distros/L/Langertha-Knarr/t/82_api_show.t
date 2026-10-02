use strict;
use warnings;
use Test2::V0;

# k29: VS Code Copilot (BYOK Ollama) calls POST /api/show for every model
# from /api/tags and fails without it; it reads tools/vision from
# `capabilities` and the context window from
# model_info["<general.architecture>.context_length"]. Continue reads it too.
# The answer must be honest: "tools" only when the routed engine can take
# tools, never "thinking" (Knarr drops think on the Ollama wire), "vision"
# only when the routed engine claims core's model-scoped image_input for the
# upstream model (k32; a core without that flag, 0.503, gets no vision and
# no croak), and a context length only when the engine knows one. A model Knarr does not list gets Ollama's own
# 404 {"error":"model 'x' not found"}. Native server and PSGI must answer
# the same, so every case below runs against both.

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}

BEGIN {
  # A real Langertha engine that knows its context size, as an Ollama
  # engine configured with context_size does.
  package LangerthaX::Engine::TestShowContext;
  use Moose;
  extends 'Langertha::Engine::Ollama';
  has '+context_size' => ( default => 32768 );
  __PACKAGE__->meta->make_immutable;
  $INC{'LangerthaX/Engine/TestShowContext.pm'} = __FILE__;
}

use Plack::Test;
use HTTP::Request;
use IO::Async::Loop;
use Net::Async::HTTP;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::PSGI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

delete $ENV{KNARR_TEST_SHOW_UNSET_KEY};

# k32: vision follows the core flag. Without Langertha::Role::ImageInput the
# installed core cannot tell, so no model claims it.
my $core_vision = eval { require Langertha::Role::ImageInput; 1 } ? 1 : 0;
my @vision = $core_vision ? ('vision') : ();
note $core_vision ? 'core knows image_input' : 'core has no image_input: no vision anywhere';

my $config = Langertha::Knarr::Config->new( data => {
  models => {
    'gpt-alias' => { engine => 'OpenAI', model => 'gpt-5.6', api_key => 'sk-test' },
    # k32: the same engine class answers per upstream model (ADR 0019):
    # Claude 3+ sees images, the pre-3 generation does not.
    'claude'    => { engine => 'Anthropic', model => 'claude-opus-4-1', api_key => 'sk-test' },
    'claude-2'  => { engine => 'Anthropic', model => 'claude-2.1', api_key => 'sk-test' },
    'hermes'    => { engine => 'NousResearch', model => 'Hermes-4-70B', api_key => 'sk-test' },
    'lmstudio'  => { engine => 'LMStudio', model => 'qwen3', url => 'http://127.0.0.1:1' },
    'ctx'       => { engine => 'TestShowContext', model => 'llama3', url => 'http://127.0.0.1:1' },
    # k30: the operator's context_size reaches the engine, so /api/show
    # reports the configured window, not an engine default.
    'ctx-conf'  => { engine => 'Ollama', model => 'llama3', url => 'http://127.0.0.1:1',
                     context_size => 8192 },
    'nokey'     => { engine => 'OpenAI', model => 'gpt-5.6', api_key_env => 'KNARR_TEST_SHOW_UNSET_KEY' },
  },
  # Chat would send an unlisted model here; /api/show must not claim it.
  default => { engine => 'OpenAI', api_key => 'sk-test' },
} );
my $router = Langertha::Knarr::Router->new( config => $config );

sub routed_knarr {
  Langertha::Knarr->new(
    handler => Langertha::Knarr::Handler::Router->new( router => $router ),
    router  => $router,
    loop    => $loop, listen => ['127.0.0.1:0'], @_,
  );
}

sub both {
  my ($knarr, $body, @headers) = @_;
  $knarr->start;
  my $port = $knarr->_server->read_handle->sockport;
  my @h = ( 'Content-Type' => 'application/json', @headers );
  my $native = $http->do_request( request =>
    HTTP::Request->new( POST => "http://127.0.0.1:$port/api/show", \@h, $body ) )->get;
  my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app )
    ->request( HTTP::Request->new( POST => 'http://localhost/api/show', \@h, $body ) );
  return ( native => $native, psgi => $psgi );
}

sub decoded {
  my ($res) = @_;
  my $data = $json->decode( $res->decoded_content );
  delete $data->{modified_at};
  return $data;
}

my $empty_details = {
  parent_model => '', format => '', family => '', families => [],
  parameter_size => '', quantization_level => '',
};

# One table, both transports.
my @cases = (
  [ 'native tools engine, vision model', routed_knarr(), '{"model":"gpt-alias"}', 200,
    { capabilities => [ 'completion', 'tools', @vision ], model_info => {} } ],
  [ 'vision model of a family', routed_knarr(), '{"model":"claude"}', 200,
    { capabilities => [ 'completion', 'tools', @vision ], model_info => {} } ],
  [ 'text-only model of the same family', routed_knarr(), '{"model":"claude-2"}', 200,
    { capabilities => [ 'completion', 'tools' ], model_info => {} } ],
  [ 'hermes tools count as tools', routed_knarr(), '{"model":"hermes"}', 200,
    { capabilities => [ 'completion', 'tools' ], model_info => {} } ],
  [ 'engine without tools', routed_knarr(), '{"model":"lmstudio"}', 200,
    { capabilities => ['completion'], model_info => {} } ],
  [ 'context length when the engine knows it', routed_knarr(), '{"model":"ctx"}', 200,
    { capabilities => [ 'completion', 'tools' ],
      model_info => { 'general.architecture' => 'knarr', 'knarr.context_length' => 32768 } } ],
  [ 'configured context_size', routed_knarr(), '{"model":"ctx-conf"}', 200,
    { capabilities => [ 'completion', 'tools' ],
      model_info => { 'general.architecture' => 'knarr', 'knarr.context_length' => 8192 } } ],
  [ 'legacy name field', routed_knarr(), '{"name":"lmstudio"}', 200,
    { capabilities => ['completion'], model_info => {} } ],
  [ 'listed but unbuildable engine keeps the forwarded baseline', routed_knarr(),
    '{"model":"nokey"}', 200,
    { capabilities => [ 'completion', 'tools' ], model_info => {} } ],
  [ 'custom handler without router', Langertha::Knarr->new(
      handler => Langertha::Knarr::Handler::Code->new( code => sub { 'x' },
        models => [ { id => 'fake-model' } ] ),
      loop => $loop, listen => ['127.0.0.1:0'] ),
    '{"model":"fake-model"}', 200,
    { capabilities => [ 'completion', 'tools' ], model_info => {} } ],
  [ 'unknown model', routed_knarr(), '{"model":"no-such-model"}', 404,
    { error => "model 'no-such-model' not found" } ],
  [ 'not routed to the default engine', routed_knarr(), '{"model":"gpt-6-astra"}', 404,
    { error => "model 'gpt-6-astra' not found" } ],
  [ 'no model', routed_knarr(), '{}', 400, { error => 'model is required' } ],
  [ 'empty body', routed_knarr(), '', 400, { error => 'model is required' } ],
);

for my $case (@cases) {
  my ($name, $knarr, $body, $status, $expect) = @$case;
  my %r = both( $knarr, $body );
  for my $t (qw( native psgi )) {
    is( $r{$t}->code, $status, "$t: $name: $status" );
    like( $r{$t}->header('Content-Type'), qr{\Aapplication/json}, "$t: $name: JSON" );
    my $got = decoded( $r{$t} );
    if ( $status == 200 ) {
      is( $got, { details => $empty_details, template => '', parameters => '', license => '',
        %$expect }, "$t: $name: body" );
      ok( !( grep { $_ eq 'thinking' } @{ $got->{capabilities} } ),
        "$t: $name: never thinking" );
      like( $json->decode( $r{$t}->decoded_content )->{modified_at},
        qr/\A\d{4}-\d\d-\d\dT/, "$t: $name: modified_at" );
    }
    else {
      is( $got, $expect, "$t: $name: Ollama error shape" );
    }
  }
  is( decoded( $r{psgi} ), decoded( $r{native} ), "$name: same body on both transports" );
}

# Ollama registers /api/show for POST only.
{
  my $knarr = routed_knarr();
  $knarr->start;
  my $port = $knarr->_server->read_handle->sockport;
  my $native = $http->do_request( request =>
    HTTP::Request->new( GET => "http://127.0.0.1:$port/api/show" ) )->get;
  my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app )
    ->request( HTTP::Request->new( GET => 'http://localhost/api/show' ) );
  is( $native->code, 404, 'native: GET /api/show has no route' );
  is( $psgi->code, 404, 'psgi: GET /api/show has no route' );
}

# Behind auth_token like every model route.
{
  my %denied = both( routed_knarr( auth_token => 's3cret' ), '{"model":"gpt-alias"}' );
  is( $denied{$_}->code, 401, "$_: /api/show needs the key" ) for qw( native psgi );
  my %ok = both( routed_knarr( auth_token => 's3cret' ), '{"model":"gpt-alias"}',
    'x-api-key' => 's3cret' );
  is( $ok{$_}->code, 200, "$_: /api/show with the key" ) for qw( native psgi );
}

done_testing;
