#!/usr/bin/env perl
# ABSTRACT: embedding_dimensions reaches the wire per engine (dimensions / output_dimension / outputDimensionality, or not at all); no translation operation
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::OpenAI;
use Langertha::Engine::vLLM;
use Langertha::Engine::Gemini;
use Langertha::Engine::Whisper;

# karr k316 (from k309):
#  - simple_embedding / simple_embedding_f take only the text, so a shortened
#    vector (OpenAI `dimensions`, Gemini `outputDimensionality`) was reachable
#    only by building the request by hand with embedding_request. The engine
#    attribute embedding_dimensions carries it through every embedding call; a
#    per-request extra still wins over it, and unset it sends nothing, so the
#    model's native size stays the default.
#  - TranscriptionBase allowed the createTranslation operation although no
#    method builds such a request; Langertha has no translation feature, so the
#    operation is not allowed.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);
sub body { $json->decode( $_[0]->content ) }

subtest 'OpenAI-compatible: dimensions' => sub {
  my $plain = Langertha::Engine::OpenAI->new( api_key => 'k' );
  ok !exists body( $plain->embedding('x') )->{dimensions}, 'unset: no dimensions field';

  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k', embedding_dimensions => 256 );
  is $openai->embedding_dimensions, 256, 'attribute readable';
  is body( $openai->embedding('x') )->{dimensions}, 256, 'embedding() sends dimensions';
  is body( $openai->embedding([qw( a b )]) )->{dimensions}, 256, 'a batch sends it once';
  is body( $openai->embedding_request( 'x', dimensions => 64 ) )->{dimensions}, 64,
    'a per-request dimensions extra wins over the attribute';

  my $vllm = Langertha::Engine::vLLM->new( url => 'http://localhost:8000/v1', embedding_dimensions => 32 );
  is body( $vllm->embedding('x') )->{dimensions}, 32, 'any OpenAI-compatible engine sends it';
};

# karr k319: embedding_dimensions is spelled per engine, and an engine that
# documents no such field does not send it (a silent drop on llama.cpp, a 400 on
# Mistral's additionalProperties:false schema, unverified elsewhere): the caller
# gets one carp instead of a vector of the wrong size or a rejected request.
sub warnings_of {
  my ( $code ) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $code->();
  return \@warnings;
}

subtest 'k319: dimensions on OpenAI, OllamaOpenAI, vLLM, VLLMHook, SGLang' => sub {
  require Langertha::Engine::OllamaOpenAI;
  require Langertha::Engine::VLLMHook;
  require Langertha::Engine::SGLang;
  for my $engine (
    Langertha::Engine::OpenAI->new( api_key => 'k', embedding_dimensions => 256 ),
    Langertha::Engine::OllamaOpenAI->new( url => 'http://localhost:11434/v1', embedding_dimensions => 256 ),
    Langertha::Engine::vLLM->new( url => 'http://localhost:8000/v1', embedding_dimensions => 256 ),
    Langertha::Engine::VLLMHook->new( url => 'http://localhost:8000/v1', embedding_dimensions => 256 ),
    Langertha::Engine::SGLang->new( url => 'http://localhost:30000/v1', embedding_dimensions => 256 ),
  ) {
    my $body;
    my $warnings = warnings_of( sub { $body = body( $engine->embedding('x') ) } );
    is $body->{dimensions}, 256, ref($engine).': dimensions sent';
    is scalar @$warnings, 0, ref($engine).': no carp';
  }
};

subtest 'k319: Mistral output_dimension for codestral-embed only' => sub {
  require Langertha::Engine::Mistral;
  my $codestral = Langertha::Engine::Mistral->new(
    api_key => 'k', embedding_model => 'codestral-embed-2505', embedding_dimensions => 512 );
  my $body;
  my $warnings = warnings_of( sub { $body = body( $codestral->embedding('x') ) } );
  is $body->{output_dimension}, 512, 'codestral-embed: output_dimension sent';
  ok !exists $body->{dimensions}, 'codestral-embed: not as dimensions';
  is scalar @$warnings, 0, 'codestral-embed: no carp';
  is body( $codestral->embedding_request( 'x', output_dimension => 256 ) )->{output_dimension}, 256,
    'an output_dimension extra wins';

  my $mistral = Langertha::Engine::Mistral->new( api_key => 'k', embedding_dimensions => 512 );
  $warnings = warnings_of( sub {
    $body = body( $mistral->embedding('x') );
    $mistral->embedding('y');
  } );
  ok !exists $body->{dimensions} && !exists $body->{output_dimension},
    'mistral-embed: nothing sent';
  is scalar @$warnings, 1, 'mistral-embed: carps once per instance';
  like $warnings->[0], qr/embedding_dimensions=512.*mistral-embed/, 'carp names value and model';
  like $warnings->[0], qr/at \Q${\ __FILE__}\E line/, 'carp points at the caller';
};

subtest 'k319: not sent + carp on Scaleway, LlamaCpp, LMStudioOpenAI, TSystems' => sub {
  require Langertha::Engine::Scaleway;
  require Langertha::Engine::LlamaCpp;
  require Langertha::Engine::LMStudioOpenAI;
  require Langertha::Engine::TSystems;
  for my $engine (
    Langertha::Engine::Scaleway->new( api_key => 'k', embedding_dimensions => 128 ),
    Langertha::Engine::LlamaCpp->new( url => 'http://localhost:8080/v1', embedding_dimensions => 128 ),
    Langertha::Engine::LMStudioOpenAI->new( embedding_dimensions => 128 ),
    Langertha::Engine::TSystems->new( api_key => 'k', embedding_dimensions => 128 ),
  ) {
    my $name = ref $engine;
    my $body;
    my $warnings = warnings_of( sub {
      $body = body( $engine->embedding('x') );
      $engine->embedding('y');
    } );
    ok !exists $body->{dimensions}, "$name: dimensions not sent";
    is scalar @$warnings, 1, "$name: carps once";
    like $warnings->[0], qr/not sending embedding_dimensions=128/, "$name: carp says why";

    $warnings = warnings_of( sub { $body = body( $engine->embedding_request( 'x', dimensions => 64 ) ) } );
    is $body->{dimensions}, 64, "$name: an explicit dimensions extra passes through untouched";
    is scalar @$warnings, 0, "$name: and does not carp";
  }
  my $unset = Langertha::Engine::LlamaCpp->new( url => 'http://localhost:8080/v1' );
  is scalar @{ warnings_of( sub { $unset->embedding('x') } ) }, 0, 'unset attribute: no carp';
};

subtest 'k319: Ollama native /api/embed sends top-level dimensions' => sub {
  require Langertha::Engine::Ollama;
  my $plain = Langertha::Engine::Ollama->new( url => 'http://localhost:11434' );
  ok !exists body( $plain->embedding('x') )->{dimensions}, 'unset: no dimensions field';
  my $ollama = Langertha::Engine::Ollama->new( url => 'http://localhost:11434', embedding_dimensions => 128 );
  is body( $ollama->embedding('x') )->{dimensions}, 128, 'dimensions sent';
  is body( $ollama->embedding_request( 'x', dimensions => 64 ) )->{dimensions}, 64, 'extra wins';
};

subtest 'Gemini: embedContentConfig.outputDimensionality' => sub {
  my $plain = Langertha::Engine::Gemini->new( api_key => 'k' );
  ok !exists body( $plain->embedding('x') )->{embedContentConfig}, 'unset: no embedContentConfig';

  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', embedding_dimensions => 768 );
  is_deeply body( $gemini->embedding('x') )->{embedContentConfig},
    { outputDimensionality => 768 }, 'single request: in embedContentConfig';
  ok !exists body( $gemini->embedding('x') )->{outputDimensionality},
    'not the deprecated top-level spelling';
  is_deeply [ map { $_->{embedContentConfig} } @{ body( $gemini->embedding([qw( a b )]) )->{requests} } ],
    [ { outputDimensionality => 768 }, { outputDimensionality => 768 } ],
    'batch: every request carries it';
  is_deeply body( $gemini->embedding_request( 'x', task_type => 'RETRIEVAL_QUERY' ) )->{embedContentConfig},
    { outputDimensionality => 768, taskType => 'RETRIEVAL_QUERY' },
    'merged with other config extras';
  is body( $gemini->embedding_request( 'x', output_dimensionality => 128 ) )
    ->{embedContentConfig}{outputDimensionality}, 128, 'output_dimensionality extra wins';
  is body( $gemini->embedding_request( 'x', embedContentConfig => { outputDimensionality => 64 } ) )
    ->{embedContentConfig}{outputDimensionality}, 64, 'a caller embedContentConfig wins';
};

subtest 'TranscriptionBase: no translation operation' => sub {
  my $whisper = Langertha::Engine::Whisper->new( url => 'http://localhost:8000/v1' );
  ok $whisper->can_operation('createTranscription'), 'transcription allowed';
  ok !$whisper->can_operation('createTranslation'), 'translation not allowed';
  my $handle = Langertha::Engine::OpenAI->new( api_key => 'k' )->whisper;
  ok !$handle->can_operation('createTranslation'), 'nor on the OpenAI whisper handle';
};

done_testing;
