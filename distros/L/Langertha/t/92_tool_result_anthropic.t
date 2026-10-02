#!/usr/bin/env perl
# ABSTRACT: ToolResult->to('anthropic') maps MCP content blocks onto Anthropic tool_result blocks
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::ToolResult;
use Langertha::Engine::Anthropic;
use Langertha::Engine::MiniMaxAnthropic;
use Langertha::Engine::MoonshotAnthropic;
use Langertha::Engine::AKIAnthropic;
use Langertha::Engine::LMStudioAnthropic;

# Why (karr k326): a tool_result's content goes onto the Anthropic wire, which
# takes only text | image | document | search_result blocks and rejects unknown
# fields ("Extra inputs are not permitted"). MCP content is not that shape: an
# MCP image is {type,data,mimeType}, text may carry annotations/_meta, and
# resource / resource_link / audio have no Anthropic type. Embedded verbatim, the
# next tool-loop turn 400s the moment an MCP tool returns an image or annotated
# text. The mapping follows anthropic-sdk-python lib/tools/mcp.py, except that
# nothing dies mid-loop: what Anthropic cannot carry becomes a text placeholder.
#
# Since k359 an MCP image becomes an image block only with image_input => 1
# (the model sees images; t/92_tool_result_images.t), so the image cases here
# ask for it. Since k364/k366 source_blocks => 0 keeps Anthropic's source
# blocks (document, search_result) off wires that reject them: AKI's /anthropic
# shim answers either inside a tool_result with HTTP 529 "Unsupported content
# type: document" / "... search_result" (live probes 2026-09-30, and 529 is
# deterministic there, not a retry signal), and Kimi's Messages schema lists
# only text | image in tool_result. Without the fix, every tool-loop turn in
# which an MCP tool returns an embedded text resource breaks on those shims.

my $PNG = 'iVBORw0KGgo=';

sub content_of {
  my (@blocks) = @_;
  return Langertha::ToolResult->new( id => 'toolu_1', content => \@blocks )
    ->to( 'anthropic', image_input => 1 )->{content};
}

sub content_without_source_blocks {
  my (@blocks) = @_;
  return Langertha::ToolResult->new( id => 'toolu_1', content => \@blocks )
    ->to( 'anthropic', image_input => 1, source_blocks => 0 )->{content};
}

my $SEARCH_RESULT = { type => 'search_result', source => 'https://e.com/q', title => 'Quelltown',
  content => [ { type => 'text', text => 'Population 12' } ] };

subtest 'text keeps only type, text and cache_control' => sub {
  is_deeply(
    content_of( { type => 'text', text => 'here',
      annotations => { audience => ['user'], priority => 0.5 }, _meta => { x => 1 } } ),
    [ { type => 'text', text => 'here' } ],
    'annotations and _meta stripped' );
  is_deeply(
    content_of( { type => 'text', text => 'c', cache_control => { type => 'ephemeral' } } ),
    [ { type => 'text', text => 'c', cache_control => { type => 'ephemeral' } } ],
    'cache_control kept' );
};

subtest 'MCP image becomes a base64 image block' => sub {
  is_deeply(
    content_of( { type => 'image', data => $PNG, mimeType => 'image/png',
      annotations => { priority => 1 } } ),
    [ { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } } ],
    'png image' );
  for my $mime (qw( image/jpeg image/gif image/webp )) {
    is( content_of( { type => 'image', data => $PNG, mimeType => $mime } )->[0]{source}{media_type},
      $mime, "$mime accepted" );
  }
  my $bmp = content_of( { type => 'image', data => $PNG, mimeType => 'image/bmp' } );
  is( $bmp->[0]{type}, 'text', 'unsupported image MIME becomes text' );
  like( $bmp->[0]{text}, qr/image\/bmp/, 'placeholder names the MIME' );
  unlike( $bmp->[0]{text}, qr/\Q$PNG\E/, 'placeholder carries no base64' );
};

subtest 'embedded resources' => sub {
  is_deeply(
    content_of( { type => 'resource',
      resource => { uri => 'file:///a.png', mimeType => 'image/png', blob => $PNG } } ),
    [ { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } } ],
    'image blob becomes an image block' );
  is_deeply(
    content_of( { type => 'resource',
      resource => { uri => 'file:///a.pdf', mimeType => 'application/pdf', blob => 'JVBERi0=' } } ),
    [ { type => 'document',
        source => { type => 'base64', media_type => 'application/pdf', data => 'JVBERi0=' } } ],
    'pdf blob becomes a base64 document' );
  is_deeply(
    content_of( { type => 'resource',
      resource => { uri => 'file:///a.md', mimeType => 'text/markdown', text => '# hi' } } ),
    [ { type => 'document', source => { type => 'text', media_type => 'text/plain', data => '# hi' } } ],
    'text/* resource becomes a text document' );
  is_deeply(
    content_of( { type => 'resource', resource => { uri => 'mem://x', text => 'plain' } } ),
    [ { type => 'document', source => { type => 'text', media_type => 'text/plain', data => 'plain' } } ],
    'resource without MIME becomes a text document' );
  # k336: text is text whatever its MIME type -- a JSON resource or a base64
  # text/* blob reaches the model as a text document, not a placeholder.
  is_deeply(
    content_of( { type => 'resource',
      resource => { uri => 'mem://j', mimeType => 'application/json', text => '{"a":1}' } } ),
    [ { type => 'document', source => { type => 'text', media_type => 'text/plain', data => '{"a":1}' } } ],
    'text resource with a non-text MIME becomes a text document' );
  is_deeply(
    content_of( { type => 'resource',
      resource => { uri => 'file:///k.txt', mimeType => 'text/plain', blob => 'S8O2bG4=' } } ),
    [ { type => 'document', source => { type => 'text', media_type => 'text/plain', data => "K\x{f6}ln" } } ],
    'text/* blob decodes as UTF-8 into a text document' );
  my $zip = content_of( { type => 'resource',
    resource => { uri => 'file:///a.zip', mimeType => 'application/zip', blob => 'UEsDBA==' } } );
  is( $zip->[0]{type}, 'text', 'unsupported blob becomes text' );
  like( $zip->[0]{text}, qr/application\/zip/, 'placeholder names the MIME' );
  like( $zip->[0]{text}, qr{file:///a\.zip}, 'placeholder names the URI' );
  unlike( $zip->[0]{text}, qr/UEsDBA/, 'placeholder carries no base64' );
};

subtest 'resource_link and audio become text placeholders' => sub {
  my $link = content_of( { type => 'resource_link', uri => 'file:///r.txt', name => 'r.txt',
    mimeType => 'text/plain' } );
  is_deeply( $link, [ { type => 'text', text => '[resource_link] r.txt <file:///r.txt>' } ],
    'resource_link names name and uri' );
  my $audio = content_of( { type => 'audio', data => 'UklGRg==', mimeType => 'audio/wav' } );
  is( $audio->[0]{type}, 'text', 'audio becomes text' );
  like( $audio->[0]{text}, qr/audio/, 'placeholder names the type' );
  like( $audio->[0]{text}, qr{audio/wav}, 'placeholder names the MIME' );
  unlike( $audio->[0]{text}, qr/UklGRg/, 'placeholder carries no base64' );
  is( content_of( { type => 'mystery', foo => 1 } )->[0]{type}, 'text',
    'an unknown type becomes text' );
};

subtest 'Anthropic-native blocks pass through' => sub {
  my $img = { type => 'image', source => { type => 'url', url => 'https://x/y.png' } };
  is_deeply( content_of($img), [$img], 'image with source kept' );
  my $doc = { type => 'document', source => { type => 'text', media_type => 'text/plain', data => 'd' } };
  is_deeply( content_of($doc), [$doc], 'document with source kept' );
};

subtest 'source_blocks => 0: text documents inline as text, PDFs become placeholders' => sub {
  is_deeply(
    content_without_source_blocks( { type => 'resource',
      resource => { uri => 'file:///a.md', mimeType => 'text/markdown', text => '# hi' } } ),
    [ { type => 'text', text => '# hi' } ],
    'a text resource becomes a text block (as on the string wires)' );
  is_deeply(
    content_without_source_blocks( { type => 'resource',
      resource => { uri => 'file:///k.txt', mimeType => 'text/plain', blob => 'S8O2bG4=' } } ),
    [ { type => 'text', text => "K\x{f6}ln" } ],
    'a text/* blob decodes into a text block' );
  is_deeply(
    content_without_source_blocks( { type => 'resource',
      resource => { uri => 'file:///a.pdf', mimeType => 'application/pdf', blob => 'JVBERi0=' } } ),
    [ { type => 'text', text => '[resource] application/pdf <file:///a.pdf> (5 bytes)' } ],
    'a PDF blob becomes the k336 placeholder, never the base64' );
  is_deeply(
    content_without_source_blocks(
      { type => 'document', source => { type => 'text', media_type => 'text/plain', data => 'd' } } ),
    [ { type => 'text', text => 'd' } ],
    'a native text document becomes its text: the wire rejects the block type itself' );
  is_deeply(
    content_without_source_blocks(
      { type => 'document', source => { type => 'base64', media_type => 'application/pdf', data => 'JVBERi0=' } } ),
    [ { type => 'text', text => '[document] application/pdf' } ],
    'a native PDF document becomes a placeholder' );
  my $img = { type => 'image', source => { type => 'url', url => 'https://x/y.png' } };
  is_deeply( content_without_source_blocks($img), [$img], 'a native image block is untouched' );
  is( content_without_source_blocks( { type => 'image', data => $PNG, mimeType => 'image/png' } )->[0]{type},
    'image', 'an MCP image still follows image_input only' );
  is_deeply(
    content_without_source_blocks( { type => 'document', source => { type => 'content', content => [
      { type => 'text', text => 'one' }, { type => 'text', text => 'two' } ] } } ),
    [ { type => 'text', text => "one\ntwo" } ],
    'a native content document becomes its inner text (k367)' );
  is_deeply( content_without_source_blocks($SEARCH_RESULT),
    [ { type => 'text', text => "[search_result] Quelltown <https://e.com/q>\nPopulation 12" } ],
    'a native search_result becomes a text block with title, source and text (k366)' );
  is_deeply(
    Langertha::ToolResult->new( id => 't', content => [ { type => 'resource',
      resource => { uri => 'mem://x', text => 'plain' } } ] )->to( 'anthropic', source_blocks => 1 )->{content},
    [ { type => 'document', source => { type => 'text', media_type => 'text/plain', data => 'plain' } } ],
    'source_blocks => 1 is the default form' );
  is_deeply( content_of($SEARCH_RESULT), [$SEARCH_RESULT],
    'by default a native search_result passes through' );
};

subtest 'empty content' => sub {
  is( content_of(), '', 'empty content becomes the empty string' );
  my $tr = Langertha::ToolResult->new( id => 't', content => [],
    structured_content => { temp => 22, unit => 'C' } );
  my $s = $tr->to('anthropic')->{content};
  ok( !ref $s, 'structuredContent goes out as a string' );
  is_deeply( JSON::MaybeXS->new->decode($s), { temp => 22, unit => 'C' },
    'the string is the JSON-encoded structuredContent' );
  my $both = Langertha::ToolResult->new( id => 't',
    content => [ { type => 'text', text => 'x' } ], structured_content => { a => 1 } );
  is_deeply( $both->to('anthropic')->{content}, [ { type => 'text', text => 'x' } ],
    'content wins when present' );
};

subtest 'format_tool_results maps the MCP result on the Anthropic wire' => sub {
  my $e = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-sonnet-4-6' );
  my $raw = { content => [ { type => 'tool_use', id => 'toolu_1', name => 'snap', input => {} },
    { type => 'tool_use', id => 'toolu_2', name => 'stats', input => {} } ] };
  my @msgs = $e->format_tool_results( $raw, [
    { tool_call => { id => 'toolu_1' }, result => { content => [
      { type => 'text', text => 'here', annotations => { priority => 1 } },
      { type => 'image', data => $PNG, mimeType => 'image/png' },
      { type => 'resource_link', uri => 'file:///r', name => 'r' },
    ] } },
    { tool_call => { id => 'toolu_2' },
      result => { content => [], structuredContent => { n => 3 } } },
  ] );
  my $blocks = $msgs[1]{content};
  is_deeply( $blocks->[0]{content}, [
    { type => 'text', text => 'here' },
    { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } },
    { type => 'text', text => '[resource_link] r <file:///r>' },
  ], 'MCP blocks mapped' );
  is( $blocks->[1]{content}, '{"n":3}', 'structuredContent carried through the loop' );
};

subtest 'format_tool_results: document blocks only where the wire takes them' => sub {
  my $raw = { content => [ { type => 'tool_use', id => 'toolu_1', name => 'read', input => {} } ] };
  my $res = [ { tool_call => { id => 'toolu_1' }, result => { content => [
    { type => 'resource', resource => { uri => 'file:///n.txt', mimeType => 'text/plain', text => 'notes' } },
  ] } } ];
  my $doc  = [ { type => 'document', source => { type => 'text', media_type => 'text/plain', data => 'notes' } } ];
  my $text = [ { type => 'text', text => 'notes' } ];
  my @rows = (
    [ Anthropic         => 'claude-sonnet-4-6' => $doc,  'first-party: documented document block' ],
    [ MiniMaxAnthropic  => 'MiniMax-M3'        => $doc,  'MiniMax: undocumented, default kept' ],
    [ LMStudioAnthropic => 'default'           => $text, 'LM Studio: no document type documented, text inline (k372)' ],
    [ AKIAnthropic      => 'qwen3.6-35b'       => $text, 'AKI: document is a 529, text inline' ],
    [ MoonshotAnthropic => 'kimi-k3'           => $text, 'Kimi: schema lists text | image only' ],
  );
  my $sr_res  = [ { tool_call => { id => 'toolu_1' }, result => { content => [$SEARCH_RESULT] } } ];
  my $sr_text = [ { type => 'text', text => "[search_result] Quelltown <https://e.com/q>\nPopulation 12" } ];
  for my $row (@rows) {
    my ( $name, $model, $want, $why ) = @$row;
    my $e = "Langertha::Engine::$name"->new( api_key => 'k', model => $model );
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my @msgs = $e->format_tool_results( $raw, $res );
    is_deeply( $msgs[1]{content}[0]{content}, $want, "$name: $why" );
    is( scalar @warnings, 0, "$name: an MCP resource is the normal path, no warning" );
    my $degraded = $want == $text;
    @msgs = $e->format_tool_results( $raw, $sr_res );
    is_deeply( $msgs[1]{content}[0]{content}, $degraded ? $sr_text : [$SEARCH_RESULT],
      "$name: native search_result " . ( $degraded ? 'as text (k366)' : 'passes through' ) );
  }
};

subtest 'format_tool_results: the anthropic PDF document block is a wire decision, not an image_input one' => sub {
  # k371 (ADR 0001 k371 Update): unlike OpenAI Responses / Gemini 3 (k361), the
  # anthropic PDF path ignores image_input. Live 2026-09-30: MiniMax-M2.7
  # (text-only) read a PDF document block inside a tool_result correctly
  # (HTTP 200), so gating on image_input would turn working PDF reading into a
  # placeholder. Red the moment someone adds that gate.
  my $raw = { content => [ { type => 'tool_use', id => 'toolu_1', name => 'read', input => {} } ] };
  my $res = [ { tool_call => { id => 'toolu_1' }, result => { content => [
    { type => 'resource', resource => { uri => 'file:///a.pdf', mimeType => 'application/pdf', blob => 'JVBERi0=' } },
  ] } } ];
  my $pdf_doc = [ { type => 'document',
    source => { type => 'base64', media_type => 'application/pdf', data => 'JVBERi0=' } } ];
  my $ph = [ { type => 'text', text => '[resource] application/pdf <file:///a.pdf> (5 bytes)' } ];
  my @rows = (
    [ Anthropic        => 'claude-sonnet-4-6' => $pdf_doc, 1, 'first-party, vision model' ],
    [ MiniMaxAnthropic => 'MiniMax-M2.7'      => $pdf_doc, 0, 'text-only model still gets the document block' ],
    [ MiniMaxAnthropic => 'MiniMax-M3'        => $pdf_doc, 1, 'vision model, same block' ],
    [ LMStudioAnthropic => 'default'          => $ph,      0, 'LM Studio: PDF is the placeholder (k372)' ],
  );
  for my $row (@rows) {
    my ( $name, $model, $want, $vision, $why ) = @$row;
    my $e = "Langertha::Engine::$name"->new( api_key => 'k', model => $model );
    is( $e->supports('image_input') ? 1 : 0, $vision, "$name $model: image_input is $vision" );
    my @msgs = $e->format_tool_results( $raw, $res );
    is_deeply( $msgs[1]{content}[0]{content}, $want, "$name $model: $why" );
  }
};

subtest 'explicit _tool_result_source_blocks_on_wire overrides are pinned' => sub {
  # MiniMaxAnthropic's 1 equals the Role::Tools default, so a behavior row
  # cannot see its deletion; pin the override (as t/92_tool_result_pdf.t does
  # for Perplexity) so the live-probed 1 cannot be flipped as "undocumented".
  for my $row ( [ MiniMaxAnthropic => 1 ], [ LMStudioAnthropic => 0 ] ) {
    my ( $name, $want ) = @$row;
    my $class = "Langertha::Engine::$name";
    my $method = $class->meta->find_method_by_name('_tool_result_source_blocks_on_wire');
    is( $method->original_package_name, $class, "$name defines its own predicate" );
    is( $class->new( api_key => 'k' )->_tool_result_source_blocks_on_wire, $want, "... and it says $want" );
  }
};

subtest 'format_tool_results carps once per engine when it degrades a caller-built source block' => sub {
  # The caller chose a native document / search_result for the Anthropic
  # wire; on a shim that rejects it, it silently becoming text would surprise
  # them. Once per engine instance, as ADR 0035's dropped cache fields.
  my $raw = { content => [ { type => 'tool_use', id => 'toolu_1', name => 'read', input => {} } ] };
  my $res = [ { tool_call => { id => 'toolu_1' }, result => { content => [
    $SEARCH_RESULT,
    { type => 'document', source => { type => 'text', media_type => 'text/plain', data => 'd' } },
  ] } } ];
  my $aki = Langertha::Engine::AKIAnthropic->new( api_key => 'k', model => 'qwen3.6-35b' );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $aki->format_tool_results( $raw, $res ) for 1 .. 3;
  is( scalar @warnings, 1, 'three turns, one warning' );
  like( $warnings[0], qr/AKIAnthropic/, 'names the engine' );
  like( $warnings[0], qr/search_result/, 'names search_result' );
  like( $warnings[0], qr/document/, 'names document' );
  like( $warnings[0], qr/as text/, 'says what happens instead' );

  @warnings = ();
  Langertha::Engine::AKIAnthropic->new( api_key => 'k', model => 'qwen3.6-35b' )
    ->format_tool_results( $raw, $res );
  is( scalar @warnings, 1, 'a second engine instance warns again' );

  @warnings = ();
  Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-sonnet-4-6' )
    ->format_tool_results( $raw, $res );
  is( scalar @warnings, 0, 'first-party Anthropic sends them as they are: no warning' );
};

done_testing;
