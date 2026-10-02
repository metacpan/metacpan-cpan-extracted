#!/usr/bin/env perl
# ABSTRACT: Unit tests for Raider self-tools, inline tools, and MCP catalog

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Raider;
use Langertha::Raider::Result;

# --- Helper: minimal mock engine that satisfies Raider's needs ---

{
  package MockEngine;
  use Moose;
  with 'Langertha::Role::Tools';

  has chat_model => (is => 'ro', default => 'mock-model');
  has '+mcp_servers' => (default => sub { [] });

  sub format_tools {
    my ($self, $tools) = @_;
    # Return in MCP format (same as input for mock)
    return $tools;
  }

  sub response_tool_calls { return [] }
  sub extract_tool_call { return ($_[1]->{name}, $_[1]->{input}) }
  sub format_tool_results { return () }
  sub response_text_content { return 'mock response' }
  sub think_tag_filter { 0 }

  __PACKAGE__->meta->make_immutable;
}

# --- Test: self-tool definitions ---

subtest 'self-tool definitions - all enabled' => sub {
  my $raider = Langertha::Raider->new(
    engine    => MockEngine->new,
    raider_mcp => 1,
  );

  my $defs = $raider->_self_tool_definitions;
  is(scalar @$defs, 7, '7 self-tools when all enabled');

  my %names = map { $_->{name} => 1 } @$defs;
  ok($names{raider_ask_user}, 'raider_ask_user defined');
  ok($names{raider_wait}, 'raider_wait defined');
  ok($names{raider_wait_for}, 'raider_wait_for defined');
  ok($names{raider_pause}, 'raider_pause defined');
  ok($names{raider_abort}, 'raider_abort defined');
  ok($names{raider_session_history}, 'raider_session_history defined');
  ok($names{raider_manage_mcps}, 'raider_manage_mcps defined');

  # Verify inputSchema is in MCP format (camelCase)
  for my $tool (@$defs) {
    ok(exists $tool->{inputSchema}, "tool $tool->{name} has inputSchema");
    is($tool->{inputSchema}{type}, 'object', "tool $tool->{name} inputSchema is object");
  }
};

subtest 'self-tool definitions - selective' => sub {
  my $raider = Langertha::Raider->new(
    engine    => MockEngine->new,
    raider_mcp => { ask_user => 1, abort => 1 },
  );

  my $defs = $raider->_self_tool_definitions;
  is(scalar @$defs, 2, '2 self-tools when selective');

  my %names = map { $_->{name} => 1 } @$defs;
  ok($names{raider_ask_user}, 'raider_ask_user enabled');
  ok($names{raider_abort}, 'raider_abort enabled');
  ok(!$names{raider_wait}, 'raider_wait not enabled');
};

subtest 'self-tool definitions - disabled' => sub {
  my $raider = Langertha::Raider->new(
    engine => MockEngine->new,
  );

  my $defs = $raider->_self_tool_definitions;
  is(scalar @$defs, 0, 'no self-tools when raider_mcp not set');
};

# --- Test: _execute_self_tool_f ---

subtest 'execute ask_user with callback' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    on_ask_user => sub {
      my ($question, $options) = @_;
      return "I choose red";
    },
  );

  my $result = $raider->_execute_self_tool_f('raider_ask_user', {
    question => 'What color?',
    options  => ['red', 'blue'],
  })->get;

  is($result->{type}, 'result', 'ask_user with callback returns result');
  is($result->{content}[0]{text}, 'I choose red', 'callback answer used');
};

subtest 'execute ask_user without callback' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );

  my $result = $raider->_execute_self_tool_f('raider_ask_user', {
    question => 'What color?',
    options  => ['red', 'blue'],
  })->get;

  is($result->{type}, 'question', 'ask_user without callback returns question');
  is($result->{question}, 'What color?', 'question text preserved');
  is_deeply($result->{options}, ['red', 'blue'], 'options preserved');
};

subtest 'execute abort' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );

  my $result = $raider->_execute_self_tool_f('raider_abort', {
    reason => 'Cannot continue',
  })->get;

  is($result->{type}, 'abort', 'abort returns abort type');
  is($result->{reason}, 'Cannot continue', 'abort reason preserved');
};

subtest 'execute pause with callback' => sub {
  my $paused_reason;
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    on_pause   => sub { $paused_reason = $_[0] },
  );

  my $result = $raider->_execute_self_tool_f('raider_pause', {
    reason => 'Taking a break',
  })->get;

  is($result->{type}, 'result', 'pause with callback returns result');
  is($paused_reason, 'Taking a break', 'on_pause callback invoked');
};

subtest 'execute pause without callback' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );

  my $result = $raider->_execute_self_tool_f('raider_pause', {
    reason => 'Thinking',
  })->get;

  is($result->{type}, 'pause', 'pause without callback returns pause');
  is($result->{reason}, 'Thinking', 'reason preserved');
};

subtest 'execute wait' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );

  my $result = $raider->_execute_self_tool_f('raider_wait', {
    seconds => 5,
    reason  => 'Rate limiting',
  })->get;

  is($result->{type}, 'wait', 'wait returns wait type');
  is($result->{seconds}, 5, 'seconds preserved');
};

subtest 'execute wait_for with callback' => sub {
  my $raider = Langertha::Raider->new(
    engine      => MockEngine->new,
    raider_mcp  => 1,
    on_wait_for => sub {
      my ($condition, $args) = @_;
      return "Condition '$condition' met";
    },
  );

  my $result = $raider->_execute_self_tool_f('raider_wait_for', {
    condition => 'file_exists',
    args      => { path => '/tmp/test' },
  })->get;

  is($result->{type}, 'result', 'wait_for returns result');
  like($result->{content}[0]{text}, qr/file_exists/, 'condition included');
};

subtest 'execute wait_for without callback dies' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );

  eval {
    $raider->_execute_self_tool_f('raider_wait_for', {
      condition => 'something',
    })->get;
  };
  like($@, qr/No on_wait_for callback/, 'dies without callback');
};

# --- Test: session history query ---

subtest 'session history query' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );

  # Manually populate session history
  push @{$raider->session_history}, (
    { role => 'user', content => 'Hello world' },
    { role => 'assistant', content => 'Hi there' },
    { role => 'user', content => 'Tell me about Perl' },
    { role => 'assistant', content => 'Perl is a programming language' },
    { role => 'user', content => 'And about Python' },
  );

  my $result = $raider->_execute_self_tool_f('raider_session_history', {})->get;
  is($result->{type}, 'result', 'returns result');
  like($result->{content}[0]{text}, qr/Hello world/, 'contains first message');
  like($result->{content}[0]{text}, qr/Perl/, 'contains Perl message');

  # Test text filter
  $result = $raider->_execute_self_tool_f('raider_session_history', {
    query => 'Perl',
  })->get;
  like($result->{content}[0]{text}, qr/Perl/, 'query filter works');
  unlike($result->{content}[0]{text}, qr/Hello world/, 'query filter excludes non-matching');

  # Test last_n
  $result = $raider->_execute_self_tool_f('raider_session_history', {
    last_n => 2,
  })->get;
  like($result->{content}[0]{text}, qr/Perl is a programming/, 'last_n returns recent');
  like($result->{content}[0]{text}, qr/Python/, 'last_n returns most recent');
};

# --- Test: session history rendering across wire formats (karr #96) ---

# session_history holds whatever the engine's format_tool_results() put on the
# wire, so the element shape follows tool_wire_format. Only openai/ollama/hermes
# hand every element a {role} plus a plain-string {content}; anthropic content
# is an ArrayRef of blocks, gemini keeps blocks under {parts}, and responses
# items have no {role} at all. Rendering must stay readable for all of them and
# must not emit uninitialized warnings.

{
  package MockToolServer;
  use Moose;
  has tools => (is => 'ro', default => sub { {} });
  sub tool {
    my ( $self, %args ) = @_;
    $self->tools->{$args{name}} = \%args;
    return;
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package MockToolHandle;
  use Moose;
  sub text_result {
    my ( $self, $text ) = @_;
    return { content => [ { type => 'text', text => $text } ] };
  }
  __PACKAGE__->meta->make_immutable;
}

sub mixed_wire_history {
  return (
    # --- anthropic: content is an ArrayRef of blocks ---
    { role => 'user', content => 'What is the weather in Berlin?' },
    { role => 'assistant', content => [
      { type => 'text', text => 'Let me check the weather.' },
      { type => 'tool_use', id => 'toolu_01', name => 'get_weather',
        input => { city => 'Berlin' } },
    ] },
    { role => 'user', content => [
      { type => 'tool_result', tool_use_id => 'toolu_01',
        content => [ { type => 'text', text => 'Berlin: sunny, 22C' } ] },
    ] },
    # --- responses: envelope items, discriminated by {type}, no {role} ---
    { type => 'reasoning', id => 'rs_1',
      summary => [ { type => 'summary_text', text => 'Need the weather tool.' } ] },
    { type => 'message', role => 'assistant', status => 'completed',
      content => [ { type => 'output_text', text => 'Checking Hamburg now.' } ] },
    { type => 'function_call', call_id => 'call_1', name => 'get_weather',
      arguments => '{"city":"Hamburg"}' },
    { type => 'function_call_output', call_id => 'call_1',
      output => '[{"text":"Hamburg: rainy, 14C","type":"text"}]' },
    # --- openai: assistant echo has content => undef when it only calls tools ---
    { role => 'assistant', content => undef, tool_calls => [
      { id => 'call_2', type => 'function',
        function => { name => 'get_time', arguments => '{"tz":"CET"}' } },
    ] },
    { role => 'tool', tool_call_id => 'call_2',
      content => '[{"type":"text","text":"14:05"}]' },
    # --- gemini: blocks live under {parts}, there is no {content} at all ---
    { role => 'model', parts => [
      { text => 'One moment.' },
      { functionCall => { name => 'get_weather', args => { city => 'Kiel' } } },
    ] },
    { role => 'user', parts => [
      { functionResponse => { name => 'get_weather',
        response => { result => 'Kiel: windy, 17C' } } },
    ] },
  );
}

subtest 'session history rendering across wire formats' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  push @{$raider->session_history}, mixed_wire_history();

  my @warnings;
  my $text;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $text = $raider->_query_session_history_f({})->get;
  }

  is(scalar @warnings, 0, 'no warnings while rendering mixed-wire history')
    or diag("warnings: @warnings");

  unlike($text, qr/ARRAY\(0x/, 'ArrayRef content is flattened, not stringified');
  unlike($text, qr/HASH\(0x/, 'HashRef payloads are flattened, not stringified');
  unlike($text, qr/^\[[^\]]*\]\s*$/m, 'no history element renders as a bare label');

  # anthropic
  like($text, qr/\[assistant\] Let me check the weather\./, 'anthropic text block rendered');
  like($text, qr/get_weather.*Berlin/, 'anthropic tool_use is visible with its arguments');
  like($text, qr/Berlin: sunny, 22C/, 'anthropic tool_result content flattened to text');

  # responses
  like($text, qr/\[reasoning\] Need the weather tool\./, 'responses reasoning summary rendered');
  like($text, qr/\[assistant\] Checking Hamburg now\./, 'responses message item uses its role');
  like($text, qr/\[function_call\] .*get_weather.*Hamburg/, 'responses function_call labelled by type');
  like($text, qr/\[function_call_output\] .*Hamburg: rainy, 14C/,
    'responses function_call_output labelled by type and carries its output');

  # openai
  like($text, qr/\[assistant\] .*get_time.*CET/, 'openai tool-only assistant echo shows the call');
  like($text, qr/14:05/, 'openai tool result content kept');

  # gemini
  like($text, qr/\[model\] One moment\./, 'gemini text part rendered');
  like($text, qr/get_weather.*Kiel/, 'gemini functionCall part is visible');
  like($text, qr/Kiel: windy, 17C/, 'gemini functionResponse flattened');
};

subtest 'session history query filters on rendered payload' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  push @{$raider->session_history}, mixed_wire_history();

  my @warnings;
  my ( $hamburg, $kiel );
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $hamburg = $raider->_query_session_history_f({ query => 'Hamburg' })->get;
    $kiel    = $raider->_query_session_history_f({ query => 'Kiel: windy' })->get;
  }
  is(scalar @warnings, 0, 'no warnings while filtering mixed-wire history')
    or diag("warnings: @warnings");

  like($hamburg, qr/Hamburg/, 'filter matches inside responses items');
  unlike($hamburg, qr/Berlin/, 'filter excludes non-matching elements');
  like($kiel, qr/Kiel: windy, 17C/, 'filter reaches into gemini functionResponse text');
};

# Since langertha k344 a tool result that carries an image goes out natively on
# two wires when the model claims image_input (Langertha::ToolResult
# to_responses / to_gemini): the Responses function_call_output.output becomes
# an input_text / input_image part array instead of a string, and Gemini 3
# moves the image into functionResponse.parts[].inlineData next to the
# `result` string. Neither may render as an empty "tool_result:" -- the text
# stays readable and the image shows up as a marker, never as base64.
subtest 'tool-result images from native image wires (k344)' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  my $b64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEAwS2OUAAAAABJRU5ErkJggg==';
  push @{$raider->session_history},
    { type => 'function_call_output', call_id => 'call_img',
      output => [
        { type => 'input_text',  text => 'Screenshot of Luebeck harbour' },
        { type => 'input_image', image_url => "data:image/png;base64,$b64" },
      ] },
    { role => 'user', parts => [
      { functionResponse => { name => 'screenshot', id => 'fc_1',
        response => { result => 'Screenshot of Rostock harbour' },
        parts    => [ { inlineData => { mimeType => 'image/png', data => $b64 } } ] } },
    ] },
    { role => 'user', parts => [
      { functionResponse => { name => 'screenshot', id => 'fc_2',
        response => { result => '' },
        parts    => [ { inlineData => { mimeType => 'image/png', data => $b64 } } ] } },
    ] };

  my @warnings;
  my $text;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $text = $raider->_query_session_history_f({})->get;
  }
  is(scalar @warnings, 0, 'no warnings while rendering tool-result images')
    or diag("warnings: @warnings");

  my @entries = split /\n\n/, $text;
  is(scalar @entries, 3, 'three history elements rendered') or diag($text);

  is($entries[0],
    "[function_call_output] tool_result: Screenshot of Luebeck harbour\n[image]",
    'responses array output: input_text kept, input_image as [image]');
  is($entries[1],
    "[user] tool_result: Screenshot of Rostock harbour\n[image]",
    'gemini functionResponse: result text kept, inlineData part as [image]');
  is($entries[2], '[user] tool_result: [image]',
    'gemini image-only functionResponse still shows the image');

  unlike($text, qr/\Q$b64\E/, 'base64 payload never leaks into the rendering');
  unlike($text, qr/<input_image>|ARRAY\(0x|HASH\(0x/, 'no raw block markers or refs');

  my $filtered = $raider->_query_session_history_f({ query => 'Luebeck' })->get;
  like($filtered, qr/Luebeck harbour/, 'query filter reaches into array output text');
};

# Langertha::ToolResult to_gemini (langertha k336) sends the tool's MCP
# structuredContent as functionResponse.response when it has one -- a hash
# with the tool's own keys and no `result` key. Rendering only {result} would
# turn that into an empty "tool_result:", so the whole structured payload has
# to show up (canonical JSON), and a tool's own `result` key next to other keys
# must not hide them. to_anthropic (langertha k326) maps an MCP image to an
# Anthropic {type => 'image', source => {...}} block, which renders as the same
# [image] marker as the Responses and Gemini images.
subtest 'gemini structured functionResponse and anthropic image block' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  my $b64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEAwS2OUAAAAABJRU5ErkJggg==';
  push @{$raider->session_history},
    { role => 'user', parts => [
      { functionResponse => { name => 'get_weather', id => 'fc_3',
        response => { city => 'Wismar', temp_c => 14, conditions => [ 'fog', 'drizzle' ] } } },
    ] },
    { role => 'user', parts => [
      { functionResponse => { name => 'lookup', id => 'fc_4',
        response => { result => 'found', count => 3 } } },
    ] },
    { role => 'user', content => [
      { type => 'tool_result', tool_use_id => 'toolu_09',
        content => [
          { type => 'text', text => 'Screenshot of Stralsund harbour' },
          { type => 'image',
            source => { type => 'base64', media_type => 'image/png', data => $b64 } },
        ] },
    ] };

  my @warnings;
  my $text;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $text = $raider->_query_session_history_f({})->get;
  }
  is(scalar @warnings, 0, 'no warnings while rendering') or diag("warnings: @warnings");

  my @entries = split /\n\n/, $text;
  is(scalar @entries, 3, 'three history elements rendered') or diag($text);

  is($entries[0],
    '[user] tool_result: {"city":"Wismar","conditions":["fog","drizzle"],"temp_c":14}',
    'gemini structuredContent response without result renders as JSON');
  is($entries[1], '[user] tool_result: {"count":3,"result":"found"}',
    'a structured result key does not hide its sibling keys');
  is($entries[2], "[user] tool_result: Screenshot of Stralsund harbour\n[image]",
    'anthropic tool_result image block renders as [image]');

  unlike($text, qr/\Q$b64\E/, 'base64 payload never leaks into the rendering');
  unlike($text, qr/<image>|ARRAY\(0x|HASH\(0x/, 'no raw block markers or refs');

  my $filtered = $raider->_query_session_history_f({ query => 'Wismar' })->get;
  like($filtered, qr/Wismar/, 'query filter reaches into structured response');
};

# Langertha::ToolResult to_anthropic (langertha k326) maps an MCP embedded text
# resource (or a text/* blob) to an Anthropic {type => 'document', source =>
# {type => 'text', data => ...}} block, and a PDF blob to a base64 document;
# Anthropic-native search_result blocks (source, title, content text blocks)
# pass through. The text the model saw has to stay readable -- a bare
# "<document>" marker loses it -- while a base64 document is named, never
# dumped. The /anthropic shims get a plain text block instead (langertha k364),
# which already renders as its text.
subtest 'anthropic document and search_result blocks' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  my $pdf = 'JVBERi0xLjQKJcOkw7zDtsOfCjIgMCBvYmoKPDwvTGVuZ3RoIDMgMCBSPj4Kc3RyZWFtCg==';
  push @{$raider->session_history},
    { role => 'user', content => [
      { type => 'tool_result', tool_use_id => 'toolu_10',
        content => [
          { type => 'document',
            source => { type => 'text', media_type => 'text/plain',
              data => 'Rostock ferry timetable: 08:15, 12:40' } },
        ] },
    ] },
    { role => 'user', content => [
      { type => 'tool_result', tool_use_id => 'toolu_11',
        content => [
          { type => 'text', text => 'Fetched the report' },
          { type => 'document',
            source => { type => 'base64', media_type => 'application/pdf', data => $pdf } },
        ] },
    ] },
    { role => 'user', content => [
      { type => 'document', title => 'Greifswald notes',
        source => { type => 'text', media_type => 'text/plain', data => 'Dock 3 is closed' } },
    ] },
    { role => 'user', content => [
      { type => 'tool_result', tool_use_id => 'toolu_12',
        content => [
          { type => 'search_result', source => 'https://example.org/usedom',
            title => 'Usedom ferries',
            content => [ { type => 'text', text => 'The Usedom ferry runs hourly' } ],
            citations => { enabled => 1 } },
        ] },
    ] };

  my @warnings;
  my $text;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $text = $raider->_query_session_history_f({})->get;
  }
  is(scalar @warnings, 0, 'no warnings while rendering') or diag("warnings: @warnings");

  my @entries = split /\n\n/, $text;
  is(scalar @entries, 4, 'four history elements rendered') or diag($text);

  is($entries[0], '[user] tool_result: Rostock ferry timetable: 08:15, 12:40',
    'text document renders as its text');
  is($entries[1], "[user] tool_result: Fetched the report\n[document]",
    'base64 document renders as [document]');
  is($entries[2], "[user] [document] Greifswald notes\nDock 3 is closed",
    'titled text document keeps its title and text');
  is($entries[3],
    "[user] tool_result: [search_result] Usedom ferries <https://example.org/usedom>\n"
      . 'The Usedom ferry runs hourly',
    'search_result renders title, source and text');

  unlike($text, qr/\Q$pdf\E/, 'base64 payload never leaks into the rendering');
  unlike($text, qr/<document>|<search_result>|ARRAY\(0x|HASH\(0x/,
    'no raw block markers or refs');

  like($raider->_query_session_history_f({ query => 'timetable' })->get,
    qr/Rostock/, 'query filter reaches into document text');
  like($raider->_query_session_history_f({ query => 'Usedom ferries' })->get,
    qr/example\.org/, 'query filter reaches a search_result title');
};

# Native tool-result PDFs (langertha k361): OpenAI Responses carries an
# input_file part (filename + file_data data: URL) in function_call_output,
# Gemini a functionResponse.parts[].inlineData with mimeType application/pdf.
# Both are named like the Anthropic document, never dumped as <input_file> /
# <block> and never as base64.
subtest 'native tool-result pdf parts' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  my $b64 = 'JVBERi0xLjQKJcOkw7zDtsOfCjIgMCBvYmoKPDwvTGVuZ3RoIDMgMCBSPj4Kc3RyZWFtCg==';
  push @{$raider->session_history},
    { type => 'function_call_output', call_id => 'call_pdf1',
      output => [
        { type => 'input_text', text => 'Fetched the report' },
        { type => 'input_file', filename => 'report.pdf',
          file_data => 'data:application/pdf;base64,' . $b64 },
      ] },
    { type => 'function_call_output', call_id => 'call_pdf2',
      output => [
        { type => 'input_file', file_data => 'data:application/pdf;base64,' . $b64 },
      ] },
    { role => 'user', parts => [
      { functionResponse => { name => 'fetch', response => { result => 'Fetched the report' },
        parts => [ { inlineData => { mimeType => 'application/pdf', data => $b64 } } ] } },
    ] };

  my @warnings;
  my $text;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $text = $raider->_query_session_history_f({})->get;
  }
  is(scalar @warnings, 0, 'no warnings while rendering') or diag("warnings: @warnings");
  like($text, qr/tool_result: Fetched the report\n\[document\] report\.pdf/,
    'input_file renders its filename');
  like($text, qr/tool_result: \[document\](?:\n|$)/m,
    'input_file without filename renders [document]');
  like($text, qr/tool_result: Fetched the report\n\[document\] application\/pdf/,
    'gemini PDF inlineData renders its mime type');
  unlike($text, qr/\Q$b64\E|<input_file>|<block>|ARRAY\(0x|HASH\(0x/,
    'no base64 or raw block markers');
};

# Anthropic custom content documents (Citations) carry their text as a block
# list in source.content -- a string is allowed too -- and any document may
# carry an optional context field the model reads but never cites. Both are
# what the model saw, so the rendering keeps them: the chunks as text, the
# context on its own [context] line; a bare "[document]" would lose them.
subtest 'anthropic content-source document and document context' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  my $pdf = 'JVBERi0xLjQKJcOkw7zDtsOfCjIgMCBvYmoKPDwvTGVuZ3RoIDMgMCBSPj4Kc3RyZWFtCg==';
  push @{$raider->session_history},
    { role => 'user', content => [
      { type => 'tool_result', tool_use_id => 'toolu_20',
        content => [
          { type => 'document', title => 'Stralsund log',
            context => 'Harbour master export, 2026-09',
            source => { type => 'content', content => [
              { type => 'text', text => 'Pier 1 reopened' },
              { type => 'text', text => 'Pier 4 dredging until Friday' },
            ] },
            citations => { enabled => 1 } },
        ] },
    ] },
    { role => 'user', content => [
      { type => 'document',
        source => { type => 'content', content => 'Warnemuende tide table' } },
    ] },
    { role => 'user', content => [
      { type => 'document', context => 'Scanned by the port office',
        source => { type => 'base64', media_type => 'application/pdf', data => $pdf } },
    ] },
    { role => 'user', content => [
      { type => 'document', context => 'Crew roster',
        source => { type => 'text', media_type => 'text/plain', data => 'Anke, Jens' } },
    ] };

  my @warnings;
  my $text;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $text = $raider->_query_session_history_f({})->get;
  }
  is(scalar @warnings, 0, 'no warnings while rendering') or diag("warnings: @warnings");

  my @entries = split /\n\n/, $text;
  is(scalar @entries, 4, 'four history elements rendered') or diag($text);

  is($entries[0],
    "[user] tool_result: [document] Stralsund log\n"
      . "[context] Harbour master export, 2026-09\n"
      . "Pier 1 reopened\nPier 4 dredging until Friday",
    'content-source document keeps title, context and every chunk');
  is($entries[1], '[user] Warnemuende tide table',
    'content-source document with a string content renders as its text');
  is($entries[2], "[user] [document]\n[context] Scanned by the port office",
    'base64 document shows its context, never its data');
  is($entries[3], "[user] [context] Crew roster\nAnke, Jens",
    'text-source document shows its context before its text');

  unlike($text, qr/\Q$pdf\E/, 'base64 payload never leaks into the rendering');
  unlike($text, qr/<document>|ARRAY\(0x|HASH\(0x/, 'no raw block markers or refs');

  like($raider->_query_session_history_f({ query => 'dredging' })->get,
    qr/Stralsund/, 'query filter reaches into content-source chunks');
  like($raider->_query_session_history_f({ query => 'port office' })->get,
    qr/\[context\]/, 'query filter reaches a document context');
};

subtest 'register_session_history_tool renders identically' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  push @{$raider->session_history}, mixed_wire_history();

  my $server = MockToolServer->new;
  $raider->register_session_history_tool($server);
  my $registered = $server->tools->{session_history};
  ok($registered, 'session_history tool registered');

  my @warnings;
  my $result;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $result = $registered->{code}->(MockToolHandle->new, {});
  }
  is(scalar @warnings, 0, 'no warnings from the MCP-registered renderer')
    or diag("warnings: @warnings");

  is($result->{content}[0]{text}, $raider->_query_session_history_f({})->get,
    'both history readers share one renderer');
};

subtest 'empty session history' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  is($raider->_query_session_history_f({})->get, 'No messages in session history.',
    'empty history keeps its placeholder');
};

# --- Test: session-history embeddings (karr #99) ---
#
# _query_session_history_f looks the vector of history element $i up as
# _session_embeddings->[$i], so the two arrays must stay 1:1: a message
# without embeddable text still needs its slot, filled with undef. A missing
# slot shifts every later vector onto the wrong message and the similarity
# search then answers with that wrong message, silently. The embedded text is
# the same rendered payload the grep fallback matches, so both search modes
# see one history element the same way.

{
  package MockEmbeddingEngine;
  use Moose;
  use Future;

  # Deterministic bag-of-words vector over a fixed vocabulary — similar
  # enough to real embeddings to prove the search lands on the right
  # message, without touching the network.
  my @VOCAB = qw( aardvark zebra narwhal tusk berlin weather time );

  has calls  => (is => 'ro', default => sub { [] });
  has die_on => (is => 'ro', predicate => 'has_die_on');

  sub simple_embedding {
    my ( $self, $text ) = @_;
    push @{$self->calls}, $text;
    die "embedding backend unavailable\n"
      if $self->has_die_on && index($text, $self->die_on) >= 0;
    my $lc_text = lc $text;
    return [ map { scalar( () = $lc_text =~ /\Q$_\E/g ) } @VOCAB ];
  }

  # What raider calls: an already-completed Future, so the slot fills at once.
  sub simple_embedding_f {
    my ( $self, $text ) = @_;
    return Future->call(sub { Future->done($self->simple_embedding($text)) });
  }

  __PACKAGE__->meta->make_immutable;
}

# Positions 1 and 3 carry no plain-string {content}: the empty assistant turn
# renders to nothing at all, the responses function_call item has no
# {content} key. Position 2 is anthropic ArrayRef content, which must be
# rendered rather than embedded as "ARRAY(0x...)".
sub embedding_probe_history {
  return (
    { role => 'user', content => 'Aardvark migration question' },
    { role => 'assistant', content => '' },
    { role => 'assistant', content => [
      { type => 'text', text => 'The zebra crossing report' } ] },
    { type => 'function_call', call_id => 'call_9', name => 'get_time',
      arguments => '{"tz":"CET"}' },
    { role => 'assistant', content => 'Narwhal tusk measurements are stable' },
  );
}

subtest 'session embeddings keep one slot per history message' => sub {
  my $embedder = MockEmbeddingEngine->new;
  my $raider = Langertha::Raider->new(
    engine           => MockEngine->new,
    embedding_engine => $embedder,
    raider_mcp       => 1,
  );

  $raider->_push_session_history(embedding_probe_history());
  my @embedded = @{$embedder->calls};

  my @hist = @{$raider->session_history};
  my $slots = $raider->_session_embeddings;
  is(scalar @$slots, scalar @hist, 'one embedding slot per history message');

  for my $i (0..$#hist) {
    my $text = Langertha::Raider::_render_history_payload($hist[$i]);
    if (length $text) {
      is_deeply($slots->[$i], $embedder->simple_embedding($text),
        "slot $i holds the vector of the message at position $i");
    } else {
      is($slots->[$i], undef, "slot $i is undef for a message without text");
    }
  }

  unlike($_, qr/ARRAY\(0x|HASH\(0x/,
    'embedded text is the rendered payload, never a stringified ref')
    for @embedded;
  ok(scalar(grep { /get_time/ } @embedded),
    'an element that is only a tool call is embedded by its rendered call');
};

subtest 'session embedding search returns the matching message' => sub {
  my $raider = Langertha::Raider->new(
    engine           => MockEngine->new,
    embedding_engine => MockEmbeddingEngine->new,
    raider_mcp       => 1,
  );
  $raider->_push_session_history(embedding_probe_history());

  my $text = $raider->_query_session_history_f({ search => 'narwhal tusk' })->get;
  my ( $top ) = split /\n\n/, $text;
  like($top, qr/Narwhal tusk measurements/, 'top hit is the message that matches');
  unlike($top, qr/zebra/, 'not the message a drifted index would have returned');
};

subtest 'drifted embeddings degrade to text search instead of lying' => sub {
  my $raider = Langertha::Raider->new(
    engine           => MockEngine->new,
    embedding_engine => MockEmbeddingEngine->new,
    raider_mcp       => 1,
  );
  $raider->_push_session_history(embedding_probe_history());

  # session_history is public: code outside the pusher can append to it and
  # leave the two arrays out of step.
  push @{$raider->session_history},
    { role => 'assistant', content => 'Berlin weather note' };

  my $text = $raider->_query_session_history_f({ search => 'narwhal tusk' })->get;
  my @hits = split /\n\n/, $text;
  is(scalar @hits, 1, 'falls back to the text search when the arrays drifted');
  like($hits[0], qr/Narwhal tusk measurements/, 'and still finds the right message');
};

subtest 'a failed embedding still leaves its slot' => sub {
  my $raider = Langertha::Raider->new(
    engine           => MockEngine->new,
    embedding_engine => MockEmbeddingEngine->new(die_on => 'zebra'),
    raider_mcp       => 1,
  );
  $raider->_push_session_history(embedding_probe_history());

  is(scalar @{$raider->_session_embeddings}, scalar @{$raider->session_history},
    'a failing embedding leaves an undef slot, not a gap');
  is($raider->_session_embeddings->[2], undef, 'the failed message has no vector');
  ok(defined $raider->_session_embeddings->[4], 'later messages keep their vector');
};

# The compression marker is pushed from compress_history_f, the second writer
# of session_history — it needs its slot like every other message.
{
  package MockCompressionHTTP;
  use Moose;
  use Future;
  sub do_request { return Future->done({ mock => 1 }) }
  __PACKAGE__->meta->make_immutable;
}

{
  package MockCompressionEngine;
  use Moose;
  sub chat_request { return { mock_request => 1 } }
  sub async_request_f { return MockCompressionHTTP->new->do_request }
  sub parse_response { return $_[1] }
  sub response_text_content { return 'compressed summary' }
  __PACKAGE__->meta->make_immutable;
}

subtest 'compression marker gets an embedding slot too' => sub {
  my $raider = Langertha::Raider->new(
    engine             => MockEngine->new,
    compression_engine => MockCompressionEngine->new,
    embedding_engine   => MockEmbeddingEngine->new,
    raider_mcp         => 1,
  );
  $raider->_push_session_history(embedding_probe_history());
  $raider->history([{ role => 'user', content => 'something to summarize' }]);

  is($raider->compress_history, 'compressed summary', 'compression ran');
  like($raider->session_history->[-1]{content}, qr/compressed/i,
    'the marker landed in the session history');
  is(scalar @{$raider->_session_embeddings}, scalar @{$raider->session_history},
    'the marker got its embedding slot');
};

# --- Test: MCP catalog management ---

subtest 'manage MCPs' => sub {
  my $raider = Langertha::Raider->new(
    engine      => MockEngine->new,
    raider_mcp  => 1,
    mcp_catalog => {
      database => { server => 'mock_db', description => 'Database tools', auto => 1 },
      email    => { server => 'mock_email', description => 'Email tools' },
    },
  );

  # Auto-activated MCPs
  ok(exists $raider->_active_catalog_mcps->{database}, 'database auto-activated');
  ok(!exists $raider->_active_catalog_mcps->{email}, 'email not auto-activated');

  # List
  my $result = $raider->_execute_self_tool_f('raider_manage_mcps', {
    action => 'list',
  })->get;
  like($result->{content}[0]{text}, qr/database \[ACTIVE\]/, 'list shows active');
  like($result->{content}[0]{text}, qr/email \[inactive\]/, 'list shows inactive');

  # Activate
  $result = $raider->_execute_self_tool_f('raider_manage_mcps', {
    action => 'activate',
    name   => 'email',
  })->get;
  like($result->{content}[0]{text}, qr/Activated/, 'activate succeeds');
  ok(exists $raider->_active_catalog_mcps->{email}, 'email now active');
  ok($raider->_tools_dirty, 'tools marked dirty after activate');
  $raider->_tools_dirty(0);

  # Deactivate
  $result = $raider->_execute_self_tool_f('raider_manage_mcps', {
    action => 'deactivate',
    name   => 'database',
  })->get;
  like($result->{content}[0]{text}, qr/Deactivated/, 'deactivate succeeds');
  ok(!exists $raider->_active_catalog_mcps->{database}, 'database now inactive');
  ok($raider->_tools_dirty, 'tools marked dirty after deactivate');

  # Error cases
  $result = $raider->_execute_self_tool_f('raider_manage_mcps', {
    action => 'activate',
    name   => 'nonexistent',
  })->get;
  like($result->{content}[0]{text}, qr/not found/, 'activate non-existent fails gracefully');
};

# --- Test: inline tools attribute ---

subtest 'inline tools configuration' => sub {
  my $raider = Langertha::Raider->new(
    engine => MockEngine->new,
    tools  => [{
      name         => 'greet',
      description  => 'Greet someone',
      input_schema => {
        type       => 'object',
        properties => { name => { type => 'string' } },
      },
      code => sub { $_[0]->text_result("Hello $_[1]->{name}!") },
    }],
  );

  is(scalar @{$raider->tools}, 1, 'inline tools stored');
  is($raider->tools->[0]{name}, 'greet', 'tool name preserved');
};

# --- Test: continuation state ---

subtest 'continuation management' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );

  ok(!$raider->has_continuation, 'no continuation initially');

  $raider->_continuation({ test => 'data' });
  ok($raider->has_continuation, 'has continuation after set');

  $raider->clear_continuation;
  ok(!$raider->has_continuation, 'no continuation after clear');
};

# --- Test: cosine similarity ---

subtest 'cosine similarity' => sub {
  # Identical vectors
  my $sim = Langertha::Raider::_cosine_similarity([1, 0, 0], [1, 0, 0]);
  cmp_ok(abs($sim - 1.0), '<', 0.001, 'identical vectors = 1.0');

  # Orthogonal vectors
  $sim = Langertha::Raider::_cosine_similarity([1, 0], [0, 1]);
  cmp_ok(abs($sim), '<', 0.001, 'orthogonal vectors = 0.0');

  # Similar vectors
  $sim = Langertha::Raider::_cosine_similarity([1, 1], [1, 0.9]);
  cmp_ok($sim, '>', 0.9, 'similar vectors have high similarity');

  # Zero vector
  $sim = Langertha::Raider::_cosine_similarity([0, 0], [1, 1]);
  is($sim, 0, 'zero vector returns 0');
};

# --- Test: respond_f continuation across a parallel tool batch (karr #162) ---
#
# When one iteration emits several tool calls and an interactive self-tool
# somewhere in the batch pauses the raid, respond_f must resume WITHOUT re-running
# the calls that already executed, and every tool_use in the batch must end up
# with exactly one matching tool_result — a re-run (double side effect) or a
# tool_use left without a tool_result is a 400 on strict providers like Anthropic.
#
# These drive the real raid_f -> respond_f loop offline through a scripted engine,
# so they exercise the continuation math the isolated _execute_self_tool_f tests
# above never reach.

{
  package SeqResponse;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  package SeqHTTP;
  use Moose;
  use IO::Async::Loop;
  has loop => (is => 'ro', default => sub { IO::Async::Loop->new });
  # A ready, loop-associated future: nothing suspends on it, but any real
  # suspension in the raid (e.g. raider_wait's delay) lands on this same loop.
  sub do_request { return $_[0]->loop->new_future->done(SeqResponse->new) }
  __PACKAGE__->meta->make_immutable;
}

{
  package SeqMCP;
  use Moose;
  use Future;
  has tools    => (is => 'ro', default => sub { [] });
  has call_log => (is => 'ro', default => sub { [] });
  sub list_tools { return Future->done($_[0]->tools) }
  sub call_tool {
    my ( $self, $name, $input ) = @_;
    push @{$self->call_log}, { name => $name, input => $input };
    return Future->done({ content => [{ type => 'text', text => "ran $name" }] });
  }
  __PACKAGE__->meta->make_immutable;
}

# Scripted engine: each LLM turn is popped from `turns` in order. It records every
# result handed to format_tool_results so a test can prove the tool_result set.
{
  package SeqEngine;
  use Moose;
  with 'Langertha::Role::Tools';

  has chat_model     => (is => 'ro', default => 'seq-model');
  has '+mcp_servers' => (default => sub { [] });
  has turns          => (is => 'ro', default => sub { [] });
  has _turn_idx      => (is => 'rw', default => 0);
  has captured       => (is => 'ro', default => sub { [] });
  has _http          => (is => 'ro', lazy => 1, default => sub { SeqHTTP->new });

  sub async_request_f { return $_[0]->_http->do_request }
  sub async_loop      { return $_[0]->_http->loop }

  sub format_tools            { return $_[1] }
  sub build_tool_chat_request { return { request => 1 } }
  sub response_tool_calls     { return $_[1]->{tool_calls} // [] }
  sub response_text_content   { return $_[1]->{text} // 'final answer' }
  sub extract_tool_call       { return ($_[1]->{name}, $_[1]->{input}) }
  sub think_tag_filter        { 0 }

  sub parse_response {
    my ( $self ) = @_;
    my $i = $self->_turn_idx;
    $self->_turn_idx($i + 1);
    return $self->turns->[$i] // { tool_calls => [] };
  }

  sub format_tool_results {
    my ( $self, $data, $results ) = @_;
    push @{$self->captured}, @$results;
    return map {
      { role => 'tool', tool_call_id => ($_->{tool_call}{id} // ''),
        content => $_->{result} }
    } @$results;
  }

  __PACKAGE__->meta->make_immutable;
}

# How many tool_result blocks carry each tool_use id, across every
# format_tool_results call the engine saw during the whole raid.
sub result_id_counts {
  my ( $engine ) = @_;
  my %count;
  $count{ $_->{tool_call}{id} // '' }++ for @{$engine->captured};
  return \%count;
}

subtest 'respond_f does not re-run an already-executed tool from the batch' => sub {
  my $mcp = SeqMCP->new(tools => [{ name => 'record' }]);
  my $engine = SeqEngine->new(
    mcp_servers => [$mcp],
    turns => [
      # iteration 1: the model runs `record`, then asks the user (pauses)
      { tool_calls => [
        { name => 'record',          input => { note => 'x' }, id => 'tc_rec' },
        { name => 'raider_ask_user', input => { question => 'Proceed?' }, id => 'tc_ask' },
      ] },
      # iteration 2 (after respond_f): the model is done
      { tool_calls => [], text => 'all done' },
    ],
  );
  my $raider = Langertha::Raider->new(engine => $engine, raider_mcp => 1);

  my $r1 = $raider->raid('record it, then ask me');
  ok($r1->is_question, 'the batch pauses on raider_ask_user');
  is($r1->content, 'Proceed?', 'the question text surfaces');
  is(scalar @{$mcp->call_log}, 1, 'record ran once before the pause');

  my $r2 = $raider->respond('yes, go ahead');
  ok($r2->is_final, 'respond_f resumes to a final answer');
  is("$r2", 'all done', 'final text is the second turn');

  is(scalar @{$mcp->call_log}, 1, 'record was NOT run a second time on resume');

  my $counts = result_id_counts($engine);
  is($counts->{tc_rec}, 1, 'exactly one tool_result for the record call');
  is($counts->{tc_ask}, 1, 'exactly one tool_result for the ask_user call');
  ok(!(grep { $_ != 1 } values %$counts), 'every tool_use id has exactly one tool_result');
};

subtest 'respond_f leaves a trailing raider_wait with a tool_result' => sub {
  my $mcp = SeqMCP->new(tools => [{ name => 'record' }]);
  my $engine = SeqEngine->new(
    mcp_servers => [$mcp],
    turns => [
      # iteration 1: record, ask (pauses), and a wait queued AFTER the pause
      { tool_calls => [
        { name => 'record',          input => { note => 'y' }, id => 'tc_rec' },
        { name => 'raider_ask_user', input => { question => 'OK?' }, id => 'tc_ask' },
        { name => 'raider_wait',     input => { seconds => 0 },       id => 'tc_wait' },
      ] },
      { tool_calls => [], text => 'finished' },
    ],
  );
  my $raider = Langertha::Raider->new(engine => $engine, raider_mcp => 1);

  ok($raider->raid('do the batch')->is_question, 'pauses on ask_user');
  my $r2 = $raider->respond('continue');
  ok($r2->is_final, 'resumes past the trailing wait to final');

  is(scalar @{$mcp->call_log}, 1, 'record still ran only once');

  my $counts = result_id_counts($engine);
  is($counts->{tc_rec},  1, 'record has its tool_result');
  is($counts->{tc_ask},  1, 'ask_user has its tool_result');
  is($counts->{tc_wait}, 1, 'the trailing raider_wait got a tool_result too');
  ok(!(grep { $_ != 1 } values %$counts), 'no tool_use left without a tool_result');
};

# Auto-compression keys on the last reported prompt size. Usage comes from
# Langertha::Usage->from_raw (k195), which yields input_tokens 0 when a body has
# usage but no prompt count: that 0 must not overwrite the last real count, or
# a provider omitting the key would switch auto-compression off.
subtest 'last prompt tokens: a usage without a prompt count keeps the old value' => sub {
  my $turn = sub { { tool_calls => [], text => 'ok', @_ } };
  my $engine = SeqEngine->new(turns => [
    $turn->(usage => { prompt_tokens => 42, completion_tokens => 1 }),
    $turn->(usage => { completion_tokens => 5 }),
    $turn->(),
    $turn->(usageMetadata => { promptTokenCount => 77, candidatesTokenCount => 3 }),
  ]);
  my $raider = Langertha::Raider->new(engine => $engine, raider_mcp => 1);

  $raider->raid('one');
  is($raider->_last_prompt_tokens, 42, 'prompt count recorded');
  $raider->raid('two');
  is($raider->_last_prompt_tokens, 42, 'usage without a prompt count does not reset it to 0');
  $raider->raid('three');
  is($raider->_last_prompt_tokens, 42, 'a body without usage leaves it alone');
  $raider->raid('four');
  is($raider->_last_prompt_tokens, 77, 'gemini usageMetadata prompt count recorded');
};

subtest 'raider_wait runs when the engine has no event loop' => sub {
  my $engine = SeqEngine->new(turns => [
    { tool_calls => [ { name => 'raider_wait', input => { seconds => 0 }, id => 'tc_wait' } ] },
    { tool_calls => [], text => 'waited' },
  ]);
  no warnings 'redefine';
  local *SeqEngine::async_loop = sub { undef };   # sync fallback: core promises no loop
  my $r = Langertha::Raider->new(engine => $engine, raider_mcp => 1)->raid('wait a bit');
  is("$r", 'waited', 'wait fell back to the process-wide loop');
  is(result_id_counts($engine)->{tc_wait}, 1, 'the wait got its tool_result');
};

# respond_f runs the rest of a paused batch through its own raider_wait site;
# it needs the same fallback when the engine has no loop.
subtest 'respond_f runs a trailing raider_wait when the engine has no event loop' => sub {
  my $engine = SeqEngine->new(turns => [
    { tool_calls => [
      { name => 'raider_ask_user', input => { question => 'OK?' }, id => 'tc_ask' },
      { name => 'raider_wait',     input => { seconds => 0 },     id => 'tc_wait' },
    ] },
    { tool_calls => [], text => 'resumed' },
  ]);
  no warnings 'redefine';
  local *SeqEngine::async_loop = sub { undef };
  my $raider = Langertha::Raider->new(engine => $engine, raider_mcp => 1);
  ok($raider->raid('ask then wait')->is_question, 'pauses on ask_user');
  my $r = $raider->respond('go');
  is("$r", 'resumed', 'the wait after the pause fell back to the process-wide loop');
  is(result_id_counts($engine)->{tc_wait}, 1, 'the wait got its tool_result');
};

subtest 'respond_f re-pauses on a second interactive self-tool in the batch' => sub {
  my $engine = SeqEngine->new(
    turns => [
      # iteration 1: two questions queued back to back
      { tool_calls => [
        { name => 'raider_ask_user', input => { question => 'First?' },  id => 'tc_q1' },
        { name => 'raider_ask_user', input => { question => 'Second?' }, id => 'tc_q2' },
      ] },
      { tool_calls => [], text => 'both answered' },
    ],
  );
  my $raider = Langertha::Raider->new(engine => $engine, raider_mcp => 1);

  my $r1 = $raider->raid('ask me twice');
  ok($r1->is_question, 'pauses on the first question');
  is($r1->content, 'First?', 'first question surfaces');

  my $r2 = $raider->respond('answer one');
  ok($r2->is_question, 'respond_f re-pauses on the second question');
  is($r2->content, 'Second?', 'second question surfaces after the first answer');

  my $r3 = $raider->respond('answer two');
  ok($r3->is_final, 'the second respond_f reaches the final answer');
  is("$r3", 'both answered', 'final text after both questions');

  my $counts = result_id_counts($engine);
  is($counts->{tc_q1}, 1, 'first question has one tool_result');
  is($counts->{tc_q2}, 1, 'second question has one tool_result');
  ok(!(grep { $_ != 1 } values %$counts), 'each question answered exactly once');
};

# --- Test: plugin_before_llm_call conversation must not diverge from the
#          continuation state across a pause / respond_f (karr #171) ---
#
# plugin_before_llm_call($conversation, $iteration) -> $conversation is
# documented to return the (possibly transformed) conversation the loop then
# proceeds with. A plugin that returns a FRESH arrayref — the normal transform
# contract — used to leave $state->{conversation} pointing at the pre-plugin
# array. On a pause, respond_f resumes from $state->{conversation}, so the
# resumed raid reverted to that stale array and dropped every assistant /
# tool_result message accumulated in earlier iterations. This drives the real
# raid_f -> respond_f loop offline and proves the earlier tool result survives
# the resume.

{
  package ConvReplacePlugin;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  # Snapshot of the conversation handed to us on each call, newest last.
  has seen => (is => 'ro', default => sub { [] });

  async sub plugin_before_llm_call {
    my ( $self, $conversation, $iteration ) = @_;
    push @{$self->seen}, [ @$conversation ];
    # Return a fresh arrayref, exactly as a transforming plugin would.
    return [ @$conversation ];
  }

  __PACKAGE__->meta->make_immutable;
}

# Scripted engine that records the conversation it is asked to send on every
# LLM turn, so a test can prove what the loop actually forwarded.
{
  package ConvCaptureEngine;
  use Moose;
  with 'Langertha::Role::Tools';

  has chat_model     => (is => 'ro', default => 'cap-model');
  has '+mcp_servers' => (default => sub { [] });
  has turns          => (is => 'ro', default => sub { [] });
  has _turn_idx      => (is => 'rw', default => 0);
  has sent           => (is => 'ro', default => sub { [] });
  has _http          => (is => 'ro', lazy => 1, default => sub { SeqHTTP->new });

  sub async_request_f { return $_[0]->_http->do_request }
  sub async_loop      { return $_[0]->_http->loop }

  sub format_tools          { return $_[1] }
  sub response_tool_calls   { return $_[1]->{tool_calls} // [] }
  sub response_text_content { return $_[1]->{text} // 'final answer' }
  sub extract_tool_call     { return ($_[1]->{name}, $_[1]->{input}) }
  sub think_tag_filter      { 0 }

  sub build_tool_chat_request {
    my ( $self, $conversation, $tools ) = @_;
    push @{$self->sent}, [ @$conversation ];
    return { request => 1 };
  }

  sub parse_response {
    my ( $self ) = @_;
    my $idx = $self->_turn_idx;
    $self->_turn_idx($idx + 1);
    return $self->turns->[$idx] // { tool_calls => [] };
  }

  # Realistic echo: an assistant message carrying the calls, then one tool
  # message per result, both tagged with the tool_use id.
  sub format_tool_results {
    my ( $self, $data, $results ) = @_;
    my @msgs = ({
      role       => 'assistant',
      content    => '',
      tool_calls => [ map {
        { id => ($_->{tool_call}{id} // ''), name => $_->{tool_call}{name} }
      } @$results ],
    });
    push @msgs, map {
      { role => 'tool', tool_call_id => ($_->{tool_call}{id} // ''),
        content => 'ran ' . $_->{tool_call}{name} }
    } @$results;
    return @msgs;
  }

  __PACKAGE__->meta->make_immutable;
}

# True if any message in $conversation references tool_use id $id, either as an
# assistant echo entry or as a tool_result.
sub conv_carries_id {
  my ( $conversation, $id ) = @_;
  for my $msg (@$conversation) {
    next unless ref $msg eq 'HASH';
    return 1 if ($msg->{tool_call_id} // '') eq $id;
    if (ref $msg->{tool_calls} eq 'ARRAY') {
      return 1 if grep { ($_->{id} // '') eq $id } @{$msg->{tool_calls}};
    }
  }
  return 0;
}

subtest 'plugin_before_llm_call conversation survives a pause and respond_f' => sub {
  my $mcp = SeqMCP->new(tools => [{ name => 'record' }]);
  my $engine = ConvCaptureEngine->new(
    mcp_servers => [$mcp],
    turns => [
      # iteration 1: run a normal MCP tool — its result must outlive the pause
      { tool_calls => [
        { name => 'record', input => { note => 'first' }, id => 'tc_rec' } ] },
      # iteration 2: ask the user — pauses the raid
      { tool_calls => [
        { name => 'raider_ask_user', input => { question => 'Proceed?' }, id => 'tc_ask' } ] },
      # iteration 3 (after respond_f): done
      { tool_calls => [], text => 'all done' },
    ],
  );
  my $raider = Langertha::Raider->new(
    engine     => $engine,
    raider_mcp => 1,
    plugins    => ['ConvReplacePlugin'],
  );

  my $r1 = $raider->raid('record, then ask me');
  ok($r1->is_question, 'the raid pauses on raider_ask_user at iteration 2');
  ok(conv_carries_id($engine->sent->[1], 'tc_rec'),
    'iteration 2 already forwards the record result (loop-local state is fine pre-pause)');

  my $r2 = $raider->respond('yes, continue');
  ok($r2->is_final, 'respond_f resumes to a final answer');
  is("$r2", 'all done', 'final text is the third turn');

  # The conversation forwarded to the LLM after the resume must still carry the
  # iteration-1 record result. Under the divergence it reverted to the stale
  # pre-plugin array and dropped it.
  ok(conv_carries_id($engine->sent->[-1], 'tc_rec'),
    'the post-resume LLM conversation still contains the iteration-1 record result');
  ok(conv_carries_id($engine->sent->[-1], 'tc_ask'),
    'and it contains the answered ask_user turn');

  # The plugin and the loop share one conversation: the plugin's view on the
  # resumed iteration is the same complete conversation the loop proceeds with.
  my $plugin = $raider->plugin_instances->[0];
  ok(conv_carries_id($plugin->seen->[-1], 'tc_rec'),
    'plugin_before_llm_call sees the record result on the resumed iteration');
};

done_testing;
