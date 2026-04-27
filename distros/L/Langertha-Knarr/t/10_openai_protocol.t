use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Protocol::OpenAI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my $handler = Langertha::Knarr::Handler::Code->new(
  code => sub {
    my ($session, $request) = @_;
    my $last = $request->messages->[-1] // {};
    return "echo: " . ( $last->{content} // '' );
  },
);

my $sb = Langertha::Knarr->new(
  handler => $handler,
  port    => 0,
);

my $proto = Langertha::Knarr::Protocol::OpenAI->new;

# Routes registered
my $routes = $proto->protocol_routes;
ok( ( grep { $_->{path} eq '/v1/chat/completions' } @$routes ), 'chat route registered' );
ok( ( grep { $_->{path} eq '/v1/models' } @$routes ), 'models route registered' );

# parse_chat_request
my $body = $json->encode({
  model    => 'test-model',
  messages => [ { role => 'user', content => 'hello' } ],
  stream   => JSON::MaybeXS::false(),
});

# Minimal fake HTTP request: only ->header used by parse_chat_request
my $fake_http = bless { headers => {} }, 'TestFakeReq';
sub TestFakeReq::header { return undef }

my $req = $proto->parse_chat_request( $fake_http, \$body );
isa_ok( $req, ['Langertha::Knarr::Request'] );
is( $req->model, 'test-model', 'model parsed' );
is( $req->stream, 0, 'stream false' );
is( scalar @{ $req->messages }, 1, 'one message' );

# Run handler
my $session = $sb->session;
my $f = $handler->handle_chat_f( $session, $req );
my $response = $f->get;
is( $response->content, 'echo: hello', 'handler echoed' );

# Format response
my ($status, $headers, $out) = $proto->format_chat_response( $response, $req );
is( $status, 200, 'status 200' );
my $decoded = $json->decode($out);
is( $decoded->{object}, 'chat.completion', 'object type' );
is( $decoded->{choices}[0]{message}{content}, 'echo: hello', 'content in choices' );

# /v1/models
my $models = $handler->list_models;
my ($mstatus, $mheaders, $mbody) = $proto->format_models_response($models);
is( $mstatus, 200, 'models 200' );
my $mdec = $json->decode($mbody);
is( $mdec->{object}, 'list', 'models list' );
ok( scalar @{ $mdec->{data} } >= 1, 'has models' );

# Streaming chunk format
my $chunk = $proto->format_stream_chunk( 'hi', $req );
like( $chunk, qr/^data: \{.*\}\n\n$/s, 'SSE chunk format' );

done_testing;
