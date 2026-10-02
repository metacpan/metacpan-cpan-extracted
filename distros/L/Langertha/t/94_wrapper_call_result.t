#!/usr/bin/env perl
# ABSTRACT: Embedder / ImageGen simple_*_result(_f) return a CallResult through the plugin hooks; Plugin::Langfuse records its model, usage and timing
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use Scalar::Util qw( refaddr );
use Test::MockAsyncHTTP;
use Langertha::Embedder;
use Langertha::ImageGen;
use Langertha::Engine::OpenAI;
use Langertha::Plugin::Langfuse;
use Langertha::Pricing;

# karr k320 (ADR 0034 Update): the engines' simple_embedding_result /
# simple_image_result carry usage, rate limit, model and timing, but
# Langertha::Embedder and Langertha::ImageGen -- the wrappers plugins attach
# to -- had no such method, so a Langfuse user could not see what an
# embedding or image generation cost. The wrappers now have *_result(_f):
# same model override and hooks as the bare methods; the after-hook gets
# the CallResult as an optional third argument (two-argument hooks keep
# working); a hook that replaces the value yields a new CallResult with the
# metadata kept, since CallResult is immutable.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub embedding_response {
  return Test::MockAsyncHTTP->mock_json_response({
    object => 'list', model => 'text-embedding-3-large-v9',
    data   => [ { object => 'embedding', index => 0, embedding => [ 0.25, 0.5 ] } ],
    usage  => { prompt_tokens => 8, total_tokens => 8 },
  });
}

sub image_response {
  return Test::MockAsyncHTTP->mock_json_response({
    created => 1, data => [ { b64_json => 'aGk=' } ],
    usage   => { input_tokens => 9, output_tokens => 100, total_tokens => 109 },
  });
}

sub engine_with {
  my ( $response, %args ) = @_;
  my $mock = Test::MockAsyncHTTP->new( responses => [$response] );
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'sk-test',
    url => 'http://mock.invalid/v1', _async_http => $mock, %args );
  return ( $engine, $mock );
}

sub body_of { $json->decode( ( $_[0]->requests )[-1]->content ) }

# A sync engine: user_agent answers from a canned response, recording requests.
{
  package CannedUA;
  use parent 'LWP::UserAgent';
  sub new { my ( $class, $response ) = @_; my $self = LWP::UserAgent::new($class); $self->{canned} = $response; $self->{sent} = []; $self }
  sub request { my ( $self, $request ) = @_; push @{ $self->{sent} }, $request; return $self->{canned} }
}

{
  package RecordingPlugin;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  has seen    => ( is => 'ro', default => sub { [] } );
  has replace => ( is => 'ro' );
  async sub plugin_after_embedding {
    my ( $self, @args ) = @_;
    push @{ $self->seen }, [ @args ];
    return $self->replace // $args[1];
  }
  async sub plugin_after_image_gen {
    my ( $self, @args ) = @_;
    push @{ $self->seen }, [ @args ];
    return $self->replace // $args[1];
  }
  __PACKAGE__->meta->make_immutable;
}

subtest 'Embedder simple_embedding_result_f: model override, CallResult to the hook, unchanged value keeps the object' => sub {
  my ( $engine, $mock ) = engine_with( embedding_response(), embedding_model => 'text-embedding-3-small' );
  my $embedder = Langertha::Embedder->new( engine => $engine, model => 'text-embedding-3-large',
    plugins => ['+RecordingPlugin'] );
  my $plugin = $embedder->plugin_instances->[0];

  my $result = $embedder->simple_embedding_result_f('hello')->get;
  isa_ok $result, 'Langertha::CallResult';
  is body_of($mock)->{model}, 'text-embedding-3-large', 'the Embedder model override is sent';
  is_deeply $result->value, [ 0.25, 0.5 ], 'value is the vector';
  is $result->usage->input_tokens, 8, 'usage kept';
  is $result->model, 'text-embedding-3-large-v9', 'answering model';
  ok $result->has_total_seconds, 'timing kept';

  my ($call) = @{ $plugin->seen };
  is scalar @$call, 3, 'the after-hook gets ($text, $vector, $call_result)';
  is $call->[0], 'hello', 'text';
  is refaddr( $call->[2] ), refaddr($result), 'the CallResult handed to the hook is the one returned';
};

subtest 'Embedder: a hook that replaces the vector yields a new CallResult, metadata kept' => sub {
  my ( $engine ) = engine_with( embedding_response() );
  my $embedder = Langertha::Embedder->new( engine => $engine,
    plugins => [ '+RecordingPlugin' => { replace => [ 1, 0 ] } ] );
  my $plugin = $embedder->plugin_instances->[0];

  my $result = $embedder->simple_embedding_result_f('hello')->get;
  is_deeply $result->value, [ 1, 0 ], 'value is what the hook returned';
  is $result->usage->input_tokens, 8, 'usage copied';
  is $result->model, 'text-embedding-3-large-v9', 'model copied';
  ok $result->has_total_seconds && $result->has_raw, 'timing and raw copied';

  my $given = $plugin->seen->[0][2];
  isnt refaddr($given), refaddr($result), 'a new object';
  is_deeply $given->value, [ 0.25, 0.5 ], 'the CallResult the hook saw is unchanged (immutable)';
};

subtest 'Embedder simple_embedding_result (sync) over the engine user_agent' => sub {
  my $ua = CannedUA->new( embedding_response() );
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'sk-test', url => 'http://mock.invalid/v1',
    user_agent => $ua );
  my $embedder = Langertha::Embedder->new( engine => $engine, model => 'text-embedding-3-large',
    plugins => ['+RecordingPlugin'] );
  my $result = $embedder->simple_embedding_result('hello');
  isa_ok $result, 'Langertha::CallResult';
  is $json->decode( $ua->{sent}[0]->content )->{model}, 'text-embedding-3-large', 'override sent';
  is $result->usage->total_tokens, 8, 'usage';
  is scalar @{ $embedder->plugin_instances->[0]->seen->[0] }, 3, 'hook got the CallResult';
};

subtest 'bare simple_embedding still calls the after-hook with two arguments' => sub {
  my ( $engine ) = engine_with( embedding_response() );
  my $embedder = Langertha::Embedder->new( engine => $engine, plugins => ['+RecordingPlugin'] );
  my $vector = $embedder->simple_embedding_f('hello')->get;
  is_deeply $vector, [ 0.25, 0.5 ], 'bare value';
  is scalar @{ $embedder->plugin_instances->[0]->seen->[0] }, 2, 'no CallResult on the bare path';
};

subtest 'Role::Embedding simple_embedding_result takes a model extra' => sub {
  my ( $engine, $mock ) = engine_with( Test::MockAsyncHTTP->mock_json_response({
    data => [ { index => 0, embedding => [ 1 ] } ] }), embedding_model => 'text-embedding-3-small' );
  my $result = $engine->simple_embedding_result_f( 'hi', model => 'custom-embed' )->get;
  is body_of($mock)->{model}, 'custom-embed', 'extra model sent';
  is $result->model, 'custom-embed', 'the requested model when the body names none';
};

subtest 'ImageGen simple_image_result_f: overrides, CallResult to the hook, replacement' => sub {
  my ( $engine, $mock ) = engine_with( image_response() );
  my $ig = Langertha::ImageGen->new( engine => $engine, model => 'gpt-image-2', size => '1024x1024',
    plugins => ['+RecordingPlugin'] );
  my $result = $ig->simple_image_result_f('A cat')->get;
  isa_ok $result, 'Langertha::CallResult';
  my $body = body_of($mock);
  is $body->{model}, 'gpt-image-2', 'model override sent';
  is $body->{size},  '1024x1024',   'size override sent';
  is $result->usage->output_tokens, 100, 'image usage';
  is $result->model, 'gpt-image-2', 'requested model';
  my $call = $ig->plugin_instances->[0]->seen->[0];
  is scalar @$call, 3, 'after-hook gets the CallResult';
  is refaddr( $call->[2] ), refaddr($result), 'unchanged value keeps the engine CallResult';

  my ( $engine2 ) = engine_with( image_response() );
  my $ig2 = Langertha::ImageGen->new( engine => $engine2,
    plugins => [ '+RecordingPlugin' => { replace => ['filtered'] } ] );
  my $replaced = $ig2->simple_image_result_f('A cat')->get;
  is_deeply $replaced->value, ['filtered'], 'hook value';
  is $replaced->usage->total_tokens, 109, 'usage copied';
};

subtest 'ImageGen simple_image_result (sync)' => sub {
  my $ua = CannedUA->new( image_response() );
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'sk-test', url => 'http://mock.invalid/v1',
    user_agent => $ua );
  my $ig = Langertha::ImageGen->new( engine => $engine, quality => 'low' );
  my $result = $ig->simple_image_result('A cat');
  is $json->decode( $ua->{sent}[0]->content )->{quality}, 'low', 'quality override sent';
  is $result->usage->input_tokens, 9, 'usage';
};

sub langfuse_generation {
  my ($lf) = @_;
  my ($gen) = grep { $_->{type} eq 'generation-create' } @{ $lf->_batch };
  return $gen->{body};
}

subtest 'Langfuse: embedding generation carries model, usage, cost and total_seconds' => sub {
  my ( $engine ) = engine_with( embedding_response() );
  my $embedder = Langertha::Embedder->new( engine => $engine, plugins => [ Langfuse => {
    public_key => 'pk', secret_key => 'sk',
    pricing => Langertha::Pricing->new( rules => {
      'text-embedding-3-large-v9' => { input_per_million => 0.13 } } ) } ] );
  my $lf = $embedder->plugin_instances->[0];
  $embedder->simple_embedding_result_f('hello')->get;
  my $body = langfuse_generation($lf);
  is $body->{name}, 'embedding', 'embedding generation';
  is $body->{model}, 'text-embedding-3-large-v9', 'model that answered';
  is $body->{usage}{input}, 8, 'input tokens';
  is $body->{usage}{total}, 8, 'total tokens';
  ok abs( $body->{usage}{inputCost} - 8 * 0.13 / 1_000_000 ) < 1e-15, 'input cost from the pricing rule';
  ok defined $body->{metadata}{total_seconds} && $body->{metadata}{total_seconds} >= 0,
    'total_seconds in metadata';
};

subtest 'Langfuse: image generation carries model, usage and total_seconds' => sub {
  my ( $engine ) = engine_with( image_response() );
  my $ig = Langertha::ImageGen->new( engine => $engine, model => 'gpt-image-2',
    plugins => [ Langfuse => { public_key => 'pk', secret_key => 'sk' } ] );
  my $lf = $ig->plugin_instances->[0];
  $ig->simple_image_result_f('A cat')->get;
  my $body = langfuse_generation($lf);
  is $body->{name}, 'image-generation', 'image generation';
  is $body->{model}, 'gpt-image-2', 'model';
  is $body->{usage}{output}, 100, 'output tokens';
  ok defined $body->{metadata}{total_seconds}, 'total_seconds in metadata';
};

subtest 'Langfuse: the bare path records no model or usage (nothing to read)' => sub {
  my ( $engine ) = engine_with( embedding_response() );
  my $embedder = Langertha::Embedder->new( engine => $engine,
    plugins => [ Langfuse => { public_key => 'pk', secret_key => 'sk' } ] );
  my $lf = $embedder->plugin_instances->[0];
  $embedder->simple_embedding_f('hello')->get;
  my $body = langfuse_generation($lf);
  ok !exists $body->{usage} && !exists $body->{model} && !exists $body->{metadata}, 'bare generation unchanged';
};

done_testing;
