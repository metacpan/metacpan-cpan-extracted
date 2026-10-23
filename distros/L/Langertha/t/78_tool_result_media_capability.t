#!/usr/bin/env perl
# ABSTRACT: tool_result_images / tool_result_pdf are public, model-scoped capabilities (k380)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny qw( path );
use Module::Runtime qw( use_module );
use Moose::Meta::Class;

use Langertha::ToolResult;

# karr k380 (ADR 0039): whether an image or PDF a tool returns reaches the
# model natively used to be private engine predicates in Role::Tools, so
# langertha-raider guessed it from image_input plus a hardcoded list of wire
# names -- wrong for AKIAnthropic (images mangled, k359), Gemini < 3, the
# Anthropic shims without source blocks and Perplexity (no input_file). The
# flags are now in the supports() registry, and format_tool_results reads the
# same flags, so what a caller is told and what goes on the wire cannot
# disagree. A wrong yes sends an image the model does not see (or a 400
# mid-loop); a wrong no hides a screenshot behind a placeholder.

delete @ENV{ grep { /\ALANGERTHA_/ } keys %ENV };

my $JSON = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $PNG  = 'iVBORw0KGgoAAAANSUhEUgAA';     # 18 decoded bytes
my $PDF  = 'JVBERi0xLjQK';                 # "%PDF-1.4\n", 9 decoded bytes

my $IMAGE_BLOCK = { type => 'image', mimeType => 'image/png', data => $PNG };
my $PDF_BLOCK   = { type => 'resource', resource => { uri => 'file:///docs/report.pdf',
  mimeType => 'application/pdf', blob => $PDF } };

sub engine {
  my ( $name, %args ) = @_;
  return use_module("Langertha::Engine::$name")
    ->new( api_key => 'k', url => 'http://h.example:1/v1', %args );
}

sub flags {
  my ($engine) = @_;
  return [ map { $engine->supports($_) ? 1 : 0 } qw( tool_result_images tool_result_pdf ) ];
}

# ---------------------------------------------------------------------------
# 1. ToolResult->carries_native is the serializer's own truth: the payload
#    leaves the placeholder exactly on the wires it names.
# ---------------------------------------------------------------------------
subtest 'carries_native matches what ToolResult->to actually emits' => sub {
  my %block = ( image => $IMAGE_BLOCK, pdf => $PDF_BLOCK );
  my %data  = ( image => $PNG,         pdf => $PDF );
  for my $fmt (qw( openai anthropic gemini ollama responses hermes )) {
    for my $kind (qw( image pdf )) {
      my $out = Langertha::ToolResult->new( id => 'c1', name => 'fetch',
        content => [ $block{$kind} ] )->to( $fmt, image_input => 1, native_pdf => 1 );
      my $wire = ref $out ? $JSON->encode($out) : $out;
      my $native = index( $wire, $data{$kind} ) >= 0 ? 1 : 0;
      is( Langertha::ToolResult->carries_native( $fmt, $kind ) ? 1 : 0, $native,
        "$fmt / $kind: carries_native says " . ( $native ? 'native' : 'placeholder' ) );
    }
  }
  ok( !Langertha::ToolResult->carries_native( 'nonsense', 'image' ), 'unknown wire: no' );
  ok( !Langertha::ToolResult->carries_native( undef, 'pdf' ), 'undef wire: no' );
  eval { Langertha::ToolResult->carries_native( 'anthropic', 'audio' ) };
  like( $@, qr/carries_native.*audio/, 'an unknown kind croaks' );
};

subtest 'native_needs_vision: a PDF is a vision question on responses / gemini, not on anthropic' => sub {
  # k361: OpenAI and Gemini read PDFs through the model's vision; k371: the
  # anthropic dialect extracts a PDF's text for a text-only model.
  my %want = (
    'anthropic/image' => 1, 'responses/image' => 1, 'gemini/image' => 1,
    'anthropic/pdf'   => 0, 'responses/pdf'   => 1, 'gemini/pdf'   => 1,
    'openai/image'    => 0, 'openai/pdf'      => 0, 'ollama/pdf'   => 0, 'hermes/image' => 0,
  );
  for my $key ( sort keys %want ) {
    my ( $fmt, $kind ) = split m{/}, $key;
    is( Langertha::ToolResult->native_needs_vision( $fmt, $kind ), $want{$key}, "$key: $want{$key}" );
  }
  eval { Langertha::ToolResult->native_needs_vision( 'gemini', 'video' ) };
  like( $@, qr/native_needs_vision.*video/, 'an unknown kind croaks' );
};

subtest 'anthropic native_pdf: default on, 0 sends the placeholder, text documents untouched' => sub {
  my $text_doc = { type => 'resource', resource => { uri => 'file:///notes.txt',
    mimeType => 'text/plain', text => 'hello' } };
  my $r = Langertha::ToolResult->new( id => 't1', content => [ $PDF_BLOCK, $text_doc ] );
  my $pdf_doc  = { type => 'document', source => { type => 'base64',
    media_type => 'application/pdf', data => $PDF } };
  my $txt_doc  = { type => 'document', source => { type => 'text',
    media_type => 'text/plain', data => 'hello' } };
  is_deeply( $r->to('anthropic')->{content}, [ $pdf_doc, $txt_doc ],
    'a bare to(anthropic) keeps the k326 document blocks' );
  is_deeply( $r->to( 'anthropic', native_pdf => 0 )->{content}, [
    { type => 'text', text => '[resource] application/pdf <file:///docs/report.pdf> (9 bytes)' },
    $txt_doc,
  ], 'native_pdf => 0: the PDF is the placeholder, the text document stays a document' );
};

# ---------------------------------------------------------------------------
# 2. The per-engine / per-model table (images, pdf).
# ---------------------------------------------------------------------------
my @ROWS = (
  # engine            model                         images pdf
  [ Anthropic         => 'claude-sonnet-4-6'        => 1, 1 ],
  [ Anthropic         => 'claude-2.1'               => 0, 1 ],  # PDF without vision (k371)
  [ MiniMaxAnthropic  => 'MiniMax-M3'               => 1, 1 ],
  [ MiniMaxAnthropic  => 'MiniMax-M2.7'             => 0, 1 ],  # read live, text extracted
  [ MoonshotAnthropic => 'kimi-k3'                  => 1, 0 ],  # no document block (k364)
  [ MoonshotAnthropic => 'kimi-k2.5'                => 0, 0 ],
  [ LMStudioAnthropic => 'some-vlm'                 => 0, 0 ],  # no static claim
  [ AKIAnthropic      => 'qwen3.6-35b'              => 0, 0 ],  # k359, k364
  [ OpenAIResponses   => 'gpt-5.6'                  => 1, 1 ],
  [ OpenAIResponses   => 'gpt-oss-120b'             => 0, 0 ],  # text-only: no PDF either (k361)
  [ OpenAIResponses   => 'gpt-3.5-turbo'            => 0, 0 ],
  [ Perplexity        => 'openai/gpt-5.6'           => 1, 0 ],  # no input_file on /v1/agent
  [ Perplexity        => 'openai/gpt-oss-120b'      => 0, 0 ],
  [ Perplexity        => 'sonar'                    => 0, 0 ],
  [ Gemini            => 'gemini-3-flash-preview'   => 1, 1 ],
  [ Gemini            => 'gemini-3.1-pro-preview'   => 1, 1 ],
  [ Gemini            => 'gemini-2.5-pro'           => 0, 0 ],  # parts are Gemini 3+ only
  [ Gemini            => 'gemini-4-argon'           => 1, 1 ],  # "Gemini 3 and later"
  [ Gemini            => 'gemini-2.5-flash'         => 0, 0 ],
  [ Gemini            => 'gemini-1.5-flash'         => 0, 0 ],
  [ Gemini            => 'gemini-3-pro-preview-tts' => 0, 0 ],  # no image_input
);

for my $row (@ROWS) {
  my ( $name, $model, @want ) = @$row;
  is_deeply( flags( engine( $name, model => $model ) ), \@want,
    "$name $model: tool_result_images=$want[0] tool_result_pdf=$want[1]" );
}

# ---------------------------------------------------------------------------
# 3. Who composes the roles; every other engine claims neither.
# ---------------------------------------------------------------------------
my %COMPOSES = (
  Anthropic         => [ 1, 1 ],
  MiniMaxAnthropic  => [ 1, 1 ],
  MoonshotAnthropic => [ 1, 1 ],
  LMStudioAnthropic => [ 1, 1 ],
  AKIAnthropic      => [ 1, 1 ],
  OpenAIResponses   => [ 1, 1 ],
  Perplexity        => [ 1, 0 ],
  Gemini            => [ 1, 1 ],
);

my @engines;
for my $file ( sort { $a cmp $b } path('lib/Langertha/Engine')->children(qr/\.pm\z/) ) {
  ( my $name = $file->basename ) =~ s/\.pm\z//;
  next if $name =~ /Base\z/ || $name eq 'Remote';
  next unless use_module("Langertha::Engine::$name")->does('Langertha::Role::Chat');
  push @engines, $name;
}
cmp_ok( scalar @engines, '>=', 30, 'found the chat engines' );

subtest 'role composition' => sub {
  for my $name (@engines) {
    my $class = "Langertha::Engine::$name";
    my $want  = $COMPOSES{$name} // [ 0, 0 ];
    is_deeply( [ map { $class->does("Langertha::Role::$_") ? 1 : 0 } qw( ToolResultImages ToolResultPDF ) ],
      $want, "$name composes ToolResultImages=$want->[0] ToolResultPDF=$want->[1]" );
  }
};

subtest 'every engine without the roles claims neither flag' => sub {
  for my $name ( grep { !$COMPOSES{$_} } @engines ) {
    for my $model ( 'some-model', 'gpt-5.6', 'claude-sonnet-4-6', 'gemini-3-flash-preview' ) {
      is_deeply( flags( engine( $name, model => $model ) ), [ 0, 0 ], "$name $model: neither" );
    }
  }
};

subtest 'invariant: tool_result_images implies image_input' => sub {
  my @probe = ( ( map { [ $_->[0], $_->[1] ] } @ROWS ), map { [ $_, 'some-model' ] } @engines );
  for my $pair (@probe) {
    my ( $name, $model ) = @$pair;
    my $engine = engine( $name, model => $model );
    ok( !$engine->supports('tool_result_images') || $engine->supports('image_input'),
      "$name $model" );
  }
};

# ---------------------------------------------------------------------------
# 4. format_tool_results follows supports(): the flag and the wire agree.
# ---------------------------------------------------------------------------
my $ANT_DATA   = { content => [ { type => 'tool_use', id => 'toolu_1', name => 'shot', input => {} } ] };
my $ANT_RESULT = [ { tool_call => { id => 'toolu_1', name => 'shot' },
  result => { content => [$IMAGE_BLOCK] } } ];
my $ANT_IMAGE  = [ { type => 'image', source => { type => 'base64', media_type => 'image/png',
  data => $PNG } } ];
my $ANT_PLACEHOLDER = [ { type => 'text', text => '[image] image/png (18 bytes)' } ];

sub anthropic_content {
  my ($engine) = @_;
  my @msgs = $engine->format_tool_results( $ANT_DATA, $ANT_RESULT );
  return $msgs[-1]{content}[0]{content};
}

subtest 'a learned image_input fact switches the image block on (LMStudioAnthropic)' => sub {
  my $engine = engine( LMStudioAnthropic => model => 'some-vlm' );
  is_deeply( anthropic_content($engine), $ANT_PLACEHOLDER, 'no claim: placeholder' );
  $engine->import_learned_capabilities( { 'some-vlm' => { image_input => 1 } } );
  is_deeply( flags($engine), [ 1, 0 ], 'learned vision: images yes, pdf still no (no source blocks)' );
  is_deeply( anthropic_content($engine), $ANT_IMAGE, '... and the image block goes on the wire' );
  $engine->clear_learned_model_capabilities;
  is_deeply( flags($engine), [ 0, 0 ], 'forgotten: no claim again' );
  is_deeply( anthropic_content($engine), $ANT_PLACEHOLDER, '... and the placeholder is back' );
};

subtest 'a tool_wire_format without a native form clears both flags' => sub {
  my $engine = engine( Anthropic => model => 'claude-sonnet-4-6', tool_wire_format => 'openai' );
  ok( $engine->supports('image_input'), 'the model still sees images' );
  is_deeply( flags($engine), [ 0, 0 ], 'but the openai tool message has no image or PDF form' );
  my @msgs = $engine->format_tool_results( { choices => [ { message => { content => '',
    tool_calls => [] } } ] }, $ANT_RESULT );
  is( $msgs[-1]{content}, '[image] image/png (18 bytes)', '... and the result is the placeholder' );

  my $gemini = engine( Gemini => model => 'gemini-3-flash-preview', tool_wire_format => 'ollama' );
  is_deeply( flags($gemini), [ 0, 0 ], 'Gemini 3 forced onto the ollama wire: neither' );
};

my $PDF_RESULT = [ { tool_call => { id => 'toolu_1', call_id => 'toolu_1', name => 'shot' },
  result => { content => [$PDF_BLOCK] } } ];
my $PDF_PLACEHOLDER = '[resource] application/pdf <file:///docs/report.pdf> (9 bytes)';

# The last tool-result block a forced wire puts on the conversation, per wire.
sub forced_result {
  my ( $engine, $results ) = @_;
  my $fmt = $engine->tool_wire_format;
  if ( $fmt eq 'anthropic' ) {
    my @msgs = $engine->format_tool_results( $ANT_DATA, $results );
    return $msgs[-1]{content}[0]{content};
  }
  if ( $fmt eq 'responses' ) {
    my @items = $engine->format_tool_results( { output => [ { type => 'function_call',
      call_id => 'toolu_1', name => 'shot', arguments => '{}' } ] }, $results );
    return $items[-1]{output};
  }
  my @msgs = $engine->format_tool_results( { candidates => [ { content => { role => 'model',
    parts => [ { functionCall => { name => 'shot', id => 'toolu_1', args => {} } } ] } } ] }, $results );
  my $fr = $msgs[-1]{parts}[0]{functionResponse};
  return $fr->{parts} // $fr->{response}{result};
}

subtest 'forced onto the anthropic wire: an engine without the roles sends placeholders' => sub {
  # AKIOpenAI's qwen3.6 sees images (k271) but AKIOpenAI composes neither role:
  # supports() says no, so neither the image nor the PDF document block goes out.
  my $engine = engine( AKIOpenAI => model => 'qwen3.6-35b', tool_wire_format => 'anthropic' );
  ok( $engine->supports('image_input'), 'the model sees images' );
  is_deeply( flags($engine), [ 0, 0 ], 'no tool_result_images, no tool_result_pdf' );
  is_deeply( forced_result( $engine, $ANT_RESULT ), $ANT_PLACEHOLDER, 'image: placeholder' );
  is_deeply( forced_result( $engine, $PDF_RESULT ), [ { type => 'text', text => $PDF_PLACEHOLDER } ],
    'PDF: placeholder, not a document block' );
};

subtest 'forced onto responses / gemini: a PDF needs image_input there' => sub {
  for my $fmt (qw( responses gemini )) {
    # Text-only models whose own anthropic wire reads PDFs (k371).
    for my $row ( [ Anthropic => 'claude-2.1' ], [ MiniMaxAnthropic => 'MiniMax-M2.7' ] ) {
      my $engine = engine( $row->[0], model => $row->[1], tool_wire_format => $fmt );
      is_deeply( flags($engine), [ 0, 0 ], "$row->[0] $row->[1] on $fmt: neither" );
      is( forced_result( $engine, $PDF_RESULT ), $PDF_PLACEHOLDER, '... the PDF is the placeholder' );
    }
    # A vision model there: the roles are composed and the wire has the form.
    my $engine = engine( Anthropic => model => 'claude-sonnet-4-6', tool_wire_format => $fmt );
    is_deeply( flags($engine), [ 1, 1 ], "Anthropic claude-sonnet-4-6 on $fmt: both" );
    my $out = forced_result( $engine, $PDF_RESULT );
    ok( ref $out eq 'ARRAY' && index( $JSON->encode($out), $PDF ) >= 0, '... the PDF goes out natively' );
  }
};

subtest 'supports() never leaves the wire lookup croak in $@' => sub {
  my $meta = Moose::Meta::Class->create_anon_class(
    superclasses => ['Langertha::Engine::Anthropic'] );
  $meta->add_method( _build_tool_wire_format => sub { die "no wire for you\n" } );
  my $engine = $meta->name->new( api_key => 'k', model => 'claude-sonnet-4-6' );
  local $@ = 'sentinel';
  ok( !$engine->supports('tool_result_images'), 'an unreadable wire: no claim' );
  is( $@, 'sentinel', '$@ is untouched' );
};

done_testing;
