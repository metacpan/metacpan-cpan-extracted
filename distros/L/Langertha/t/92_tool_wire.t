use strict;
use warnings;
use Test2::Bundle::More;
use Langertha::Tool;
use Langertha::ToolCall;
use Langertha::ToolResult;
use Langertha::ToolChoice;

# Value-object layer for tool wire-translation: Tool->to / format_list,
# ToolCall->from_fmt / locate / extract($fmt,$data), ToolResult->to.
# This is the test surface the engine tool methods now delegate to.

my $mcp_tool = {
  name        => 'get_weather',
  description => 'Get the weather',
  inputSchema => { type => 'object', properties => { city => { type => 'string' } } },
};

# ---------------------------------------------------------------------------
# Tool->to / format_list
# ---------------------------------------------------------------------------
subtest 'Tool->to per format' => sub {
  my $tool = Langertha::Tool->from_mcp($mcp_tool);

  is_deeply( $tool->to('openai'),    $tool->to_openai,    'to(openai)' );
  is_deeply( $tool->to('anthropic'), $tool->to_anthropic, 'to(anthropic)' );
  is_deeply( $tool->to('gemini'),    $tool->to_gemini,    'to(gemini)' );
  is_deeply( $tool->to('ollama'),    $tool->to_ollama,    'to(ollama)' );
  is_deeply( $tool->to('responses'), $tool->to_responses, 'to(responses)' );
  is_deeply( $tool->to('hermes'),    $tool->to_mcp,       'to(hermes) == to_mcp' );

  ok( !eval { $tool->to('bogus'); 1 }, 'unknown format dies' );
  like( $@, qr/unknown wire format 'bogus'/, 'unknown format croaks' );
};

subtest 'Tool->format_list collection shaping' => sub {
  my $oai = Langertha::Tool->format_list( 'openai', [$mcp_tool] );
  is( $oai->[0]{type}, 'function', 'openai list is flat function objects' );
  is( $oai->[0]{function}{name}, 'get_weather', 'name carried' );

  my $gem = Langertha::Tool->format_list( 'gemini', [$mcp_tool] );
  is( scalar @$gem, 1, 'gemini list has one wrapper' );
  ok( $gem->[0]{functionDeclarations}, 'gemini wraps in functionDeclarations' );
  is( $gem->[0]{functionDeclarations}[0]{name}, 'get_weather', 'declaration name' );

  my $herm = Langertha::Tool->format_list( 'hermes', [$mcp_tool] );
  is( $herm->[0]{name}, 'get_weather', 'hermes list is raw MCP defs' );
  ok( $herm->[0]{inputSchema}, 'hermes keeps inputSchema (camelCase)' );

  # mixed-shape input is normalized via from_list
  my $mixed = Langertha::Tool->format_list( 'openai',
    [ { type => 'function', function => { name => 'x', parameters => {} } }, $mcp_tool ] );
  is( scalar @$mixed, 2, 'mixed shapes both parse' );
};

# ---------------------------------------------------------------------------
# ToolCall->locate / from_fmt / extract($fmt,$data)
# ---------------------------------------------------------------------------
subtest 'ToolCall->locate + extract per format' => sub {
  my %resp = (
    openai => {
      choices => [ { message => { tool_calls => [
        { id => 'call_1', type => 'function',
          function => { name => 'echo', arguments => '{"m":"hi"}' } },
      ] } } ],
    },
    ollama => {
      message => { tool_calls => [
        { function => { name => 'echo', arguments => { m => 'hi' } } },
      ] },
    },
    anthropic => {
      content => [
        { type => 'text', text => 'thinking' },
        { type => 'tool_use', id => 'toolu_1', name => 'echo', input => { m => 'hi' } },
      ],
    },
    gemini => {
      candidates => [ { content => { parts => [
        { text => 'before' },
        { functionCall => { name => 'echo', args => { m => 'hi' } } },
      ] } } ],
    },
    responses => {
      output => [
        { type => 'function_call', call_id => 'call_9', name => 'echo',
          arguments => '{"m":"hi"}' },
      ],
    },
  );

  for my $fmt ( sort keys %resp ) {
    my $located = Langertha::ToolCall->locate( $fmt, $resp{$fmt} );
    is( scalar @$located, 1, "$fmt: locate finds one raw call" );

    my @calls = Langertha::ToolCall->extract( $fmt, $resp{$fmt} );
    is( scalar @calls, 1, "$fmt: extract returns one ToolCall" );
    isa_ok( $calls[0], ['Langertha::ToolCall'], "$fmt: is a ToolCall" );
    is( $calls[0]->name, 'echo', "$fmt: name parsed" );
    is_deeply( $calls[0]->arguments, { m => 'hi' }, "$fmt: arguments parsed/decoded" );
  }

  is_deeply( Langertha::ToolCall->locate( 'openai', {} ), [], 'empty data locates nothing' );
  ok( !eval { Langertha::ToolCall->from_fmt( 'bogus', {} ); 1 }, 'from_fmt unknown dies' );
  like( $@, qr/unknown wire format 'bogus'/, 'from_fmt unknown croaks' );
};

# ---------------------------------------------------------------------------
# ToolResult->to per format
# ---------------------------------------------------------------------------
subtest 'ToolResult->to per format' => sub {
  my $r = Langertha::ToolResult->new(
    name    => 'echo',
    id      => 'call_1',
    content => [ { type => 'text', text => 'Echo: hi' } ],
  );

  my $oai = $r->to('openai');
  is( $oai->{role}, 'tool', 'openai role tool' );
  is( $oai->{tool_call_id}, 'call_1', 'openai tool_call_id' );
  ok( !ref $oai->{content}, 'openai content is an encoded string' );

  my $oll = $r->to('ollama');
  is( $oll->{role}, 'tool', 'ollama role tool' );
  is( $oll->{tool_name}, 'echo', 'ollama tool_name' );
  is( $oll->{tool_call_id}, 'call_1', 'ollama tool_call_id' );

  my $res = $r->to('responses');
  is( $res->{call_id}, 'call_1', 'responses call_id' );

  my $ant = $r->to('anthropic');
  is( $ant->{type}, 'tool_result', 'anthropic tool_result' );
  is( $ant->{tool_use_id}, 'call_1', 'anthropic tool_use_id' );
  is_deeply( $ant->{content}, [ { type => 'text', text => 'Echo: hi' } ],
    'anthropic embeds content array' );
  ok( !exists $ant->{is_error}, 'no is_error when ok' );

  my $gem = $r->to('gemini');
  is( $gem->{functionResponse}{name}, 'echo', 'gemini name' );
  is_deeply( $gem->{functionResponse}{response}, { result => 'Echo: hi' },
    'gemini flattens to text' );

  my $herm = $r->to( 'hermes', response_tag => 'fn_response' );
  like( $herm, qr/<fn_response>/, 'hermes custom tag' );
  like( $herm, qr/Echo: hi/, 'hermes carries text' );
};

subtest 'ToolResult error flag' => sub {
  my $r = Langertha::ToolResult->new(
    id => 'x', content => [ { type => 'text', text => 'boom' } ], is_error => 1,
  );
  ok( $r->to('anthropic')->{is_error}, 'anthropic is_error set on error' );
};

# ---------------------------------------------------------------------------
# ToolChoice->to per format (unified tag dispatch over the per-format to_*)
# ---------------------------------------------------------------------------
subtest 'ToolChoice->to per format' => sub {
  my $named = Langertha::ToolChoice->specific('calc');

  is_deeply( $named->to('openai'),    $named->to_openai,    'to(openai)' );
  is_deeply( $named->to('anthropic'), $named->to_anthropic, 'to(anthropic)' );
  is_deeply( $named->to('gemini'),    $named->to_gemini,    'to(gemini)' );
  is_deeply( $named->to('responses'), $named->to_responses, 'to(responses)' );

  is( Langertha::ToolChoice->any->to('openai'), 'required', 'string forms dispatch too' );

  # Wires with no tool_choice parameter (and non-wire perplexity) are not on the
  # tag dispatch.
  ok( !eval { $named->to('ollama'); 1 },     'ollama has no wire tool_choice' );
  ok( !eval { $named->to('hermes'); 1 },     'hermes has no wire tool_choice' );
  ok( !eval { $named->to('bogus');  1 },     'unknown format dies' );
  like( $@, qr/unknown wire format 'bogus'/, 'unknown format croaks' );
};

# ---------------------------------------------------------------------------
# ToolCall->sniff_format / extract_sniff (format-less back-compat fallback)
# ---------------------------------------------------------------------------
subtest 'ToolCall sniff fallback' => sub {
  my %resp = (
    openai    => { choices => [ { message => { tool_calls => [
                     { id => 'c1', type => 'function',
                       function => { name => 'echo', arguments => '{"m":"hi"}' } } ] } } ] },
    ollama    => { message => { tool_calls => [
                     { function => { name => 'echo', arguments => { m => 'hi' } } } ] } },
    anthropic => { content => [
                     { type => 'tool_use', id => 't1', name => 'echo', input => { m => 'hi' } } ] },
    gemini    => { candidates => [ { content => { parts => [
                     { functionCall => { name => 'echo', args => { m => 'hi' } } } ] } } ] },
    responses => { output => [
                     { type => 'function_call', call_id => 'c9', name => 'echo',
                       arguments => '{"m":"hi"}' } ] },
  );

  for my $fmt ( sort keys %resp ) {
    is( Langertha::ToolCall->sniff_format( $resp{$fmt} ), $fmt, "$fmt: sniff_format detects shape" );
    my @calls = Langertha::ToolCall->extract_sniff( $resp{$fmt} );
    is( scalar @calls, 1, "$fmt: extract_sniff returns one ToolCall" );
    is( $calls[0]->name, 'echo', "$fmt: name parsed via sniff" );
  }

  is( Langertha::ToolCall->sniff_format({}), undef, 'unknown shape sniffs to undef' );
  is_deeply( [ Langertha::ToolCall->extract_sniff({}) ], [], 'unknown shape extracts nothing' );

  ok( !eval { Langertha::ToolCall->extract({ choices => [] }); 1 },
    'extract with a hashref as $fmt dies (fail loud on legacy single-arg)' );
};

done_testing;
