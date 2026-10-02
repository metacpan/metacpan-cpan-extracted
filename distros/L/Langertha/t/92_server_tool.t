#!/usr/bin/env perl
# ABSTRACT: Langertha::ServerTool -- provider-native server-side tools, pinned to one wire

use strict;
use warnings;
use Test2::Bundle::More;
use Langertha::Tool;
use Langertha::ServerTool;
use Langertha::ServerToolCall;

# Why (karr k206, ADR 0030): a server-side tool (web_search, file_search,
# remote mcp, ...) runs at the provider during one request. Its definition is
# a provider contract, not a translatable function tool: web_search on the
# Responses wire, web_search_20250305 on Anthropic and google_search on Gemini
# are three different things. So Langertha::ServerTool carries the native hash
# verbatim, is keyed by the tool_wire_format it belongs to (ADR 0001/0010) and
# refuses every other wire -- sending a Responses web_search to chat/completions
# must croak, not reach the provider as a mystery tool. Recognition reuses
# Tool->classify (k210), the one classifier, so the two value objects can never
# disagree about what a hash is. Phase 1a supports the `responses` wire only.

my $ws = { type => 'web_search' };

subtest 'from_hash recognises Responses server tools, pinned to the wire' => sub {
  for my $hash (
    $ws,
    { type => 'web_search_preview' },
    { type => 'file_search', vector_store_ids => ['vs'] },
    { type => 'code_interpreter', container => { type => 'auto' } },
    { type => 'image_generation' },
    { type => 'mcp', server_label => 's', server_url => 'https://x', require_approval => 'never' },
    { type => 'tool_search' },
    { type => 'shell', environment => { type => 'container_auto' } },
  ) {
    my $st = Langertha::ServerTool->from_hash( responses => $hash );
    ok( $st && $st->isa('Langertha::ServerTool'), "$hash->{type}: a ServerTool" );
    is( $st->wire, 'responses', 'wire' );
    is( $st->type, $hash->{type}, 'type' );
    is_deeply( $st->to('responses'), $hash, 'to(responses) is the native hash, verbatim' );
  }
};

subtest 'from_hash is format-pinned: never sniffs, never takes non-server items' => sub {
  is( Langertha::ServerTool->from_hash( openai => $ws ), undef, 'web_search is not a server tool on openai' );
  is( Langertha::ServerTool->from_hash( responses => { type => 'web_search_20250305', name => 'web_search' } ),
    undef, 'an Anthropic server tool is not one on responses' );
  is( Langertha::ServerTool->from_hash( anthropic => { type => 'web_search_20250305', name => 'web_search' } ),
    undef, 'anthropic is Phase 2: not recognised yet' );
  is( Langertha::ServerTool->from_hash( gemini => { google_search => {} } ), undef, 'gemini is Phase 2' );
  for my $hash (
    { type => 'function', name => 'f', parameters => { type => 'object' } },
    { type => 'custom', name => 'sql' },
    { type => 'namespace', name => 'ns', tools => [] },
    { type => 'local_shell' },
    { type => 'tool_search', execution => 'client' },
    { type => 'programmatic_tool_calling' },
    { name => 'f', inputSchema => { type => 'object' } },
  ) {
    is( Langertha::ServerTool->from_hash( responses => $hash ), undef,
      "not a server tool: " . ( $hash->{type} // $hash->{name} ) );
  }
  my $st = Langertha::ServerTool->new( wire => 'responses', spec => $ws );
  is( Langertha::ServerTool->from_hash( responses => $st ), $st, 'an object passes through' );
};

subtest 'to() croaks on any other wire' => sub {
  my $st = Langertha::ServerTool->new( wire => 'responses', spec => $ws );
  for my $fmt (qw( openai anthropic gemini ollama hermes mcp )) {
    ok( !eval { $st->to($fmt); 1 }, "to($fmt) croaks" );
    like( $@, qr/web_search.*responses.*not '\Q$fmt\E'/, 'names the tool, its wire and the asked wire' );
  }
};

subtest 'the constructor validates the spec' => sub {
  my @bad = (
    [ { wire => 'responses', spec => { type => 'function', name => 'f' } }, qr/function tool/ ],
    [ { wire => 'responses', spec => { type => 'custom', name => 'f' } },   qr/client tool/ ],
    [ { wire => 'responses', spec => { type => 'namespace' } },            qr/client tool/ ],
    [ { wire => 'responses', spec => { type => 'local_shell' } },          qr/client-executed/ ],
    [ { wire => 'responses', spec => { type => 'frobnicate' } },           qr/unlisted => 1/ ],
    [ { wire => 'responses', spec => { name => 'x' } },                    qr/no type/ ],
    [ { wire => 'anthropic', spec => { type => 'web_search_20250305', name => 'web_search' } },
      qr/not supported yet/ ],
    [ { wire => 'responses', spec => { type => 'web_search_20250305', name => 'web_search' } },
      qr/belongs to the anthropic wire/ ],
  );
  for my $row (@bad) {
    my ( $args, $re ) = @$row;
    ok( !eval { Langertha::ServerTool->new(%$args); 1 }, "croaks: $args->{wire} " . ( $args->{spec}{type} // '-' ) );
    like( $@, $re, 'with the reason' );
  }
  my $st = Langertha::ServerTool->new( wire => 'responses', spec => { type => 'frobnicate' }, unlisted => 1 );
  is_deeply( $st->to('responses'), { type => 'frobnicate' }, 'unlisted => 1 vouches for a new server type' );
  ok( !eval { Langertha::ServerTool->new( wire => 'responses', spec => { type => 'custom' }, unlisted => 1 ); 1 },
    'unlisted never makes a client tool a server tool' );
};

subtest 'the native hash is copied, not shared' => sub {
  my $spec = { type => 'web_search' };
  my $st = Langertha::ServerTool->new( wire => 'responses', spec => $spec );
  $spec->{search_context_size} = 'high';
  is_deeply( $st->to('responses'), { type => 'web_search' }, 'a later change to the caller hash does not leak in' );
  my $out = $st->to('responses');
  $out->{x} = 1;
  is_deeply( $st->to('responses'), { type => 'web_search' }, 'nor does a change to the emitted hash' );
  is_deeply( $st->to_hash, { wire => 'responses', spec => { type => 'web_search' } }, 'to_hash' );
  is_deeply( $st->TO_JSON, $st->to_hash, 'TO_JSON delegates' );
};

subtest 'Tool->format_list: server tools on their own wire, croak elsewhere' => sub {
  my $mcp = { name => 'echo', description => 'Echo', inputSchema => { type => 'object', properties => {} } };
  my $fn  = { type => 'function', name => 'echo', description => 'Echo',
              parameters => { type => 'object', properties => {} } };
  my $st  = Langertha::ServerTool->new( wire => 'responses', spec => { type => 'file_search', vector_store_ids => ['v'] } );
  is_deeply( Langertha::Tool->format_list( responses => [ $ws, $mcp, $st ] ),
    [ $ws, $fn, { type => 'file_search', vector_store_ids => ['v'] } ],
    'hash and object server tools kept in place, function tools formatted' );
  for my $fmt (qw( openai anthropic gemini )) {
    ok( !eval { Langertha::Tool->format_list( $fmt => [ $mcp, $ws ] ); 1 }, "a Responses hash croaks on $fmt" );
    like( $@, qr/server-side tool \(responses\)/, 'the k210 door message' );
    ok( !eval { Langertha::Tool->format_list( $fmt => [ $mcp, $st ] ); 1 }, "a Responses ServerTool croaks on $fmt" );
    like( $@, qr/belongs to the responses wire/, 'names the wire' );
  }
  ok( !eval { Langertha::Tool->from_hash($ws); 1 }, 'Tool->from_hash still refuses it: Tool is for function tools' );
  like( $@, qr/Langertha::ServerTool/, 'and points at the value object that takes it' );
};

subtest 'remote MCP on the responses wire needs require_approval => never, on every path' => sub {
  # Enforced by the value object, so Tool->format_list (which sees no engine)
  # cannot skip it (k206 review M3; orchestrator ruling Q2).
  my %mcp = ( type => 'mcp', server_label => 'docs', server_url => 'https://mcp.example/sse' );
  for my $spec ( {%mcp}, { %mcp, require_approval => 'always' },
                 { %mcp, require_approval => { never => { tool_names => ['a'] } } } ) {
    my $st = Langertha::ServerTool->from_hash( responses => $spec );
    ok( $st, 'still recognised (from_hash never croaks)' );
    ok( !eval { $st->to('responses'); 1 }, 'to(responses) croaks' );
    like( $@, qr/remote MCP tool 'docs' needs require_approval => 'never'/, 'says why' );
    ok( !eval { Langertha::Tool->format_list( responses => [$spec] ); 1 }, 'format_list(responses) croaks' );
  }
  my $ok = { %mcp, require_approval => 'never' };
  is_deeply( Langertha::Tool->format_list( responses => [$ok] ), [$ok], "'never' passes" );
};

subtest 'ServerToolCall: a thin record of one provider-executed call' => sub {
  my $item = { id => 'ws_1', type => 'web_search_call', status => 'completed',
               action => { type => 'search', query => 'perl' } };
  my $call = Langertha::ServerToolCall->new( type => 'web_search_call', id => 'ws_1',
    status => 'completed', data => $item );
  is( $call->type, 'web_search_call', 'type' );
  is( $call->id, 'ws_1', 'id' );
  is( $call->status, 'completed', 'status' );
  is_deeply( $call->data, $item, 'data is the item verbatim' );
  is_deeply( $call->to_hash, { type => 'web_search_call', id => 'ws_1', status => 'completed', data => $item },
    'to_hash' );
  is_deeply( $call->TO_JSON, $call->to_hash, 'TO_JSON delegates' );
  my $bare = Langertha::ServerToolCall->new( type => 'mcp_list_tools', data => { type => 'mcp_list_tools' } );
  is( $bare->id, '', 'id defaults to empty' );
  ok( !$bare->has_status, 'status is optional' );
  ok( !exists $bare->to_hash->{status}, 'and absent from to_hash when missing' );
};

subtest 'ServerToolCall->extract: only provider-executed call items' => sub {
  my $data = { output => [
    { type => 'reasoning', id => 'rs', summary => [] },
    { type => 'web_search_call', id => 'ws', status => 'completed' },
    { type => 'function_call', id => 'fc', call_id => 'c', name => 'f', arguments => '{}' },
    { type => 'file_search_call', id => 'fs', status => 'completed' },
    { type => 'code_interpreter_call', id => 'ci' },
    { type => 'image_generation_call', id => 'ig' },
    { type => 'mcp_list_tools', id => 'ml' },
    { type => 'mcp_call', id => 'mc' },
    { type => 'shell_call', id => 'sc' },
    { type => 'tool_search_call', id => 'ts' },
    { type => 'something_new_call', id => 'sn' },
    { type => 'message', id => 'm', content => [] },
    'not a hash',
  ] };
  my @calls = Langertha::ServerToolCall->extract( responses => $data );
  is_deeply( [ map { $_->type } @calls ],
    [qw( web_search_call file_search_call code_interpreter_call image_generation_call
         mcp_list_tools mcp_call shell_call tool_search_call )],
    'server call items in order; function calls, messages and unknown items skipped' );
  is( $calls[0]->data, $data->{output}[1], 'data is the very item' );
  is_deeply( [ Langertha::ServerToolCall->extract( responses => {} ) ], [], 'no output: none' );
  ok( !eval { Langertha::ServerToolCall->extract( anthropic => {} ); 1 }, 'anthropic is not supported yet' );
};

# Why (karr k355, ADR 0030): xAI's Responses API reports an X Search as its own
# output item type, x_search_call, "handled by SpaceXAI server" next to
# web_search_call (docs.x.ai/developers/tools/tool-usage-details, table of
# response.output[].type). Unrecognised, the item is skipped and the search is
# visible only in Response.raw -- a caller reading server_tool_calls would never
# learn X was searched (and X Search is billed per post fetched). The item
# below is constructed: the type is documented, the rest of its fields are not
# (docs-derived, no xAI capture yet -- k206 capture #5), so only type, id and
# status are asserted and the item is kept verbatim.
subtest 'ServerToolCall: xAI x_search_call is a provider-executed call' => sub {
  my $item = { type => 'x_search_call', id => 'xs_1', status => 'completed' };
  my $data = { output => [
    { type => 'reasoning', id => 'rs', summary => [] },
    $item,
    { type => 'web_search_call', id => 'ws', status => 'completed' },
    { type => 'message', id => 'm', content => [] },
  ] };
  my @calls = Langertha::ServerToolCall->extract( responses => $data );
  is_deeply( [ map { $_->type } @calls ], [qw( x_search_call web_search_call )],
    'x_search_call lands next to web_search_call, in wire order' );
  is( $calls[0]->id, 'xs_1', 'id' );
  is( $calls[0]->status, 'completed', 'status' );
  is( $calls[0]->data, $item, 'data is the very item' );
};

done_testing;
