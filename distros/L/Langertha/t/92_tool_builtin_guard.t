#!/usr/bin/env perl
# ABSTRACT: Non-function tool hashes are classified, and fail loud instead of vanishing

use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;
use Langertha::Tool;
use Langertha::Engine::OpenAIResponses;

# Why (karr k210, ADR 0001): a tool hash that is not a function tool used to be
# silently dropped by Tool->from_hash ({type=>'web_search'}, Gemini's keyed
# {google_search=>{}}, {functionDeclarations=>[...]}) or silently turned into
# a *function* tool ({type=>'web_search_20250305', name=>'web_search'}), so the
# request quietly lost its meaning. Tool->classify now names what a hash is
# (function / server / client_builtin / foreign / unknown) without croaking --
# sibling gateways map it to a 400 (k216) -- and the Tool door croaks on every
# category but `function`, from the same classification. Server-side tools get
# their own value object with k206.
#
# `type` other than `function` does NOT mean "server-side": on /v1/responses
# local_shell, computer, computer_use_preview, apply_patch, a local shell and a
# client tool_search run on the client (llm-advisor, OpenAI create-response
# reference, 2026-09-25). The Responses envelope therefore decides per item by
# a denylist: those croak, another wire's built-ins croak, and every other
# typed item goes out verbatim (spec k206 section 3.4, values open) -- so a
# dated web_search_2025_08_26, a hosted shell (container_auto /
# container_reference) or a future type still reaches the provider, which
# judges it. A shell is client-executed unless its environment is one of those
# two containers, so a bare or local shell croaks. The envelope used to decide
# for the WHOLE list from the first item only: a typed item first sent an MCP
# tool unformatted (400), an MCP tool first dropped a built-in and turned
# custom / namespace into function tools.

my $server = sub { my $w = shift; qr/is a server-side tool \($w\)/ };
my $client = sub { my $w = shift; qr/is a client-executed built-in tool \($w\), not a server tool/ };
my $unsupported = qr/unsupported tool type/;
my $nameless    = qr/no type and no name/;

# [ hash, classify(), wire, classify($h,'responses'), croak regex, Responses envelope ]
my @table = (
  # Responses server-side: verbatim on the Responses wire
  map( { [ $_, server => 'responses', 'server', $server->('responses'), 'verbatim' ] }
    { type => 'web_search' },
    { type => 'web_search_preview_2025_03_11' },
    { type => 'web_search_2025_08_26' },
    { type => 'file_search', vector_store_ids => ['vs'] },
    { type => 'code_interpreter', container => { type => 'auto' } },
    { type => 'image_generation' },
    # require_approval => 'never': OpenAIResponses refuses anything else (k206)
    { type => 'mcp', server_label => 's', server_url => 'https://x', require_approval => 'never' },
    { type => 'x_search' },
    { type => 'collections_search' },
    { type => 'tool_search' },
    { type => 'tool_search', execution => 'server' },
    { type => 'shell', environment => { type => 'container_auto' } },
    { type => 'shell', environment => { type => 'container_reference', container_id => 'c' } },
  ),
  # Responses client-executed built-ins: croak on the Responses wire too
  map( { [ $_, client_builtin => 'responses', 'client_builtin', $client->('responses'), 'croak' ] }
    { type => 'local_shell' },
    { type => 'computer' },
    { type => 'computer_use_preview', display_width => 1024 },
    { type => 'apply_patch' },
    { type => 'shell', environment => { type => 'local' } },
    { type => 'shell' },
    { type => 'shell', environment => { type => 'something_new' } },
    { type => 'tool_search', execution => 'client' },
  ),
  # Anthropic built-ins: foreign on the Responses wire, so they croak there
  map( { [ $_, server => 'anthropic', 'foreign', $server->('anthropic'), 'croak' ] }
    { type => 'web_search_20250305', name => 'web_search', max_uses => 3 },
    { type => 'web_fetch_20250910', name => 'web_fetch' },
    { type => 'code_execution_20250825', name => 'code_execution' },
    { type => 'tool_search_tool_regex_20251119', name => 'tool_search' },
    { type => 'mcp_toolset', mcp_server_name => 's' },
  ),
  map( { [ $_, client_builtin => 'anthropic', 'foreign', $client->('anthropic'), 'croak' ] }
    { type => 'bash_20250124', name => 'bash' },
    { type => 'text_editor_20250728', name => 'str_replace_based_edit_tool' },
    { type => 'computer_20250124', name => 'computer' },
    { type => 'memory_20250818', name => 'memory' },
  ),
  # Gemini keyed built-ins (untyped): foreign on the Responses wire
  map( { [ $_, server => 'gemini', 'foreign', $server->('gemini'), 'croak' ] }
    { google_search => {} },
    { googleSearch => {} },
    { google_search_retrieval => {} },
    { code_execution => {} },
    { url_context => {} },
    { google_maps => {} },
    { enterprise_web_search => {} },
    { file_search => { file_search_store_names => ['s'] } },
    { retrieval => {} },
  ),
  [ { computer_use => { environment => 'ENVIRONMENT_BROWSER' } },
    client_builtin => 'gemini', 'foreign', $client->('gemini'), 'croak' ],
  # Typed, not recognised: croak at the Tool door, verbatim on the Responses wire
  map( { [ $_, unknown => undef, 'unknown', $unsupported, 'verbatim' ] }
    { type => 'custom', name => 'sql', format => { type => 'grammar' } },
    { type => 'namespace', name => 'ns', tools => [] },
    { type => 'programmatic_tool_calling' },
    { type => 'frobnicate', name => 'x' },
  ),
  # Untyped and nameless: croak everywhere
  map( { [ $_, unknown => undef, 'unknown', $nameless, 'croak' ] }
    { functionDeclarations => [ { name => 'f', parameters => { type => 'object' } } ] },
    { description => 'no name' },
    {},
  ),
);

my $mcp = { name => 'echo', description => 'Echo', inputSchema => { type => 'object', properties => {} } };
my $json    = JSON::MaybeXS->new->canonical(1)->utf8(1);
my $engine  = Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.5-pro' );
my $want_fn = { type => 'function', name => 'echo', description => 'Echo',
                parameters => { type => 'object', properties => {} } };

sub croaks_like {
  my ( $code, $re, $label ) = @_;
  my $err;
  eval { $code->(); 1 } or $err = $@;
  like( $err, $re, $label );
}

sub responses_tools {
  my ($tools) = @_;
  my $req = $engine->chat_request( [ { role => 'user', content => 'hi' } ], tools => $tools );
  return $json->decode( $req->content )->{tools};
}

for my $row (@table) {
  my ( $hash, $category, $wire, $on_responses, $err_re, $envelope ) = @$row;
  subtest $json->encode($hash) => sub {
    is( scalar Langertha::Tool->classify($hash), $category, "classify: $category" );
    my ( undef, $got_wire ) = Langertha::Tool->classify($hash);
    is( $got_wire, $wire, 'classify: wire' );
    is( scalar Langertha::Tool->classify( $hash, 'responses' ), $on_responses,
      "classify(responses): $on_responses" );

    croaks_like( sub { Langertha::Tool->from_hash($hash) }, $err_re, 'from_hash croaks' );
    for my $order ( [ $hash, $mcp ], [ $mcp, $hash ] ) {
      croaks_like( sub { Langertha::Tool->from_list($order) }, $err_re, 'from_list croaks on a mixed list' );
      for my $fmt (qw( openai anthropic gemini responses )) {
        # k206: a server tool of the wire being formatted is a
        # Langertha::ServerTool and keeps its place, verbatim.
        if ( $fmt eq 'responses' && $on_responses eq 'server' ) {
          is_deeply( Langertha::Tool->format_list( $fmt, $order ),
            [ map { $_ == $mcp ? $want_fn : $hash } @$order ], 'format_list(responses) keeps it (k206)' );
          next;
        }
        croaks_like( sub { Langertha::Tool->format_list( $fmt, $order ) }, $err_re,
          "format_list($fmt) croaks" );
      }
    }

    if ( $envelope eq 'verbatim' ) {
      is_deeply( responses_tools( [ $hash, $mcp ] ), [ $hash, $want_fn ], 'Responses: first, verbatim' );
      is_deeply( responses_tools( [ $mcp, $hash ] ), [ $want_fn, $hash ], 'Responses: second, verbatim' );
    }
    else {
      croaks_like( sub { responses_tools( [ $hash, $mcp ] ) }, $err_re, 'Responses: croaks first' );
      croaks_like( sub { responses_tools( [ $mcp, $hash ] ) }, $err_re, 'Responses: croaks second' );
    }
  };
}

subtest 'classify never croaks on odd input' => sub {
  is( scalar Langertha::Tool->classify(undef),    'unknown', 'undef' );
  is( scalar Langertha::Tool->classify('string'), 'unknown', 'plain string' );
  is( scalar Langertha::Tool->classify( [] ),     'unknown', 'array ref' );
  is( scalar Langertha::Tool->classify( Langertha::Tool->new( name => 'x' ) ), 'function', 'Tool object' );
};

subtest 'classify: foreign for any other $fmt, carp once on an unknown $fmt' => sub {
  my $ws = { type => 'web_search' };
  is( scalar Langertha::Tool->classify( $ws, $_ ), 'foreign', "web_search on $_ is foreign" )
    for qw( openai anthropic gemini ollama hermes );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  is( scalar Langertha::Tool->classify( $ws, 'reponses' ), 'foreign', 'typo fmt: foreign' );
  Langertha::Tool->classify( $ws, 'reponses' );
  is( scalar @warnings, 1, 'carped once for the unknown fmt' );
  like( $warnings[0] // '', qr/unknown tool_wire_format 'reponses'/, 'carp names it' );
  Langertha::Tool->classify( $ws, 'responses' );
  is( scalar @warnings, 1, 'no carp for a known fmt' );
};

subtest 'Responses envelope: function-tool forms per item' => sub {
  # An already flat Responses function tool stays verbatim wherever it sits;
  # every other function-tool form is formatted.
  my $flat = { type => 'function', name => 'flat', parameters => { type => 'object' } };
  is_deeply( responses_tools( [
    $flat,
    { type => 'function', function => { name => 'echo', description => 'Echo' } },
    Langertha::Tool->new( name => 'echo', description => 'Echo' ),
    { type => 'custom', name => 'echo', description => 'Echo', input_schema => { type => 'object', properties => {} } },
  ] ), [ $flat, $want_fn, $want_fn, $want_fn ],
    'flat function verbatim; nested OpenAI, Tool object, Anthropic custom formatted' );
};

done_testing;
