#!/usr/bin/env perl
# ABSTRACT: Server-side tools on the Responses wire -- request bodies, replies, the tool loop

use strict;
use warnings;
use lib 't/lib';
use Test2::Bundle::More;
use Future;
use HTTP::Response;
use JSON::MaybeXS;
use Path::Tiny qw( path );
use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;
use Langertha::ServerTool;
use Langertha::ToolCall;
use Test::MockAsyncHTTP;

# Why (karr k206, ADR 0030): OpenAI's hosted tools (web_search, file_search,
# remote mcp, ...) run at the provider during one request. Langertha must
#   - send them as the provider-native entries in `tools`, next to function
#     tools, per request and as engine defaults (server_tools);
#   - keep what the provider did off Response.tool_calls -- that list means
#     "calls the client must execute" (ADR 0003), and chat_with_tools_f would
#     die "Tool 'web_search' not found" on a server call -- and record it on
#     Response.server_tool_calls instead;
#   - lift the answer's url_citation annotations onto Response.citations;
#   - fail loud on an output item the client must answer but Langertha cannot
#     (mcp_approval_request, computer_call, ...), because otherwise a tool loop
#     ends as if the model were done;
#   - refuse a remote mcp tool without require_approval => 'never' (OpenAI
#     defaults to "always", and there is no approval flow).
# The replies are the verbatim OpenAI captures in t/data (gpt-5.6-luna,
# 2026-09-25, k206); the .request.json next to each is the body that produced
# it, so the request tests assert Langertha builds that body.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);
my $data = path(__FILE__)->parent->child('data');
sub capture_bytes { $data->child( $_[0] . '.json' )->slurp_raw }
sub capture       { $json->decode( capture_bytes( $_[0] ) ) }
sub capture_req   { $json->decode( $data->child( $_[0] . '.request.json' )->slurp_raw ) }

sub http_ok {
  my ($bytes) = @_;
  my $res = HTTP::Response->new( 200, 'OK' );
  $res->header( 'Content-Type' => 'application/json' );
  $res->content($bytes);
  return $res;
}

sub engine {
  return Langertha::Engine::OpenAIResponses->new(
    api_key          => 'k',
    model            => 'gpt-5.6-luna',
    response_size    => 2000,
    reasoning_effort => 'low',
    @_,
  );
}

sub body_of {
  my ($req) = @_;
  my $body = $json->decode( $req->content );
  # The non-streaming builder always states stream => false (a JSON boolean);
  # the captures left it out, which is the same on the wire.
  my $stream = delete $body->{stream};
  ok( JSON::MaybeXS::is_bool($stream) && !$stream, 'the body says stream => false' );
  return $body;
}

# The captures sent `input` as a bare string; Langertha always sends the
# equivalent one-item message list. Everything else must match byte for byte.
sub as_langertha_input {
  my ($want) = @_;
  $want->{input} = [ { role => 'user', content => $want->{input} } ] unless ref $want->{input};
  return $want;
}

my $prompt_1 = capture_req('responses_web_search')->{input};
my $prompt_2 = capture_req('responses_web_search_function_call')->{input};
my $get_weather = capture_req('responses_web_search_function_call')->{tools}[1];

subtest 'capability: server_tools on OpenAIResponses only' => sub {
  ok( engine()->supports('server_tools'), 'OpenAIResponses supports server_tools' );
  ok( engine()->does('Langertha::Role::ServerTools'), 'via Role::ServerTools' );
  ok( !Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6-luna' )->supports('server_tools'),
    'the chat/completions engine does not' );
};

subtest 'manifest: the model entry claims server_tools (ADR 0029)' => sub {
  require Langertha::Manifest::Builder;
  my $m = Langertha::Manifest::Builder->from_engine( engine() );
  ok( $m->models->[0]->supports('server_tools'), 'OpenAIResponses model claims server_tools' );
  my $chat = Langertha::Manifest::Builder->from_engine(
    Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6-luna' ) );
  ok( !$chat->models->[0]->supports('server_tools'), 'the chat/completions model does not' );
};

subtest 'capture #1: web_search per request, the exact body' => sub {
  my $req = engine()->chat_request( [ { role => 'user', content => $prompt_1 } ],
    tools => [ { type => 'web_search' } ], include => ['web_search_call.action.sources'] );
  is_deeply( body_of($req), as_langertha_input( capture_req('responses_web_search') ), 'body matches the capture' );

  my $obj = engine()->chat_request( [ { role => 'user', content => $prompt_1 } ],
    tools => [ Langertha::ServerTool->new( wire => 'responses', spec => { type => 'web_search' } ) ],
    include => ['web_search_call.action.sources'] );
  is_deeply( body_of($obj), body_of($req), 'a ServerTool object builds the same body' );
};

subtest 'capture #1: web_search as the engine default' => sub {
  my $req = engine( server_tools => [ { type => 'web_search' } ] )
    ->chat_request( [ { role => 'user', content => $prompt_1 } ], include => ['web_search_call.action.sources'] );
  is_deeply( body_of($req), as_langertha_input( capture_req('responses_web_search') ),
    'server_tools reach a request that has no tools of its own' );
};

subtest 'capture #2: web_search + function tool, the exact body' => sub {
  my $req = engine()->chat_request( [ { role => 'user', content => $prompt_2 } ],
    tools => [ { type => 'web_search' }, $get_weather ] );
  is_deeply( body_of($req), as_langertha_input( capture_req('responses_web_search_function_call') ),
    'body matches the capture' );

  my $mixed = engine( server_tools => [ { type => 'web_search' } ] )
    ->chat_request( [ { role => 'user', content => $prompt_2 } ], tools => [$get_weather] );
  is_deeply( body_of($mixed)->{tools}, [ $get_weather, { type => 'web_search' } ],
    'engine server_tools are appended after the request tools' );
};

subtest 'the stream request builder takes them too' => sub {
  my $req = engine( server_tools => [ { type => 'web_search' } ] )
    ->chat_stream_request( [ { role => 'user', content => 'x' } ], tools => [$get_weather] );
  is_deeply( $json->decode( $req->content )->{tools}, [ $get_weather, { type => 'web_search' } ],
    'server_tools appended on chat_stream_request' );
};

subtest 'remote MCP needs require_approval => never on OpenAI' => sub {
  my %mcp = ( type => 'mcp', server_label => 'docs', server_url => 'https://mcp.example/sse' );
  for my $case (
    [ 'absent (wire default always)', {%mcp} ],
    [ 'always',                       { %mcp, require_approval => 'always' } ],
    [ 'a per-tool hash',              { %mcp, require_approval => { never => { tool_names => ['a'] } } } ],
  ) {
    my ( $label, $tool ) = @$case;
    ok( !eval { engine()->chat_request( [ { role => 'user', content => 'x' } ], tools => [$tool] ); 1 },
      "croaks: $label" );
    like( $@, qr/remote MCP tool 'docs' needs require_approval => 'never'/, 'says why' );
    ok( !eval { engine( server_tools => [$tool] )->chat_request( [ { role => 'user', content => 'x' } ] ); 1 },
      "croaks as an engine default too: $label" );
  }
  my $ok = { %mcp, require_approval => 'never' };
  my $req = engine()->chat_request( [ { role => 'user', content => 'x' } ], tools => [$ok] );
  is_deeply( $json->decode( $req->content )->{tools}, [$ok], "'never' goes out verbatim" );
};

subtest 'engine server_tools must be server tools (fail loud, no silent drop)' => sub {
  for my $case (
    [ 'a bare string',   'web_search' ],
    [ 'a function tool', { name => 'f', input_schema => { type => 'object', properties => {} } } ],
    [ 'an unknown type', { type => 'foo_search' } ],
  ) {
    my ( $label, $entry ) = @$case;
    ok( !eval { engine( server_tools => [$entry] )->chat_request( [ { role => 'user', content => 'x' } ] ); 1 },
      "croaks: $label" );
    like( $@, qr/server_tools entry .* is not a server tool/, 'says why' );
  }
  my $unlisted = Langertha::ServerTool->new( wire => 'responses', spec => { type => 'foo_search' }, unlisted => 1 );
  my $req = engine( server_tools => [$unlisted] )->chat_request( [ { role => 'user', content => 'x' } ] );
  is_deeply( $json->decode( $req->content )->{tools}, [ { type => 'foo_search' } ],
    'an unlisted type is sent when wrapped with unlisted => 1' );
};

subtest 'a server tool in the request replaces the engine default of the same kind' => sub {
  my $e = engine( server_tools => [
    { type => 'web_search' },
    { type => 'mcp', server_label => 'a', server_url => 'https://a', require_approval => 'never' },
    { type => 'mcp', server_label => 'b', server_url => 'https://b', require_approval => 'never' },
  ] );
  my $req = $e->chat_request( [ { role => 'user', content => 'x' } ], tools => [
    { type => 'web_search', search_context_size => 'high' },
    Langertha::ServerTool->new( wire => 'responses',
      spec => { type => 'mcp', server_label => 'a', server_url => 'https://a2', require_approval => 'never' } ),
  ] );
  is_deeply( $json->decode( $req->content )->{tools}, [
    { type => 'web_search', search_context_size => 'high' },
    { type => 'mcp', server_label => 'a', server_url => 'https://a2', require_approval => 'never' },
    { type => 'mcp', server_label => 'b', server_url => 'https://b', require_approval => 'never' },
  ], 'the request wins per type (per server_label for mcp); other defaults stay' );
};

subtest 'a ServerTool on an engine without server_tools croaks before the request' => sub {
  my $mock   = Test::MockAsyncHTTP->new( responses => [ { content => '{}' } ] );
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6-luna', _async_http => $mock );
  my $st     = Langertha::ServerTool->new( wire => 'responses', spec => { type => 'web_search' } );
  my $f = $openai->chat_f( messages => [ { role => 'user', content => 'x' } ], tools => [$st] );
  ok( $f->is_failed, 'chat_f fails' );
  like( scalar $f->failure, qr/'web_search' is a Langertha::ServerTool, and this engine does not supports\('server_tools'\)/,
    'and says why' );
  is( $mock->request_count, 0, 'nothing was sent' );
};

subtest 'max_output_tokens only where supports(response_size)' => sub {
  {
    package Test::NoResponseSize;
    use Moose;
    extends 'Langertha::Engine::OpenAIResponses';
    around engine_capabilities => sub {
      my ( $orig, $self, @rest ) = @_;
      my $caps = $self->$orig(@rest);
      delete $caps->{response_size};
      return $caps;
    };
    __PACKAGE__->meta->make_immutable;
  }
  my $cleared = Test::NoResponseSize->new( api_key => 'k', model => 'm', response_size => 2000 );
  for my $req (
    $cleared->chat_request( [ { role => 'user', content => 'x' } ] ),
    $cleared->chat_request( [ { role => 'user', content => 'x' } ], controls => { max_tokens => 10 } ),
    $cleared->chat_stream_request( [ { role => 'user', content => 'x' } ] ),
  ) {
    ok( !exists $json->decode( $req->content )->{max_output_tokens}, 'no max_output_tokens when the flag is cleared' );
  }
  is( $json->decode( engine()->chat_request( [ { role => 'user', content => 'x' } ], controls => { max_tokens => 10 } )
      ->content )->{max_output_tokens}, 10, 'a per-request max_tokens still wins where the flag is set' );
};

subtest 'capture #1 reply: server call recorded, citation lifted, no tool_calls' => sub {
  my $resp = engine()->chat_response( http_ok( capture_bytes('responses_web_search') ) );
  my $raw  = capture('responses_web_search');
  like( $resp->content, qr/current stable release of Perl 5 is \*\*Perl 5\.44\.0\*\*/, 'content' );
  ok( !$resp->has_tool_calls, 'Response.tool_calls stays empty: nothing for the client to run' );
  is( $resp->finish_reason, 'stop', 'finish_reason stop' );
  ok( $resp->has_server_tool_calls, 'server_tool_calls present' );
  is( scalar @{ $resp->server_tool_calls }, 1, 'one server call' );
  my $call = $resp->server_tool_calls->[0];
  isa_ok( $call, 'Langertha::ServerToolCall' );
  is( $call->type, 'web_search_call', 'type' );
  is( $call->id, 'ws_0775496f8ce2b6b0006ab5d8fc6a9087d293ca4743cf2fdfe9', 'id' );
  is( $call->status, 'completed', 'status' );
  is_deeply( $call->data, $raw->{output}[1], 'the item verbatim, sources included' );
  is_deeply( $resp->citations, [ {
    url         => 'https://dev.perl.org/perl5/?utm_source=openai',
    title       => 'Perl - dev.perl.org',
    start_index => 57,
    end_index   => 120,
  } ], 'the url_citation annotation, url kept verbatim' );
  ok( !$resp->has_thinking, 'encrypted-only reasoning yields no thinking' );
  is_deeply( $resp->raw, $raw, 'raw is untouched (no autovivification)' );
};

subtest 'capture #2 reply: the function call is a tool_call, the search is not' => sub {
  my $resp = engine()->chat_response( http_ok( capture_bytes('responses_web_search_function_call') ) );
  is( scalar @{ $resp->tool_calls }, 1, 'exactly one tool_call' );
  is( $resp->tool_calls->[0]->name, 'get_weather', 'the function call' );
  is_deeply( $resp->tool_calls->[0]->arguments, { city => 'Greenville, South Carolina' }, 'its arguments' );
  is( $resp->finish_reason, 'tool_calls', 'finish_reason tool_calls' );
  is_deeply( [ map { $_->type } @{ $resp->server_tool_calls } ], ['web_search_call'], 'the search is a server call' );
  ok( !$resp->has_citations, 'no annotations, no citations' );
  my @located = @{ Langertha::ToolCall->locate( responses => capture('responses_web_search_function_call') ) };
  is_deeply( [ map { $_->{type} } @located ], ['function_call'], 'ToolCall->locate never returns a server call item' );
};

subtest 'client-actionable output items Langertha cannot answer croak' => sub {
  # Minimal items after the OpenAI create-response reference: provoking an
  # mcp_approval_request live costs an approval round trip, and the other
  # client tools are refused outbound (so no capture can contain them).
  for my $item (
    { type => 'mcp_approval_request', id => 'mcpr_1', server_label => 'docs', name => 'search', arguments => '{}' },
    { type => 'custom_tool_call', id => 'ctc_1', call_id => 'c', name => 'sql', input => 'select 1' },
    { type => 'computer_call', id => 'cu_1', call_id => 'c', action => { type => 'click' } },
    { type => 'local_shell_call', id => 'ls_1', call_id => 'c', action => { type => 'exec' } },
    { type => 'apply_patch_call', id => 'ap_1', call_id => 'c' },
    { type => 'tool_search_call', id => 'ts_1', execution => 'client' },
  ) {
    my $body = { id => 'resp_x', model => 'm', output => [
      { type => 'message', status => 'completed', content => [ { type => 'output_text', text => 'hi' } ] },
      $item,
    ] };
    ok( !eval { engine()->chat_response( http_ok( $json->encode($body) ) ); 1 }, "chat_response croaks: $item->{type}" );
    like( $@, qr/\Q$item->{type}\E.*client must answer/, 'names the item type' );
    ok( !eval { Langertha::ToolCall->locate( responses => $body ); 1 }, "ToolCall->locate croaks: $item->{type}" );
  }
  like( do { eval { engine()->chat_response( http_ok( $json->encode( { output => [
    { type => 'mcp_approval_request', id => 'm', server_label => 's' } ] } ) ) ) }; $@ },
    qr/require_approval => 'never'/, 'the approval request points at the fix' );
  my $unknown = { output => [ { type => 'something_new_call', id => 'x' },
    { type => 'message', status => 'completed', content => [ { type => 'output_text', text => 'ok' } ] } ] };
  my $resp = engine()->chat_response( http_ok( $json->encode($unknown) ) );
  is( $resp->content, 'ok', 'an unknown item type is still skipped (values open)' );
  ok( !$resp->has_server_tool_calls, 'and not claimed as a server call' );
};

subtest 'citations: merged with the hook, deduplicated by url without utm_*' => sub {
  {
    package Test::CitingResponses;
    use Moose;
    extends 'Langertha::Engine::OpenAIResponses';
    sub _responses_extra_fields {
      return ( citations => [
        { url => 'https://dev.perl.org/perl5/', snippet => 'from the hook' },
        { url => 'https://only.hook.example/' },
      ] );
    }
    __PACKAGE__->meta->make_immutable;
  }
  my $resp = Test::CitingResponses->new( api_key => 'k', model => 'm' )
    ->chat_response( http_ok( capture_bytes('responses_web_search') ) );
  is_deeply( $resp->citations, [
    { url => 'https://dev.perl.org/perl5/', snippet => 'from the hook', title => 'Perl - dev.perl.org',
      start_index => 57, end_index => 120 },
    { url => 'https://only.hook.example/' },
  ], 'hook entries first; the ?utm_source=openai annotation fills in the same page, nothing overwritten' );

  my $twice = { output => [ { type => 'message', status => 'completed', content => [ {
    type => 'output_text', text => 'a b',
    annotations => [
      { type => 'url_citation', url => 'https://a.example/x?utm_source=openai', title => 'A', start_index => 0, end_index => 1 },
      { type => 'url_citation', url => 'https://a.example/x?utm_source=openai', title => 'A', start_index => 2, end_index => 3 },
      { type => 'url_citation', url => 'https://a.example/x?page=2&utm_source=openai', title => 'A2' },
      { type => 'file_citation', file_id => 'f' },
    ] } ] } ] };
  is_deeply( engine()->chat_response( http_ok( $json->encode($twice) ) )->citations, [
    { url => 'https://a.example/x?utm_source=openai', title => 'A', start_index => 0, end_index => 1 },
    { url => 'https://a.example/x?page=2&utm_source=openai', title => 'A2' },
  ], 'a page cited twice appears once (first place kept); other query parameters still count; file_citation skipped' );
};

{
  package Test::WeatherMCP;
  sub new { bless { calls => [] }, shift }
  sub calls { $_[0]->{calls} }
  sub list_tools {
    return Future->done( [ {
      name        => 'get_weather',
      description => 'Get the current weather for a city.',
      inputSchema => $get_weather->{parameters},
    } ] );
  }
  sub call_tool {
    my ( $self, $name, $input ) = @_;
    push @{ $self->{calls} }, [ $name, $input ];
    return Future->done( { content => [ { type => 'text',
      text => '{"city":"Greenville, South Carolina","temp_c":18,"conditions":"cloudy"}' } ] } );
  }
}

subtest 'chat_with_tools_f: server-only turn runs no tool' => sub {
  my $mcp  = Test::WeatherMCP->new;
  my $mock = Test::MockAsyncHTTP->new( responses => [ http_ok( capture_bytes('responses_web_search') ) ] );
  my $e    = engine( mcp_servers => [$mcp], server_tools => [ { type => 'web_search' } ], _async_http => $mock );
  my $text = $e->chat_with_tools_f($prompt_1)->get;
  like( $text, qr/Perl 5\.44\.0/, 'returns the answer' );
  is( scalar @{ $mcp->calls }, 0, 'zero call_tool: the web search already ran at OpenAI' );
  is( $mock->request_count, 1, 'one request' );
};

subtest 'chat_with_tools_f: capture #2 -> echo capture, end to end' => sub {
  my $mcp  = Test::WeatherMCP->new;
  my $mock = Test::MockAsyncHTTP->new( responses => [
    http_ok( capture_bytes('responses_web_search_function_call') ),
    http_ok( capture_bytes('responses_web_search_echo') ),
  ] );
  my $e    = engine( mcp_servers => [$mcp], server_tools => [ { type => 'web_search' } ], _async_http => $mock );
  my $text = $e->chat_with_tools_f($prompt_2)->get;
  # No think tags, so the think filter leaves the text as sent, trailing
  # space included (k302).
  my $want_text = capture('responses_web_search_echo')->{output}[0]{content}[0]{text};
  is( $text, $want_text, 'final text of the echo turn, as the model sent it' );
  is_deeply( $mcp->calls, [ [ get_weather => { city => 'Greenville, South Carolina' } ] ],
    'exactly one call_tool: the function call, never the search' );
  is( $mock->request_count, 2, 'two requests' );

  my @sent = map { body_of($_) } $mock->requests;
  # The MCP-formatted function tool carries no `strict` (Tool->to_responses
  # never emits it); the capture's hand-written tool did.
  my %want_fn = %$get_weather;
  delete $want_fn{strict};
  my $want_1 = as_langertha_input( capture_req('responses_web_search_function_call') );
  $want_1->{tools} = [ \%want_fn, { type => 'web_search' } ];
  is_deeply( $sent[0], $want_1, 'turn 1: the capture #2 body (function tool first, then the engine server tool)' );

  my $want_2 = capture_req('responses_web_search_echo');
  my @input  = @{ $sent[1]{input} };
  is_deeply( [ @input[ 0 .. 2 ] ], [ @{ $want_2->{input} }[ 0 .. 2 ] ],
    'turn 2 echoes the user message, the web_search_call item and the function_call item unchanged' );
  is( $input[3]{type}, 'function_call_output', 'then the function result' );
  # ToolResult->to('responses') sends the tool's text as the output string,
  # the same bare JSON string the capture sent (k336, ADR 0030).
  is( $input[3]{output},
    '{"city":"Greenville, South Carolina","temp_c":18,"conditions":"cloudy"}',
    'its output is the tool text, as a plain string' );
  is( $input[3]{call_id}, 'call_kcSDMmpaoCvPu0AvsvjiwYA0', 'for the function call id' );
  is( scalar @input, 4, 'and nothing else' );
  is_deeply( $sent[1]{tools}, $want_1->{tools}, 'the same tools on the follow-up turn' );
};

done_testing;
