use strict;
use warnings;
use Test2::V0;

# Regression (k80), on top of k78/k79: a sync error of ACP and AG-UI reached
# the client in the OpenAI wire's {"error":{"message":...}}, and an A2A error
# answered with id null although the request's id was known (the 401 comes
# before the body is parsed, a handler failure was answered without the
# parsed request). Now:
#  - ACP: its Error object {code, message} (code server_error / not_found /
#    invalid_input), top level, as in the ACP specification;
#  - AG-UI: the RUN_ERROR event {type, message, code} as the JSON body;
#  - A2A: the JSON-RPC error with the request's id wherever it can be read,
#    id null (JSON-RPC 2.0) for a body that is not JSON, then -32700 Parse
#    error with status 400.
# Natively and under PSGI.

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
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Stream;

my $loop = IO::Async::Loop->new;

{
  package IdHandler;
  use Moose;
  use Future;
  with 'Langertha::Knarr::Handler';

  sub handle_chat_f {
    my ($self, $session, $request) = @_;
    return Future->fail("backend exploded\n") if $request->messages->[-1]{content} eq 'die';
    return Future->fail( "no such model\n", 'model_not_found' ) if $request->messages->[-1]{content} eq 'missing';
    return Future->done( Langertha::Knarr::Response->new( content => 'fine', model => 'm' ) );
  }

  sub handle_stream_f {
    my ($self, $session, $request) = @_;
    return Future->fail("backend refused\n") if $request->messages->[-1]{content} eq 'die';
    return Future->fail( "no such model\n", 'model_not_found' ) if $request->messages->[-1]{content} eq 'missing';
    return Future->done( Langertha::Knarr::Stream->from_list('fine') );
  }

  sub list_models { [ { id => 'x', object => 'model' } ] }
  __PACKAGE__->meta->make_immutable;
}

my $json   = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $secret = 'sekrit-proxy-key';
my $knarr  = Langertha::Knarr->new(
  handler    => IdHandler->new,
  loop       => $loop,
  listen     => [ '127.0.0.1:0' ],
  auth_token => $secret,
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

sub post {
  my ($transport, $path, $content, $authed) = @_;
  my @h = ( 'Content-Type' => 'application/json', ( $authed ? ( Authorization => "Bearer $secret" ) : () ) );
  return $transport eq 'native'
    ? $http->do_request( request => HTTP::Request->new(
        POST => "http://127.0.0.1:$port$path", \@h, $content ), timeout => 10 )->get
    : $psgi->request( HTTP::Request->new( POST => "http://localhost$path", \@h, $content ) );
}

sub decoded { my ($resp) = @_; my $d = eval { $json->decode( $resp->content ) }; return $d // $resp->content }

sub acp_body {
  my ($text) = @_;
  $json->encode({ agent_name => 'x', mode => 'sync',
    input => [ { parts => [ { content_type => 'text/plain', content => $text } ] } ] });
}
sub agui_body {
  my ($text) = @_;
  $json->encode({ threadId => 't', runId => 'r', model => 'x', messages => [ { role => 'user', content => $text } ] });
}
sub a2a_body {
  my ($text, $stream) = @_;
  $json->encode({ jsonrpc => '2.0', id => 'rpc-7', method => $stream ? 'tasks/sendSubscribe' : 'tasks/send',
    params => { id => 'task-1', message => { parts => [ { type => 'text', text => $text } ] } } });
}

sub rpc_error {
  my ($id, $code, $status, $re) = @_;
  return hash {
    field jsonrpc => '2.0';
    field id      => $id;
    field error   => hash { field code => $code; field message => match $re; field data => { status => $status }; end };
    end;
  };
}

for my $transport (qw( native psgi )) {
  # ACP
  my $resp = post( $transport, '/runs', acp_body('x') );
  is( $resp->code, 401, "$transport acp 401" );
  is( decoded($resp), { code => 'invalid_input', message => 'unauthorized' }, "$transport acp 401: ACP's Error object" );

  $resp = post( $transport, '/runs', acp_body('die'), 1 );
  is( $resp->code, 500, "$transport acp failure: 500" );
  is( decoded($resp), { code => 'server_error', message => 'backend exploded' }, "$transport acp failure: ACP's Error object" );

  $resp = post( $transport, '/runs', acp_body('missing'), 1 );
  is( $resp->code, 404, "$transport acp unknown model: 404" );
  is( decoded($resp), { code => 'not_found', message => 'no such model' }, "$transport acp unknown model: not_found" );

  # AG-UI
  $resp = post( $transport, '/awp', agui_body('x') );
  is( $resp->code, 401, "$transport agui 401" );
  is( decoded($resp), { type => 'RUN_ERROR', code => 'invalid_input', message => 'unauthorized' }, "$transport agui 401: RUN_ERROR" );

  $resp = post( $transport, '/awp', agui_body('die'), 1 );
  is( $resp->code, 500, "$transport agui failure: 500" );
  is( decoded($resp), { type => 'RUN_ERROR', code => 'server_error', message => 'backend refused' }, "$transport agui failure: RUN_ERROR" );

  # A2A: the request's id
  $resp = post( $transport, '/', a2a_body('x') );
  is( $resp->code, 401, "$transport a2a 401" );
  is( decoded($resp), rpc_error( 'rpc-7', -32600, 401, qr/\Aunauthorized\z/ ), "$transport a2a 401: the request's id" );

  $resp = post( $transport, '/', a2a_body('die'), 1 );
  is( $resp->code, 500, "$transport a2a failure: 500" );
  is( decoded($resp), rpc_error( 'rpc-7', -32603, 500, qr/\Abackend exploded\z/ ), "$transport a2a failure: the request's id" );

  $resp = post( $transport, '/', a2a_body('die', 1), 1 );
  is( $resp->code, 500, "$transport a2a stream failure: 500" );
  is( decoded($resp), rpc_error( 'rpc-7', -32603, 500, qr/\Abackend refused\z/ ), "$transport a2a stream failure: the request's id" );

  # A2A: no readable request, id null (JSON-RPC 2.0: Parse error / Invalid Request)
  $resp = post( $transport, '/', '{"jsonrpc":"2.0","id":9,', 1 );
  is( $resp->code, 400, "$transport a2a unparseable body: 400" );
  is( decoded($resp), rpc_error( undef, -32700, 400, qr/\AParse error\z/ ), "$transport a2a unparseable body: Parse error, id null" );

  $resp = post( $transport, '/', '{"jsonrpc":"2.0","id":9,', 0 );
  is( $resp->code, 401, "$transport a2a 401 with unparseable body" );
  is( decoded($resp), rpc_error( undef, -32600, 401, qr/\Aunauthorized\z/ ), "$transport a2a 401 with unparseable body: id null" );
}

done_testing;
