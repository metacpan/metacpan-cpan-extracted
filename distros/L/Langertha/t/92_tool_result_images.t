#!/usr/bin/env perl
# ABSTRACT: ToolResult carries tool-result images natively on the Responses, Gemini 3 and Anthropic wires when the model sees images
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::ToolResult;
use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Perplexity;
use Langertha::Engine::Gemini;
use Langertha::Engine::Anthropic;
use Langertha::Engine::MiniMaxAnthropic;
use Langertha::Engine::MoonshotAnthropic;
use Langertha::Engine::AKIAnthropic;
use Langertha::Engine::LMStudioAnthropic;

# Why (karr k344, follow-up of k336 / ADR 0001 k326+k336 Update): on every
# string wire a tool's image output reaches the model as a placeholder
# ("[image] image/png (18 bytes)"), so a screenshot tool is blind. Two wires
# take images inside a tool result natively:
#
#   - Open Responses: function_call_output.output is a string OR an array of
#     input_text / input_image parts (OpenAI /v1/responses and Perplexity
#     /v1/agent alike); input_image.image_url is a plain string, a data: URL
#     is accepted, detail is optional.
#   - Gemini 3 (v1beta): functionResponse.parts[] of { inlineData => {
#     mimeType, data } }, documented for the Gemini 3 series only, image
#     MIME types png / jpeg / webp.
#
# Both shapes are DOCS-DERIVED, NOT LIVE-VERIFIED (OpenAI API reference,
# docs.perplexity.ai agent-post reference, Gemini v1beta discovery doc and
# function-calling guide, fetched 2026-09-29).
#
# The tool loop sends what an MCP server returned, not what the caller chose,
# so the native form is used only when the selected model claims image_input
# (ADR 0019) and the wire takes it for that model; otherwise the k336
# placeholder string stays. Wires without a native form (openai, ollama,
# hermes) ignore the option and keep the placeholder -- nothing dies inside the
# tool loop (k336).
#
# Anthropic's tool_result has an image block (k326), and since k359 it follows
# the same gate: the /anthropic shims answer 200 whether or not the model sees
# the image (AKI live probe 2026-09-30: gpt-oss-120b silently dropped it,
# qwen3.6-35b misread it as a black/white square), so a model without the
# claim gets the placeholder, which at least says an image was there.
# First-party Claude claims image_input, so nothing changes there. An
# Anthropic-native image block a caller built passes through unchanged.

my $PNG  = 'iVBORw0KGgoAAAANSUhEUgAA';    # 18 decoded bytes
my $JPEG = '/9j/4AAQSkZJRg==';
my $JSON = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

my @MIXED = (
  { type => 'text', text => 'first' },
  { type => 'image', data => $PNG, mimeType => 'image/png' },
  { type => 'resource_link', uri => 'file:///r.txt', name => 'r.txt' },
  { type => 'audio', data => 'UklGRg==', mimeType => 'audio/wav' },
  { type => 'text', text => 'last' },
);
my $PLACEHOLDER_STRING = join "\n",
  'first',
  '[image] image/png (18 bytes)',
  '[resource_link] r.txt <file:///r.txt>',
  '[audio] audio/wav (4 bytes)',
  'last';

sub result { Langertha::ToolResult->new( id => 'c1', name => 'snap', @_ ) }

subtest 'responses: image_input turns the output into input_text / input_image parts' => sub {
  my $r = result( content => \@MIXED );
  is_deeply( $r->to( 'responses', image_input => 1 ), {
    type    => 'function_call_output',
    call_id => 'c1',
    output  => [
      { type => 'input_text',  text => 'first' },
      { type => 'input_image', image_url => "data:image/png;base64,$PNG" },
      { type => 'input_text',  text => '[resource_link] r.txt <file:///r.txt>' },
      { type => 'input_text',  text => '[audio] audio/wav (4 bytes)' },
      { type => 'input_text',  text => 'last' },
    ],
  }, 'image rides as a data-URL input_image, the rest as input_text in order' );
  is( $r->to('responses')->{output}, $PLACEHOLDER_STRING,
    'without the option the k336 string is unchanged' );

  my $res = result( content => [ { type => 'resource', resource => { uri => 'file:///s.jpg',
    mimeType => 'image/jpeg', blob => "/9j/4AAQ\nSkZJRg==" } } ] );
  is_deeply( $res->to( 'responses', image_input => 1 )->{output},
    [ { type => 'input_image', image_url => "data:image/jpeg;base64,$JPEG" } ],
    'an embedded image resource is an image too; base64 whitespace is dropped' );
};

subtest 'responses: no carriable image keeps the string' => sub {
  is( result( content => [ { type => 'text', text => 'x' } ] )
    ->to( 'responses', image_input => 1 )->{output}, 'x', 'text only: string' );
  is( result( content => [ { type => 'image', data => 'Qk0=', mimeType => 'image/bmp' } ] )
    ->to( 'responses', image_input => 1 )->{output}, '[image] image/bmp (2 bytes)',
    'a MIME type the wire does not take stays a placeholder string' );
  is( result( structured_content => { n => 1 } )->to( 'responses', image_input => 1 )->{output},
    '{"n":1}', 'empty content still falls back to structuredContent' );
};

subtest 'gemini: image_input adds functionResponse.parts inlineData' => sub {
  my $r = result( content => \@MIXED );
  is_deeply( $r->to( 'gemini', image_input => 1 ), {
    functionResponse => {
      name     => 'snap',
      id       => 'c1',
      response => { result => join "\n", 'first', '[resource_link] r.txt <file:///r.txt>',
        '[audio] audio/wav (4 bytes)', 'last' },
      parts    => [ { inlineData => { mimeType => 'image/png', data => $PNG } } ],
    },
  }, 'the image moves out of the result string into parts' );
  is_deeply( $r->to('gemini')->{functionResponse},
    { name => 'snap', id => 'c1', response => { result => $PLACEHOLDER_STRING } },
    'without the option: no parts, placeholder in the string' );

  my $gif = result( content => [ { type => 'image', data => 'R0lGOA==', mimeType => 'image/gif' } ] );
  ok( !exists $gif->to( 'gemini', image_input => 1 )->{functionResponse}{parts},
    'image/gif is not a documented functionResponse type: no parts' );
  is( $gif->to( 'gemini', image_input => 1 )->{functionResponse}{response}{result},
    '[image] image/gif (4 bytes)', '... it stays a placeholder' );

  my $only = result( content => [ { type => 'image', data => $PNG, mimeType => 'image/png' } ],
    structured_content => { w => 640 } );
  is_deeply( $only->to( 'gemini', image_input => 1 )->{functionResponse}{response}, { w => 640 },
    'structuredContent stays the response object' );
  is_deeply( result( content => [ { type => 'image', data => $PNG, mimeType => 'image/png' } ] )
    ->to( 'gemini', image_input => 1 )->{functionResponse}{response}, { result => '' },
    'an image-only result keeps the required response object' );
};

subtest 'wires without a native form ignore the option' => sub {
  my $r = result( content => \@MIXED );
  for my $fmt (qw( openai ollama hermes )) {
    is_deeply( $r->to( $fmt, image_input => 1 ), $r->to($fmt), "$fmt unchanged" );
  }
};

subtest 'anthropic: image_input gates MCP images; native image blocks pass through' => sub {
  my $r = result( content => \@MIXED );
  is_deeply( $r->to( 'anthropic', image_input => 1 )->{content}, [
    { type => 'text',  text => 'first' },
    { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } },
    { type => 'text',  text => '[resource_link] r.txt <file:///r.txt>' },
    { type => 'text',  text => '[audio] audio/wav (4 bytes)' },
    { type => 'text',  text => 'last' },
  ], 'with image_input the MCP image is a base64 image block' );
  is_deeply( $r->to('anthropic')->{content}[1],
    { type => 'text', text => '[image] image/png (18 bytes)' },
    'without it the MCP image is the k336 placeholder text block' );

  my $res = result( content => [ { type => 'resource', resource => { uri => 'file:///s.png',
    mimeType => 'image/png', blob => $PNG } } ] );
  is_deeply( $res->to('anthropic')->{content},
    [ { type => 'text', text => '[resource] image/png <file:///s.png> (18 bytes)' } ],
    'an image resource without image_input is a placeholder too' );
  is( $res->to( 'anthropic', image_input => 1 )->{content}[0]{type}, 'image',
    '... and an image block with it' );

  my $native = { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } };
  is_deeply( result( content => [$native] )->to('anthropic')->{content}, [$native],
    'an Anthropic-native image block (the caller chose it) passes through without the option' );
};

# --- the tool loop decides per engine and model ---

my $IMG_RESULT = [ { tool_call => { call_id => 'call_1', name => 'snap' },
  result => { content => [ { type => 'image', data => $PNG, mimeType => 'image/png' } ] } } ];
my $RESP_DATA = { output => [ { type => 'function_call', call_id => 'call_1', name => 'snap',
  arguments => '{}' } ] };

sub responses_output {
  my ($engine) = @_;
  my @items = $engine->format_tool_results( $RESP_DATA, $IMG_RESULT );
  return $items[-1]{output};
}

subtest 'format_tool_results: responses wire follows image_input' => sub {
  my $oai = Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.6' );
  ok( $oai->supports('image_input'), 'gpt-5.6 claims image_input' );
  is_deeply( responses_output($oai),
    [ { type => 'input_image', image_url => "data:image/png;base64,$PNG" } ],
    'OpenAIResponses: native input_image' );

  my $text_only = Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-oss-120b' );
  ok( !$text_only->supports('image_input'), 'gpt-oss claims no image_input' );
  is( responses_output($text_only), '[image] image/png (18 bytes)',
    'a text-only model keeps the placeholder string' );

  is_deeply( responses_output( Langertha::Engine::Perplexity->new( api_key => 'k',
    model => 'openai/gpt-5.6' ) ),
    [ { type => 'input_image', image_url => "data:image/png;base64,$PNG" } ],
    'Perplexity with a vision model: native input_image (same Agent API shape)' );
  is( responses_output( Langertha::Engine::Perplexity->new( api_key => 'k', model => 'sonar' ) ),
    '[image] image/png (18 bytes)', 'Perplexity sonar preset (no claim): placeholder string' );
};

my $GEM_DATA = { candidates => [ { content => { role => 'model',
  parts => [ { functionCall => { name => 'snap', id => 'g1', args => {} } } ] } } ] };
my $GEM_RESULT = [ { tool_call => { functionCall => { name => 'snap', id => 'g1' } },
  result => { content => [ { type => 'image', data => $PNG, mimeType => 'image/png' } ] } } ];

sub gemini_fr {
  my ($model) = @_;
  my $g = Langertha::Engine::Gemini->new( api_key => 'k', model => $model );
  my @msgs = $g->format_tool_results( $GEM_DATA, $GEM_RESULT );
  return $msgs[1]{parts}[0]{functionResponse};
}

subtest 'format_tool_results: gemini parts only on Gemini 3' => sub {
  for my $model (qw( gemini-3-flash-preview gemini-3.1-pro-preview gemini-3.8-flash )) {
    is_deeply( gemini_fr($model)->{parts}, [ { inlineData => { mimeType => 'image/png', data => $PNG } } ],
      "$model: parts" );
  }
  for my $model (qw( gemini-2.5-flash gemini-30-future gemma-3-27b-it gemini-3-flash-preview-tts )) {
    my $fr = gemini_fr($model);
    ok( !exists $fr->{parts}, "$model: no parts" );
    is( $fr->{response}{result}, '[image] image/png (18 bytes)', "$model: placeholder string" );
  }
};

subtest 'the native forms survive the request envelopes' => sub {
  my $oai = Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.6' );
  my @conv = ( { role => 'user', content => 'shoot' },
    $oai->format_tool_results( $RESP_DATA, $IMG_RESULT ) );
  my $body = $JSON->decode( $oai->chat(@conv)->content );
  my ($fco) = grep { ( $_->{type} // '' ) eq 'function_call_output' } @{ $body->{input} };
  is_deeply( $fco->{output}, [ { type => 'input_image', image_url => "data:image/png;base64,$PNG" } ],
    'OpenAIResponses request body keeps the part array' );

  my $ppx = Langertha::Engine::Perplexity->new( api_key => 'k', model => 'openai/gpt-5.6' );
  @conv = ( { role => 'user', content => 'shoot' }, $ppx->format_tool_results( $RESP_DATA, $IMG_RESULT ) );
  $body = $JSON->decode( $ppx->chat(@conv)->content );
  ($fco) = grep { ( $_->{type} // '' ) eq 'function_call_output' } @{ $body->{input} };
  is_deeply( $fco->{output}, [ { type => 'input_image', image_url => "data:image/png;base64,$PNG" } ],
    'Perplexity request body keeps the part array' );

  my $g = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-3-flash-preview' );
  @conv = ( { role => 'user', content => 'shoot' }, $g->format_tool_results( $GEM_DATA, $GEM_RESULT ) );
  $body = $JSON->decode( $g->chat(@conv)->content );
  is_deeply( $body->{contents}[-1]{parts}[0]{functionResponse}{parts},
    [ { inlineData => { mimeType => 'image/png', data => $PNG } } ],
    'Gemini request body keeps functionResponse.parts' );
};

my $ANT_DATA = { content => [ { type => 'tool_use', id => 'toolu_1', name => 'snap', input => {} } ] };
my $ANT_RESULT = [ { tool_call => { id => 'toolu_1' },
  result => { content => [ { type => 'image', data => $PNG, mimeType => 'image/png' } ] } } ];
my $ANT_IMAGE = [ { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } } ];
my $ANT_PLACEHOLDER = [ { type => 'text', text => '[image] image/png (18 bytes)' } ];

sub anthropic_content {
  my ($engine) = @_;
  my @msgs = $engine->format_tool_results( $ANT_DATA, $ANT_RESULT );
  return $msgs[1]{content}[0]{content};
}

sub anthropic_engine {
  my ( $name, $model ) = @_;
  return "Langertha::Engine::$name"->new( api_key => 'k', model => $model );
}

subtest 'format_tool_results: anthropic wire follows image_input per engine and model' => sub {
  my @rows = (
    [ Anthropic         => 'claude-sonnet-4-6' => $ANT_IMAGE,       'first-party Claude sees images' ],
    [ MiniMaxAnthropic  => 'MiniMax-M3'        => $ANT_IMAGE,       'MiniMax-M3 claims image_input' ],
    [ MiniMaxAnthropic  => 'MiniMax-M2.7'      => $ANT_PLACEHOLDER, 'MiniMax-M2.x is text-only' ],
    [ MoonshotAnthropic => 'kimi-k3'           => $ANT_IMAGE,       'kimi-k3 is a vision model (Kimi documents text|image in tool_result)' ],
    [ MoonshotAnthropic => 'kimi-k2.5'         => $ANT_PLACEHOLDER, 'an unlisted Kimi id makes no claim' ],
    [ AKIAnthropic      => 'qwen3.6-35b'       => $ANT_PLACEHOLDER, 'AKI shim: placeholder' ],
    [ AKIAnthropic      => 'gpt-oss-120b'      => $ANT_PLACEHOLDER, 'AKI shim, text-only model: placeholder' ],
    [ LMStudioAnthropic => 'some-vlm'          => $ANT_PLACEHOLDER, 'LM Studio: served model unknown, placeholder' ],
  );
  for my $row (@rows) {
    my ( $name, $model, $want, $why ) = @$row;
    is_deeply( anthropic_content( anthropic_engine( $name, $model ) ), $want, "$name $model: $why" );
  }
};

subtest 'LMStudioAnthropic: a learned vision fact switches the tool result to the image block' => sub {
  # k365 x k359: LMStudioAnthropic is the first probing engine on the anthropic
  # wire, so a learned image_input fact (ADR 0032) changes the tool-result
  # form there. Unlearned it stays the placeholder (the row above); a store
  # that said "no" must keep it too.
  my $lms = anthropic_engine( LMStudioAnthropic => 'some-vlm' );
  $lms->_set_learned_model_capabilities( { 'some-vlm' => { image_input => 1 } } );
  ok( $lms->supports('image_input'), 'the learned store makes the model claim image_input' );
  is_deeply( anthropic_content($lms), $ANT_IMAGE, 'learned vision model: base64 image block' );

  my $blind = anthropic_engine( LMStudioAnthropic => 'some-vlm' );
  $blind->_set_learned_model_capabilities( { 'some-vlm' => { image_input => 0 } } );
  is_deeply( anthropic_content($blind), $ANT_PLACEHOLDER, 'learned text-only model: placeholder' );
};

subtest 'AKIAnthropic keeps the placeholder even with an image_input claim' => sub {
  # The AKI shim's user-image path works for qwen3.6-35b (live probe
  # 2026-09-30), so an image_input row will likely be added one day; the
  # tool_result path then still must not carry images, because there the
  # image reaches the model mangled (answered 'White' / 'Black' for a red /
  # green square).
  my $meta = Moose::Meta::Class->create_anon_class(
    superclasses => ['Langertha::Engine::AKIAnthropic'] );
  $meta->add_around_method_modifier( engine_capabilities => sub {
    my ( $orig, $self, @rest ) = @_;
    return { %{ $self->$orig(@rest) }, image_input => 1 };
  } );
  my $aki = $meta->name->new( api_key => 'k', model => 'qwen3.6-35b' );
  ok( $aki->supports('image_input'), 'the anon subclass claims image_input' );
  is_deeply( anthropic_content($aki), $ANT_PLACEHOLDER,
    '_tool_result_images_on_wire keeps the placeholder' );
};

subtest 'the anthropic image survives the request envelope' => sub {
  for my $row ( [ Anthropic => 'claude-sonnet-4-6' ], [ MoonshotAnthropic => 'kimi-k3' ] ) {
    my $e = anthropic_engine(@$row);
    my @conv = ( { role => 'user', content => 'shoot' }, $e->format_tool_results( $ANT_DATA, $ANT_RESULT ) );
    my $body = $JSON->decode( $e->chat(@conv)->content );
    is_deeply( $body->{messages}[-1]{content}[0]{content}, $ANT_IMAGE,
      "$row->[0] request body keeps the image block" );
  }
};

subtest 'string wires in the loop are unchanged' => sub {
  my $oai = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6' );
  ok( $oai->supports('image_input'), 'the chat-completions model sees images' );
  my @msgs = $oai->format_tool_results(
    { choices => [ { message => { role => 'assistant', tool_calls => [] } } ] },
    [ { tool_call => { id => 'call_1', function => { name => 'snap' } },
        result => $IMG_RESULT->[0]{result} } ] );
  is( $msgs[1]{content}, '[image] image/png (18 bytes)',
    'the openai tool message stays a placeholder string (no native image form)' );
};

done_testing;
