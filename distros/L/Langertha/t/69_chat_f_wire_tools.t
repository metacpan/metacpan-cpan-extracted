#!/usr/bin/env perl
# ABSTRACT: chat_f puts every tools item on the wire in the engine's tool_wire_format
use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;
use Langertha::Engine::NousResearch;
use Langertha::Engine::AKI;
use Langertha::ServerTool;
use Langertha::Tool;
use Test::MockAsyncHTTP;

# karr k227 (ADR 0001): chat_f handed `tools` to chat_request raw, so a
# Langertha::Tool went out through TO_JSON in its canonical to_hash shape --
# which only the Anthropic wire reads; OpenAI, Gemini and Ollama got an invalid
# tool and answered 400. chat_f now shapes the list through the same one path
# as chat_stream_realtime_f (k221). What must NOT move: a hash that is already
# in the wire's own shape is the caller's wire intent and goes out byte for
# byte -- it carries the extras the value objects do not model
# (function.strict, cache_control) and the provider built-ins
# (web_search_20250305, google_search) the Tool door refuses.
#
# karr k231: the hermes wire (NousResearch, AKI native) has no tools body key
# -- tools ride the system prompt. chat_f on hermes is one turn of
# chat_with_tools_f: the list is rendered into the Role::HermesTools prompt,
# nothing goes out as `tools`, and <tool_call> blocks in the reply land on
# Response.tool_calls (ADR 0003). A body `tools` key there is a list the
# model never sees.
#
# karr k234: the hermes wire claims no tool_choice_named, so on NousResearch
# (json_schema response_format) a forced tool takes the ADR 0005 rewrite, with
# the schema also in a Hermes <schema> system prompt.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my %reply = (
  openai    => { choices => [ { message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' } ] },
  anthropic => { id => 'msg_1', type => 'message', role => 'assistant',
    content => [ { type => 'text', text => 'ok' } ], stop_reason => 'end_turn' },
  gemini    => { candidates => [ { content => { role => 'model', parts => [ { text => 'ok' } ] }, finishReason => 'STOP' } ] },
  ollama    => { model => 'qwen3:8b', message => { role => 'assistant', content => 'ok' }, done => JSON->true },
  responses => { output => [ { type => 'message', role => 'assistant',
    content => [ { type => 'output_text', text => 'ok' } ] } ] },
);
$reply{hermes} = $reply{openai};

my %make = (
  openai    => sub { Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini', @_ ) },
  anthropic => sub { Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-sonnet-4-6', @_ ) },
  gemini    => sub { Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-3-flash-preview', @_ ) },
  ollama    => sub { Langertha::Engine::Ollama->new( url => 'http://127.0.0.1:11434', model => 'qwen3:8b', @_ ) },
  responses => sub { Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.6-luna', @_ ) },
  hermes    => sub { Langertha::Engine::NousResearch->new( api_key => 'k', model => 'Hermes-4-70B', @_ ) },
);

# ($engine, $mock) for one wire; the engine sends through the mock.
sub engine_for {
  my ($fmt) = @_;
  my $mock = Test::MockAsyncHTTP->new(
    responses => [ Test::MockAsyncHTTP->mock_json_response( $reply{$fmt} ) ] );
  my $engine = $make{$fmt}->( _async_http => $mock );
  is( $engine->tool_wire_format, $fmt, "engine speaks the $fmt tool wire" );
  return ( $engine, $mock );
}

# The raw request bytes chat_f sent for @tools.
sub chat_f_bytes {
  my ( $fmt, $tools ) = @_;
  my ( $engine, $mock ) = engine_for($fmt);
  my $response = $engine->chat_f( messages => ['hi'], tools => $tools )->get;
  ok( defined $response, "$fmt: chat_f answered" );
  my ($request) = $mock->requests;
  return $request->content;
}
sub chat_f_tools { $json->decode( chat_f_bytes(@_) )->{tools} }

# The bytes chat_request builds for the same tools when nothing reshapes them.
sub direct_bytes {
  my ( $fmt, $tools ) = @_;
  my ($engine) = engine_for($fmt);
  return $engine->chat_request( $engine->chat_messages('hi'), tools => $tools )->content;
}

my $schema = { type => 'object', properties => { a => { type => 'number' } }, required => ['a'] };

# Hashes that are already in each wire's own shape, extras and built-ins
# included, plus a typed item Langertha does not know (Moonshot's builtin
# function on an OpenAI-compatible wire): the provider judges those.
my %native = (
  openai => [
    { type => 'function', function => { name => 'add', description => 'Add', parameters => $schema, strict => JSON->true } },
    { type => 'builtin_function', function => { name => '$web_search' } },
  ],
  anthropic => [
    { type => 'web_search_20250305', name => 'web_search', max_uses => 1 },
    { name => 'add', description => 'Add', input_schema => $schema, cache_control => { type => 'ephemeral' } },
  ],
  gemini => [
    { google_search => {} },
    { functionDeclarations => [ { name => 'add', description => 'Add', parameters => $schema, behavior => 'BLOCKING' } ] },
  ],
  ollama => [
    { type => 'function', function => { name => 'add', description => 'Add', parameters => $schema } },
  ],
  responses => [
    { type => 'function', name => 'add', description => 'Add', parameters => $schema, strict => JSON->true },
    { type => 'web_search' },
  ],
  hermes => [
    { type => 'function', function => { name => 'add', description => 'Add', parameters => $schema } },
  ],
);

subtest 'pin: wire-shaped hashes go out byte for byte' => sub {
  for my $fmt (qw( openai anthropic gemini ollama responses )) {
    is( chat_f_bytes( $fmt, $native{$fmt} ), direct_bytes( $fmt, $native{$fmt} ),
      "$fmt: the chat_f body equals the body chat_request builds from the same hashes" );
    is_deeply( chat_f_tools( $fmt, $native{$fmt} ), $native{$fmt}, "$fmt: every hash verbatim, in order" );
  }
};

my $obj = Langertha::Tool->new( name => 'obj', description => 'An object', input_schema => $schema );
my $mcp = { name => 'mcp', description => 'An MCP tool', inputSchema => $schema };
my $mcp_tool = Langertha::Tool->from_hash($mcp);

subtest 'a Langertha::Tool goes out in the wire shape of the engine' => sub {
  for my $fmt (qw( openai anthropic ollama responses )) {
    is_deeply( chat_f_tools( $fmt, [$obj] ), [ $obj->to($fmt) ], "$fmt: serialized by Tool->to" );
  }
  is_deeply( chat_f_tools( gemini => [$obj] ), [ { functionDeclarations => [ $obj->to('gemini') ] } ],
    'gemini: wrapped in one functionDeclarations entry' );
  is( chat_f_tools( hermes => [$obj] ), undef, 'hermes: no tools body key (k231)' );
};

subtest 'a function-tool hash in another shape is converted, per item' => sub {
  for my $fmt (qw( openai anthropic ollama responses )) {
    is_deeply( chat_f_tools( $fmt, [$mcp] ), [ $mcp_tool->to($fmt) ], "$fmt: an MCP hash is converted" );
  }
  is_deeply( chat_f_tools( gemini => [$mcp] ), [ { functionDeclarations => [ $mcp_tool->to('gemini') ] } ],
    'gemini: an MCP hash becomes a declaration' );
  my $canonical = { name => 'mcp', description => 'An MCP tool', input_schema => $schema };
  is_deeply( chat_f_tools( openai => [$canonical] ), [ $mcp_tool->to('openai') ],
    'openai: a canonical input_schema hash is converted' );
  my $nested = { type => 'function', function => { name => 'mcp', description => 'An MCP tool', parameters => $schema } };
  is_deeply( chat_f_tools( anthropic => [$nested] ), [ $mcp_tool->to('anthropic') ],
    'anthropic: an OpenAI-nested hash is converted' );
  is( chat_f_tools( hermes => [$mcp] ), undef, 'hermes: no tools body key (k231)' );
};

subtest 'a converted hash keeps the extras its target wire takes' => sub {
  my $strict = { %$mcp, strict => JSON->true };
  is( chat_f_tools( openai => [$strict] )->[0]{function}{strict}, JSON->true,
    'openai: strict lands on function.strict' );
  my $cached = { %$mcp, cache_control => { type => 'ephemeral' } };
  is_deeply( chat_f_tools( anthropic => [$cached] )->[0]{cache_control}, { type => 'ephemeral' },
    'anthropic: cache_control is kept' );
  my $nested = { type => 'function', function => { name => 'n', parameters => { type => 'object', properties => {} }, strict => JSON->false } };
  is( chat_f_tools( anthropic => [$nested] )->[0]{strict}, JSON->false,
    'anthropic: an explicit function.strict wins over the schema guess' );
  my $decl = { name => 'decl', parameters => $schema, behavior => 'NON_BLOCKING' };
  is_deeply( chat_f_tools( gemini => [$decl] ), [ { functionDeclarations => [$decl] } ],
    'gemini: a bare declaration is not round-tripped, so its extra fields stay' );
};

subtest 'a Langertha::ServerTool: native on its wire, refused elsewhere' => sub {
  my $st = Langertha::ServerTool->new( wire => 'responses', spec => { type => 'web_search' } );
  is_deeply( chat_f_tools( responses => [$st] ), [ { type => 'web_search' } ], 'responses: its native hash' );
  for my $fmt (qw( openai anthropic gemini ollama hermes )) {
    my ( $engine, $mock ) = engine_for($fmt);
    ok( !eval { $engine->chat_f( messages => ['hi'], tools => [$st] )->get; 1 }, "$fmt: croaks" );
    like( $@, qr/does not supports\('server_tools'\)/, "$fmt: says why" );
    is( $mock->request_count, 0, "$fmt: nothing was sent" );
  }
};

subtest 'mixed lists keep the caller order' => sub {
  my $st = Langertha::ServerTool->new( wire => 'responses', spec => { type => 'code_interpreter', container => { type => 'auto' } } );
  my %mixed = (
    openai    => [ [ $native{openai}[0], $obj, $mcp, $native{openai}[1] ],
                   [ $native{openai}[0], $obj->to('openai'), $mcp_tool->to('openai'), $native{openai}[1] ] ],
    ollama    => [ [ $native{ollama}[0], $obj, $mcp ],
                   [ $native{ollama}[0], $obj->to('ollama'), $mcp_tool->to('ollama') ] ],
    anthropic => [ [ $native{anthropic}[0], $obj, $mcp, $native{anthropic}[1] ],
                   [ $native{anthropic}[0], $obj->to('anthropic'), $mcp_tool->to('anthropic'), $native{anthropic}[1] ] ],
    responses => [ [ $native{responses}[0], $obj, $mcp, $native{responses}[1], $st ],
                   [ $native{responses}[0], $obj->to('responses'), $mcp_tool->to('responses'),
                     $native{responses}[1], $st->to('responses') ] ],
  );
  for my $fmt ( sort keys %mixed ) {
    my ( $in, $want ) = @{ $mixed{$fmt} };
    is_deeply( chat_f_tools( $fmt, $in ), $want, "$fmt: every item in place" );
  }
  is_deeply( chat_f_tools( gemini => [ { google_search => {} }, $obj, $mcp ] ),
    [ { google_search => {} }, { functionDeclarations => [ $obj->to('gemini'), $mcp_tool->to('gemini') ] } ],
    'gemini: declarations grouped where the first one was, built-in in place' );
};

subtest 'gemini: one functionDeclarations entry (k221 review M4)' => sub {
  my $raw = $native{gemini}[1];
  my $raw_decl = $raw->{functionDeclarations}[0];
  is_deeply( chat_f_tools( gemini => [ $raw, { google_search => {} }, $obj ] ),
    [ { functionDeclarations => [ $raw_decl, $obj->to('gemini') ] }, { google_search => {} } ],
    'a raw functionDeclarations entry absorbs the converted declarations' );
  is_deeply( chat_f_tools( gemini => [ $obj, $raw ] ),
    [ { functionDeclarations => [ $obj->to('gemini'), $raw_decl ] } ],
    'declarations keep the caller order across the merge' );
  my $second = { functionDeclarations => [ { name => 'two' } ] };
  is_deeply( chat_f_tools( gemini => [ $raw, $second ] ),
    [ { functionDeclarations => [ $raw_decl, { name => 'two' } ] } ],
    'two raw functionDeclarations entries merge into the first' );
  my $combined = { functionDeclarations => [ { name => 'two' } ], codeExecution => {} };
  is_deeply( chat_f_tools( gemini => [ $raw, $combined ] ),
    [ { functionDeclarations => [ $raw_decl, { name => 'two' } ] }, { codeExecution => {} } ],
    'a later entry gives up its declarations and keeps its other fields' );

  # k227 review M1: the REST API reads function_declarations too (ADR 0018);
  # both spellings fold into the one entry, or Gemini gets two.
  my $snake = { function_declarations => [ { name => 'snake' } ] };
  is_deeply( chat_f_tools( gemini => [ $snake, $obj ] ),
    [ { functionDeclarations => [ { name => 'snake' }, $obj->to('gemini') ] } ],
    'a function_declarations entry absorbs the converted declarations' );
  is_deeply( chat_f_tools( gemini => [ $raw, { function_declarations => [ { name => 'two' } ], codeExecution => {} } ] ),
    [ { functionDeclarations => [ $raw_decl, { name => 'two' } ] }, { codeExecution => {} } ],
    'a later function_declarations entry merges into the first and keeps its other fields' );
};

subtest 'a Gemini declaration with parametersJsonSchema keeps its schema off Gemini (k227 review M2)' => sub {
  # Gemini declares a schema as parameters OR parametersJsonSchema (ADR 0018:
  # accept both). Read only as parameters, the other spelling went out on a
  # non-Gemini wire with an empty schema -- a tool whose arguments vanished.
  for my $key (qw( parametersJsonSchema parameters_json_schema )) {
    my $decl = { name => 'mcp', description => 'An MCP tool', $key => $schema };
    for my $fmt (qw( openai anthropic ollama )) {
      is_deeply( chat_f_tools( $fmt, [$decl] ), [ $mcp_tool->to($fmt) ], "$fmt: $key becomes the schema" );
    }
    is_deeply( chat_f_tools( gemini => [$decl] ), [ { functionDeclarations => [$decl] } ],
      "gemini: a $key declaration goes out verbatim" );
  }
};

# --- hermes (k231) --------------------------------------------------------

# The tools the hermes system prompt carries, decoded from the <tools> block.
sub prompt_tools {
  my ($content) = @_;
  my ($tools_json) = $content =~ m{^<tools>\n(.*?)\n</tools>$}ms or return undef;
  return $json->decode($tools_json);
}

sub hermes_body {
  my ( $tools, %args ) = @_;
  my ( $engine, $mock ) = engine_for('hermes');
  $engine->chat_f( messages => ['hi'], tools => $tools, %args )->get;
  return ( $json->decode( ( $mock->requests )[0]->content ), $engine );
}

subtest 'hermes: chat_f renders the tools into the system prompt, as chat_with_tools_f' => sub {
  my $in = [ $native{hermes}[0], $obj, $mcp ];
  my ( $body, $engine ) = hermes_body($in);
  ok( !exists $body->{tools}, 'no tools body key' );
  ok( !exists $body->{parallel_tool_calls}, 'no parallel_tool_calls either' );
  is( $body->{messages}[0]{role}, 'system', 'a system message leads' );
  is_deeply( prompt_tools( $body->{messages}[0]{content} ),
    [ Langertha::Tool->from_hash( $native{hermes}[0] )->to_mcp, $obj->to_mcp, $mcp_tool->to_mcp ],
    'the prompt carries every tool in MCP shape, in the caller order' );
  is_deeply( $body->{messages}[1], { role => 'user', content => 'hi' }, 'the user turn follows' );

  # The claim "one turn of chat_with_tools_f": the same body its request builder makes.
  my $turn = $engine->build_tool_chat_request( $engine->chat_messages('hi'), $engine->format_tools($in) );
  is_deeply( $body, $json->decode( $turn->content ), 'same body as a chat_with_tools_f turn' );

  my ( $sys_body ) = do {
    my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response( $reply{hermes} ) ] );
    my $e = $make{hermes}->( _async_http => $mock, system_prompt => 'Be terse.' );
    $e->chat_f( messages => ['hi'], tools => [$obj] )->get;
    $json->decode( ( $mock->requests )[0]->content );
  };
  is( scalar @{ $sys_body->{messages} }, 3, 'with an engine system prompt: three messages' );
  like( $sys_body->{messages}[0]{content}, qr/<tools>/, 'the tool prompt first' );
  is_deeply( $sys_body->{messages}[1], { role => 'system', content => 'Be terse.' }, 'then the engine system prompt' );

  my ($empty) = hermes_body( [] );
  ok( !exists $empty->{tools}, 'tools => []: no tools body key' );
  is_deeply( $empty->{messages}, [ { role => 'user', content => 'hi' } ], 'tools => []: no tool prompt' );
};

subtest 'hermes: tool_choice has no wire of its own' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my ($auto) = hermes_body( [$obj], tool_choice => 'auto' );
  ok( !exists $auto->{tool_choice}, 'auto: not in the body' );
  is( scalar @warnings, 0, 'auto: silent -- it is what the prompt already says' );

  # AKI native has no response_format either, so the ADR 0005 rewrite cannot
  # fire there (k234): a forced choice is dropped with a warning.
  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response( { success => JSON->true, text => 'ok' } ) ] );
  my $aki = Langertha::Engine::AKI->new( api_key => 'k', _async_http => $mock );
  $aki->chat_f( messages => ['hi'], tools => [$obj], tool_choice => { type => 'tool', name => 'obj' } )->get;
  my $forced = $json->decode( ( $mock->requests )[0]->content );
  ok( !exists $forced->{tool_choice}, 'AKI forced: not in the body' );
  ok( !exists $forced->{response_format}, 'AKI forced: no response_format to rewrite to' );
  is( prompt_tools( $json->decode( $forced->{chat_context} )->[0]{content} )->[0]{name}, 'obj',
    'AKI forced: the tool is still offered' );
  is( scalar @warnings, 1, 'AKI forced: one warning' );
  like( $warnings[0] // '', qr/tool_choice.*ignored.*hermes/, 'AKI forced: the warning says it is ignored on hermes' );

  @warnings = ();
  my ($any) = hermes_body( [$obj], tool_choice => 'any' );
  ok( !exists $any->{tool_choice} && !exists $any->{response_format}, 'NousResearch any: dropped, not rewritten' );
  is( scalar @warnings, 1, 'NousResearch any: one warning' );

  @warnings = ();
  my ($missing) = hermes_body( [$obj], tool_choice => { type => 'tool', name => 'nope' } );
  ok( !exists $missing->{tool_choice} && !exists $missing->{response_format},
    'NousResearch named tool not in tools: dropped, not rewritten' );
  is( scalar @warnings, 1, 'NousResearch named tool not in tools: one warning' );
};

subtest 'hermes: a forced tool on NousResearch takes the json_schema rewrite (k234, ADR 0005)' => sub {
  # tool_choice_named is cleared on the hermes wire and NousResearch keeps the
  # json_schema response_format of OpenAIBase, so chat_f rewrites a forced
  # tool into response_format and synthesizes the ToolCall from the JSON reply.
  # A backend that ignores response_format must still see the schema, so it
  # also rides a system message in the Hermes structured-output prompt form.
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $reply = { choices => [ { message => { role => 'assistant', content => '{"a": 1}' }, finish_reason => 'stop' } ] };
  my $mock  = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response($reply) ] );
  my $engine = $make{hermes}->( _async_http => $mock );
  my $response = $engine->chat_f( messages => ['hi'], tools => [ $obj, $mcp ],
    tool_choice => { type => 'tool', name => 'obj' } )->get;
  my $body = $json->decode( ( $mock->requests )[0]->content );

  ok( !exists $body->{tools} && !exists $body->{tool_choice}, 'neither tools nor tool_choice in the body' );
  is( $body->{response_format}{type}, 'json_schema', 'response_format json_schema' );
  is( $body->{response_format}{json_schema}{name}, 'obj', 'named after the forced tool' );
  is_deeply( $body->{response_format}{json_schema}{schema}, $schema, 'carrying its input schema' );

  is( scalar @{ $body->{messages} }, 2, 'a schema system message, then the user turn' );
  is( $body->{messages}[0]{role}, 'system', 'the schema prompt leads' );
  my ($in_prompt) = $body->{messages}[0]{content} =~ m{<schema>\s*(.*?)\s*</schema>}s;
  ok( defined $in_prompt, 'the schema sits in <schema> tags' );
  is_deeply( $json->decode( $in_prompt // 'null' ), $schema, 'the same schema' );
  unlike( $body->{messages}[0]{content}, qr/<tools>/, 'no tool prompt: the rewrite took the tools off' );
  is_deeply( $body->{messages}[1], { role => 'user', content => 'hi' }, 'the user turn follows' );

  is( scalar @{ $response->tool_calls }, 1, 'one tool call' );
  is( $response->tool_call->name, 'obj', 'the forced tool' );
  ok( $response->tool_call->synthetic, 'synthetic' );
  is_deeply( $response->tool_call_args('obj'), { a => 1 }, 'arguments parsed from the JSON reply' );
  is( scalar @warnings, 0, 'silent: the choice was honored' );

  my $custom = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response($reply) ] );
  $make{hermes}->( _async_http => $custom, hermes_schema_prompt => "Schema: %s" )
    ->chat_f( messages => ['hi'], tools => [$obj], tool_choice => { type => 'tool', name => 'obj' } )->get;
  like( $json->decode( ( $custom->requests )[0]->content )->{messages}[0]{content}, qr/\ASchema: \{/,
    'hermes_schema_prompt is the template' );
};

subtest 'hermes: tool_choice undef is no choice (k231 review)' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my ($body) = hermes_body( [$obj], tool_choice => undef );
  ok( !exists $body->{tool_choice}, 'not in the body' );
  is_deeply( prompt_tools( $body->{messages}[0]{content} ), [ $obj->to_mcp ], 'the tools are offered' );
  is( scalar @warnings, 0, 'silent, as OpenAICompatible treats an undef tool_choice' );
};

subtest 'hermes: tool_choice none withholds the tools (k231 review, as k233 on Responses)' => sub {
  # none means the model must not call a tool. The prompt cannot forbid one,
  # so the only honest expression is to not offer the tools at all -- and a
  # tag the model writes anyway is not lifted as if a tool had been offered.
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $text  = qq{<tool_call>{"name": "obj", "arguments": {}}</tool_call>};
  my $reply = { choices => [ { message => { role => 'assistant', content => $text }, finish_reason => 'stop' } ] };
  my $mock  = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response($reply) ] );
  my $engine = $make{hermes}->( _async_http => $mock );
  my $response = $engine->chat_f( messages => ['hi'], tools => [$obj], tool_choice => 'none' )->get;
  my $body = $json->decode( ( $mock->requests )[0]->content );
  ok( !exists $body->{tools} && !exists $body->{tool_choice}, 'neither key in the body' );
  is_deeply( $body->{messages}, [ { role => 'user', content => 'hi' } ], 'no tool prompt' );
  ok( !( $response->has_tool_calls && @{ $response->tool_calls } ), 'no reply lift' );
  is( $response->content, $text, 'content untouched' );
  is( scalar @warnings, 1, 'one warning' );
  like( $warnings[0] // '', qr/none.*withheld/, 'the warning says the tools were withheld' );
};

subtest 'hermes: a built-in cannot ride the prompt and croaks' => sub {
  my ( $engine, $mock ) = engine_for('hermes');
  ok( !eval { $engine->chat_f( messages => ['hi'],
    tools => [ { type => 'web_search_20250305', name => 'web_search' } ] )->get; 1 }, 'croaks' );
  like( $@, qr/web_search_20250305/, 'names the item' );
  is( $mock->request_count, 0, 'nothing was sent' );
};

subtest 'hermes: AKI native puts the prompt in chat_context, no tools key' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response( { success => JSON->true, text => 'ok' } ) ] );
  my $aki = Langertha::Engine::AKI->new( api_key => 'k', _async_http => $mock );
  $aki->chat_f( messages => ['hi'], tools => [$obj] )->get;
  my $body = $json->decode( ( $mock->requests )[0]->content );
  ok( !exists $body->{tools}, 'no tools body key' );
  my $context = $json->decode( $body->{chat_context} );
  is_deeply( prompt_tools( $context->[0]{content} ), [ $obj->to_mcp ], 'chat_context leads with the tool prompt' );
};

subtest 'hermes: <tool_call> blocks in the reply land on Response.tool_calls' => sub {
  my $text = qq{Adding.\n<tool_call>\n{"name": "obj", "arguments": {"a": 1}}\n</tool_call>};
  my $reply = { choices => [ { message => { role => 'assistant', content => $text }, finish_reason => 'stop' } ] };
  my $run = sub {
    my ( $tools, @engine_args ) = @_;
    my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response($reply) ] );
    my $engine = $make{hermes}->( _async_http => $mock, @engine_args );
    return $engine->chat_f( messages => ['hi'], $tools ? ( tools => $tools ) : () )->get;
  };

  my $response = $run->( [$obj] );
  is( scalar @{ $response->tool_calls }, 1, 'one tool call' );
  is( $response->tool_call->name, 'obj', 'named as in the tag' );
  is_deeply( $response->tool_call_args('obj'), { a => 1 }, 'with its arguments' );
  ok( !$response->tool_call->synthetic, 'the model emitted it -- not synthetic' );
  is( $response->content, 'Adding.', 'the tag is gone from content' );

  my $plain = $run->(undef);
  ok( !( $plain->has_tool_calls && @{ $plain->tool_calls } ), 'without tools: nothing lifted' );
  is( $plain->content, $text, 'without tools: content untouched (simple_chat_f is not a tool turn)' );

  my $custom_text = $text =~ s/tool_call>/function_call>/gr;
  $reply->{choices}[0]{message}{content} = $custom_text;
  my $custom = $run->( [$obj], hermes_call_tag => 'function_call' );
  is( $custom->tool_call && $custom->tool_call->name, 'obj', 'a custom hermes_call_tag is honored' );

  # AKI native already lifts the tags in chat_response (k123): not twice.
  my $aki_text = $text;
  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response( { success => JSON->true, text => $aki_text } ) ] );
  my $aki = Langertha::Engine::AKI->new( api_key => 'k', _async_http => $mock );
  my $aki_response = $aki->chat_f( messages => ['hi'], tools => [$obj] )->get;
  is( scalar @{ $aki_response->tool_calls }, 1, 'AKI: one tool call, not two' );
  is( $aki_response->content, 'Adding.', 'AKI: content without the tag' );
};

{
  # Records what chat_stream_realtime_f hands to chat_stream_request and stops
  # there: the claim is the request, not the transport.
  package Test::StopAtHermesStream;
  use Moose::Role;
  has seen => ( is => 'rw' );
  around chat_stream_request => sub {
    my ( $orig, $self, $messages, %extra ) = @_;
    $self->seen( [ $messages, \%extra ] );
    die "stop before sending\n";
  };
}

subtest 'hermes: any json_schema response_format also rides the schema prompt (k234)' => sub {
  # Not only the rewrite: a json_schema the caller passes on NousResearch --
  # per request or on the engine -- goes into the Hermes <schema> prompt too,
  # for the same reason: a backend that ignores response_format still sees it.
  my $rf = { type => 'json_schema', json_schema => { name => 'out', schema => $schema } };
  my $send = sub {
    my ( $engine_args, @chat_args ) = @_;
    my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response( $reply{hermes} ) ] );
    $make{hermes}->( _async_http => $mock, @$engine_args )->chat_f( messages => ['hi'], @chat_args )->get;
    return $json->decode( ( $mock->requests )[0]->content );
  };
  my $schema_in = sub { my ($m) = $_[0]{messages}[0]{content} =~ m{<schema>\s*(.*?)\s*</schema>}s; $m };

  my $direct = $send->( [], response_format => $rf );
  is_deeply( $direct->{response_format}, $rf, 'per request: response_format still on the body' );
  is( $direct->{messages}[0]{role}, 'system', 'per request: a system message leads' );
  is_deeply( $json->decode( $schema_in->($direct) // 'null' ), $schema, 'per request: the schema in <schema> tags' );
  is_deeply( $direct->{messages}[1], { role => 'user', content => 'hi' }, 'per request: the user turn follows' );
  unlike( $direct->{messages}[0]{content}, qr/\bYou are\b/i,
    'no persona line: the schema prompt must not compete with the system_prompt (k234 review M3)' );

  my $with_system = $send->( [ system_prompt => 'Be terse.' ], response_format => $rf );
  like( $with_system->{messages}[0]{content}, qr/<schema>/, 'with a system_prompt: the schema prompt leads, as the tool prompt does' );
  is_deeply( $with_system->{messages}[1], { role => 'system', content => 'Be terse.' }, 'with a system_prompt: then the engine system prompt' );

  my $engine_rf = $send->( [ response_format => $rf ] );
  is_deeply( $json->decode( $schema_in->($engine_rf) // 'null' ), $schema, 'engine attribute: the schema in the prompt' );

  my $with_tools = $send->( [], response_format => $rf, tools => [$obj] );
  is( scalar @{ $with_tools->{messages} }, 3, 'with tools: schema prompt, tool prompt, user turn' );
  like( $with_tools->{messages}[0]{content}, qr/<schema>/, 'with tools: the schema prompt first' );
  like( $with_tools->{messages}[1]{content}, qr/<tools>/, 'with tools: then the tool prompt' );

  my $object = $send->( [], response_format => { type => 'json_object' } );
  is_deeply( $object->{messages}, [ { role => 'user', content => 'hi' } ], 'json_object: no schema, no prompt' );

  my $engine = Moose::Util::with_traits( 'Langertha::Engine::NousResearch', 'Test::StopAtHermesStream' )
    ->new( api_key => 'k', model => 'Hermes-4-70B' );
  ok( !eval { $engine->chat_stream_realtime_f( messages => ['hi'], response_format => $rf )->get; 1 },
    'stream: stopped at chat_stream_request' );
  is( $@, "stop before sending\n", 'stream: for the recording stop' );
  like( $engine->seen->[0][0]{content}, qr/<schema>/, 'stream: the schema prompt leads too' );
};

subtest 'hermes: chat_stream_realtime_f renders the tools into the prompt too' => sub {
  my $engine = Moose::Util::with_traits( 'Langertha::Engine::NousResearch', 'Test::StopAtHermesStream' )
    ->new( api_key => 'k', model => 'Hermes-4-70B' );
  ok( !eval { $engine->chat_stream_realtime_f( messages => ['hi'], tools => [ $obj, $mcp ],
    tool_choice => 'auto' )->get; 1 }, 'stopped at chat_stream_request' );
  is( $@, "stop before sending\n", 'for the recording stop, not an earlier croak' );
  my ( $messages, $extra ) = @{ $engine->seen };
  ok( !exists $extra->{tools}, 'no tools key' );
  ok( !exists $extra->{tool_choice}, 'no tool_choice key' );
  is_deeply( prompt_tools( $messages->[0]{content} ), [ $obj->to_mcp, $mcp_tool->to_mcp ],
    'the prompt carries the tools' );
};

done_testing;
