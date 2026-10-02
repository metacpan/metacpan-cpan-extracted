#!/usr/bin/env perl
# ABSTRACT: ToolResult carries a tool-result PDF natively on the OpenAI Responses and Gemini 3 wires
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::ToolResult;
use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Perplexity;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;

# Why (karr k361, follow-up of k344 / ADR 0001 k344 Update): a PDF an MCP tool
# returns (an embedded resource blob, application/pdf) reaches the model as the
# k336 placeholder on the responses and gemini wires, while the anthropic wire
# sends it as a base64 document block (k326). Two of those wires document a
# native form:
#
#   - OpenAI /v1/responses: function_call_output.output is a string or an
#     array of input_text / input_image / input_file parts (API reference,
#     FunctionCallOutput); an input_file carries file_data (the file guide
#     sends a data:application/pdf;base64,... URL) and filename (optional in
#     the reference, required by the server in practice).
#   - Gemini 3 (v1beta generateContent): functionResponse.parts[].inlineData;
#     the multimodal-function-response MIME list names application/pdf
#     beside the image types, Gemini 3 series only.
#
# Perplexity's Agent API (/v1/agent) shares the Responses envelope but its
# FunctionCallOutputInput.output lists only input_text and input_image, so it
# keeps the placeholder. DOCS-DERIVED, NOT LIVE-VERIFIED (developers.openai.com
# API reference + PDF-files guide, docs.perplexity.ai agent-post reference,
# ai.google.dev generate-content function-calling guide, fetched 2026-09-30).
#
# Gate: the wire must take it for the model (private _tool_result_pdf_on_wire:
# OpenAIResponses, Gemini 3) AND the model must claim image_input, because
# both providers document PDF understanding as a vision feature (OpenAI: page
# text plus page images, "requires models with vision capabilities"). The tool
# loop sends what an MCP server returned, not what the caller chose (the k344
# reason), so a text-only model keeps the placeholder instead of a possible
# 400. Every other wire keeps the placeholder too.

my $PDF  = 'JVBERi0xLjQK';                 # "%PDF-1.4\n", 9 decoded bytes
my $PNG  = 'iVBORw0KGgoAAAANSUhEUgAA';     # 18 decoded bytes
my $JSON = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

my $PDF_BLOCK = { type => 'resource', resource => { uri => 'file:///docs/report.pdf',
  mimeType => 'application/pdf', blob => $PDF } };
my $PDF_PLACEHOLDER = '[resource] application/pdf <file:///docs/report.pdf> (9 bytes)';
my $PDF_FILE = { type => 'input_file', filename => 'report.pdf',
  file_data => "data:application/pdf;base64,$PDF" };

sub result { Langertha::ToolResult->new( id => 'c1', name => 'fetch', @_ ) }

subtest 'responses: native_pdf turns a PDF resource into an input_file part' => sub {
  my $r = result( content => [ { type => 'text', text => 'here' }, $PDF_BLOCK ] );
  is_deeply( $r->to( 'responses', native_pdf => 1 ), {
    type    => 'function_call_output',
    call_id => 'c1',
    output  => [ { type => 'input_text', text => 'here' }, $PDF_FILE ],
  }, 'the PDF rides as input_file (data: URL + filename), the rest as input_text in order' );
  is( $r->to('responses')->{output}, "here\n$PDF_PLACEHOLDER",
    'without the option the k336 string is unchanged' );
  is( $r->to( 'responses', image_input => 1 )->{output}, "here\n$PDF_PLACEHOLDER",
    'image_input alone does not carry a PDF' );
};

subtest 'responses: filename and payload details' => sub {
  my $noext = result( content => [ { type => 'resource', resource => {
    uri => 'https://x.test/api/doc/42?v=1#p2', mimeType => 'application/pdf', blob => "JVBE\nRi0xLjQK" } } ] );
  is_deeply( $noext->to( 'responses', native_pdf => 1 )->{output},
    [ { type => 'input_file', filename => '42.pdf', file_data => "data:application/pdf;base64,$PDF" } ],
    'last path segment without query/fragment, .pdf appended; base64 whitespace dropped' );

  my $nouri = result( content => [ { type => 'resource', resource => {
    mimeType => 'application/pdf', blob => $PDF } } ] );
  is( $nouri->to( 'responses', native_pdf => 1 )->{output}[0]{filename}, 'document.pdf',
    'no URI: a generic filename (the server requires one with file_data)' );

  my %names = (
    'file:///docs/my%20report.pdf'          => 'my report.pdf',
    'file:///docs/K%C3%B6ln'                => "K\x{f6}ln.pdf",
    'urn:uuid:0e1f2a3b-4c5d-6e7f-8091-a2b3c4d5e6f7' => 'document.pdf',
    'foo:bar/baz.pdf'                       => 'document.pdf',
    'https://x.test'                        => 'document.pdf',
    'https://x.test/'                       => 'document.pdf',
    'report'                                => 'report.pdf',
  );
  for my $uri ( sort keys %names ) {
    my $r = result( content => [ { type => 'resource', resource => {
      uri => $uri, mimeType => 'application/pdf', blob => $PDF } } ] );
    is( $r->to( 'responses', native_pdf => 1 )->{output}[0]{filename}, $names{$uri},
      "filename from <$uri>: percent-decoded last segment of a hierarchical path, else generic" );
  }

  my $upper = result( content => [ { type => 'resource', resource => {
    uri => 'file:///A/SCAN.PDF', mimeType => 'application/pdf', blob => $PDF } } ] );
  is( $upper->to( 'responses', native_pdf => 1 )->{output}[0]{filename}, 'SCAN.PDF',
    'an existing .pdf extension (any case) is kept' );

  my $link = result( content => [ { type => 'resource_link', uri => 'file:///r.pdf',
    name => 'r.pdf', mimeType => 'application/pdf' } ] );
  is( $link->to( 'responses', native_pdf => 1 )->{output}, '[resource_link] r.pdf <file:///r.pdf>',
    'a resource_link has no payload: stays a string' );

  my $other = result( content => [ { type => 'resource', resource => {
    uri => 'file:///a.zip', mimeType => 'application/zip', blob => 'UEsDBA==' } } ] );
  is( $other->to( 'responses', native_pdf => 1 )->{output}, '[resource] application/zip <file:///a.zip> (4 bytes)',
    'another binary MIME type stays a placeholder string' );
};

subtest 'responses: PDF and image together, each behind its own option' => sub {
  my $r = result( content => [ { type => 'image', data => $PNG, mimeType => 'image/png' }, $PDF_BLOCK ] );
  is_deeply( $r->to( 'responses', image_input => 1, native_pdf => 1 )->{output}, [
    { type => 'input_image', image_url => "data:image/png;base64,$PNG" },
    $PDF_FILE,
  ], 'both native' );
  is_deeply( $r->to( 'responses', image_input => 1 )->{output}, [
    { type => 'input_image', image_url => "data:image/png;base64,$PNG" },
    { type => 'input_text',  text => $PDF_PLACEHOLDER },
  ], 'image only: the PDF is an input_text placeholder (Perplexity vision models)' );
  is_deeply( $r->to( 'responses', native_pdf => 1 )->{output}, [
    { type => 'input_text', text => '[image] image/png (18 bytes)' },
    $PDF_FILE,
  ], 'PDF only: the image is an input_text placeholder' );
};

subtest 'gemini: native_pdf adds functionResponse.parts inlineData application/pdf' => sub {
  my $r = result( content => [ { type => 'text', text => 'here' }, $PDF_BLOCK ] );
  is_deeply( $r->to( 'gemini', native_pdf => 1 ), {
    functionResponse => {
      name     => 'fetch',
      id       => 'c1',
      response => { result => 'here' },
      parts    => [ { inlineData => { mimeType => 'application/pdf', data => $PDF } } ],
    },
  }, 'the PDF moves out of the result string into parts' );
  is_deeply( $r->to('gemini')->{functionResponse},
    { name => 'fetch', id => 'c1', response => { result => "here\n$PDF_PLACEHOLDER" } },
    'without the option: no parts, placeholder in the string' );
  ok( !exists $r->to( 'gemini', image_input => 1 )->{functionResponse}{parts},
    'image_input alone does not carry a PDF' );

  my $both = result( content => [ { type => 'image', data => $PNG, mimeType => 'image/png' }, $PDF_BLOCK ] );
  is_deeply( $both->to( 'gemini', image_input => 1, native_pdf => 1 )->{functionResponse}{parts}, [
    { inlineData => { mimeType => 'image/png',       data => $PNG } },
    { inlineData => { mimeType => 'application/pdf', data => $PDF } },
  ], 'image and PDF parts in content order' );
};

subtest 'wires without a native PDF form in a tool result ignore the option' => sub {
  my $r = result( content => [ { type => 'text', text => 'here' }, $PDF_BLOCK ] );
  for my $fmt (qw( openai ollama hermes anthropic )) {
    is_deeply( $r->to( $fmt, native_pdf => 1 ), $r->to($fmt), "$fmt unchanged" );
  }
};

# --- the tool loop decides per engine and model ---

my $PDF_RESULT = [ { tool_call => { call_id => 'call_1', name => 'fetch' },
  result => { content => [$PDF_BLOCK] } } ];
my $RESP_DATA = { output => [ { type => 'function_call', call_id => 'call_1', name => 'fetch',
  arguments => '{}' } ] };

sub responses_output {
  my ($engine) = @_;
  my @items = $engine->format_tool_results( $RESP_DATA, $PDF_RESULT );
  return $items[-1]{output};
}

subtest 'format_tool_results: responses wire' => sub {
  # The Role::Tools default is 0 too, so the Perplexity rows below would stay
  # green without Perplexity's explicit override; pin the override itself, so
  # the shared envelope's divergence cannot silently follow a changed default.
  my $method = Langertha::Engine::Perplexity->meta->find_method_by_name('_tool_result_pdf_on_wire');
  is( $method->original_package_name, 'Langertha::Engine::Perplexity',
    'Perplexity defines its own _tool_result_pdf_on_wire (not the Role::Tools default)' );
  ok( !Langertha::Engine::Perplexity->new( api_key => 'k', model => 'openai/gpt-5.6' )
    ->_tool_result_pdf_on_wire, '... and it says no' );

  is_deeply( responses_output( Langertha::Engine::OpenAIResponses->new( api_key => 'k',
    model => 'gpt-5.6' ) ), [$PDF_FILE], 'OpenAIResponses, vision model: native input_file' );
  is( responses_output( Langertha::Engine::OpenAIResponses->new( api_key => 'k',
    model => 'gpt-oss-120b' ) ), $PDF_PLACEHOLDER,
    'OpenAIResponses, text-only model: placeholder string' );
  is( responses_output( Langertha::Engine::Perplexity->new( api_key => 'k',
    model => 'openai/gpt-5.6' ) ), $PDF_PLACEHOLDER,
    'Perplexity, vision model: placeholder (the Agent API documents no input_file)' );
  is( responses_output( Langertha::Engine::Perplexity->new( api_key => 'k', model => 'sonar' ) ),
    $PDF_PLACEHOLDER, 'Perplexity sonar preset: placeholder' );
};

my $GEM_DATA = { candidates => [ { content => { role => 'model',
  parts => [ { functionCall => { name => 'fetch', id => 'g1', args => {} } } ] } } ] };
my $GEM_RESULT = [ { tool_call => { functionCall => { name => 'fetch', id => 'g1' } },
  result => { content => [$PDF_BLOCK] } } ];

sub gemini_fr {
  my ($model) = @_;
  my $g = Langertha::Engine::Gemini->new( api_key => 'k', model => $model );
  my @msgs = $g->format_tool_results( $GEM_DATA, $GEM_RESULT );
  return $msgs[1]{parts}[0]{functionResponse};
}

subtest 'format_tool_results: gemini parts only on Gemini 3' => sub {
  for my $model (qw( gemini-3-flash-preview gemini-3.1-pro-preview gemini-3.8-flash )) {
    is_deeply( gemini_fr($model)->{parts},
      [ { inlineData => { mimeType => 'application/pdf', data => $PDF } } ], "$model: parts" );
  }
  for my $model (qw( gemini-2.5-flash gemini-30-future gemini-3-flash-preview-tts )) {
    my $fr = gemini_fr($model);
    ok( !exists $fr->{parts}, "$model: no parts" );
    is( $fr->{response}{result}, $PDF_PLACEHOLDER, "$model: placeholder string" );
  }
};

subtest 'format_tool_results: string wires keep the placeholder' => sub {
  my $oai = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6' );
  my @msgs = $oai->format_tool_results(
    { choices => [ { message => { role => 'assistant', tool_calls => [] } } ] },
    [ { tool_call => { id => 'call_1', function => { name => 'fetch' } },
        result => $PDF_RESULT->[0]{result} } ] );
  is( $msgs[1]{content}, $PDF_PLACEHOLDER, 'OpenAI chat completions: placeholder string' );

  my $oll = Langertha::Engine::Ollama->new( url => 'http://localhost:11434', model => 'llava' );
  @msgs = $oll->format_tool_results(
    { message => { role => 'assistant', content => '', tool_calls => [] } },
    [ { tool_call => { function => { name => 'fetch' } }, result => $PDF_RESULT->[0]{result} } ] );
  is( $msgs[1]{content}, $PDF_PLACEHOLDER, 'Ollama native: placeholder string' );
};

subtest 'the native forms survive the request envelopes' => sub {
  my $oai = Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.6' );
  my @conv = ( { role => 'user', content => 'read it' },
    $oai->format_tool_results( $RESP_DATA, $PDF_RESULT ) );
  my $body = $JSON->decode( $oai->chat(@conv)->content );
  my ($fco) = grep { ( $_->{type} // '' ) eq 'function_call_output' } @{ $body->{input} };
  is_deeply( $fco->{output}, [$PDF_FILE], 'OpenAIResponses request body keeps the input_file part' );

  my $g = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-3-flash-preview' );
  @conv = ( { role => 'user', content => 'read it' }, $g->format_tool_results( $GEM_DATA, $GEM_RESULT ) );
  $body = $JSON->decode( $g->chat(@conv)->content );
  is_deeply( $body->{contents}[-1]{parts}[0]{functionResponse}{parts},
    [ { inlineData => { mimeType => 'application/pdf', data => $PDF } } ],
    'Gemini request body keeps functionResponse.parts' );
};

done_testing;
