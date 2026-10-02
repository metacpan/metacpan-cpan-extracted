use strict;
use warnings;
use Log::Any::Test;
use Log::Any qw( $log );
use Test2::V0;

# k30: a model config's context_size is operator intent. The router hands it
# to engines that compose core's Role::ContextSize, and those engines put it
# on the wire (Ollama's options.num_ctx) -- the accepted consequence. An
# engine without the role cannot take it: the value is dropped, and the
# operator hears about it once, when the config is loaded, not per request
# and not never.

use JSON::MaybeXS;
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub context_warnings {
  [ grep { $_->{level} eq 'warning' && $_->{message} =~ /context_size/ } @{ $log->msgs } ];
}

my $config = Langertha::Knarr::Config->new( data => {
  models => {
    'ollama-ctx' => { engine => 'Ollama', model => 'llama3', url => 'http://127.0.0.1:1',
                      context_size => 8192 },
    'ollama-bare' => { engine => 'Ollama', model => 'llama3', url => 'http://127.0.0.1:1' },
    'openai-ctx' => { engine => 'OpenAI', model => 'gpt-5.6', api_key => 'sk-test',
                      context_size => 8192 },
  },
  default => { engine => 'OpenAI', api_key => 'sk-test', context_size => 4096 },
} );

subtest 'engines without Role::ContextSize warn once, at config load' => sub {
  $log->clear;
  is( [ $config->validate ], [], 'config with context_size validates' );
  my $warnings = context_warnings();
  is( scalar @$warnings, 2, 'one warning per ignoring entry (model + default)' );
  like( $warnings->[0]{message}, qr/Model 'openai-ctx'.*OpenAI does not take context_size/,
    'names the model and engine' );
  like( $warnings->[1]{message}, qr/Default.*OpenAI does not take context_size/,
    'names the default engine' );

  $log->clear;
  my $router = Langertha::Knarr::Router->new( config => $config );
  my ($engine) = $router->resolve('openai-ctx');
  ok( !$engine->can('context_size'), 'OpenAI engine has no context_size attribute' );
  $router->resolve('some-unlisted-model');
  $config->validate;
  is( context_warnings(), [], 'no repeat warnings on resolve or re-validate' );
};

subtest 'Role::ContextSize engines get the configured context_size' => sub {
  my $router = Langertha::Knarr::Router->new( config => $config );
  my ($engine) = $router->resolve('ollama-ctx');
  ok( $engine->has_context_size, 'engine has an explicit context_size' );
  is( $engine->context_size, 8192, 'context_size is the configured one' );

  my $body = $json->decode( $engine->chat( { role => 'user', content => 'hi' } )->content );
  is( $body->{options}{num_ctx}, 8192, 'Ollama native request carries num_ctx' );

  # Same engine, url and model, no context_size: context_size is read-only
  # on the engine, so the cached ollama-ctx instance must not be reused.
  my ($bare) = $router->resolve('ollama-bare');
  isnt( "$bare", "$engine", 'alias without context_size gets its own instance' );
  ok( !$bare->has_context_size, 'unconfigured model leaves context_size unset' );
  my $bare_body = $json->decode( $bare->chat( { role => 'user', content => 'hi' } )->content );
  ok( !exists $bare_body->{options}{num_ctx}, 'no num_ctx without a configured context_size' );
};

subtest 'context_size must be a positive integer' => sub {
  my $bad = Langertha::Knarr::Config->new( data => {
    models  => { 'm' => { engine => 'Ollama', url => 'http://127.0.0.1:1', context_size => '8k' } },
    default => { engine => 'Ollama', url => 'http://127.0.0.1:1', context_size => 0 },
  } );
  is( [ sort $bad->validate ], [
    "Default: context_size must be a positive integer",
    "Model 'm': context_size must be a positive integer",
  ], 'validate rejects non-integer and zero' );
};

# k31: a context window belongs to one model. A model found by auto_discover
# is routed with the config of the entry it was discovered through, but must
# not inherit that entry's context_size -- on Ollama it would size another
# model's context via num_ctx. Endpoint-level settings still carry over.
{
  package LangerthaX::Engine::TestOllamaDiscover;
  use Moose;
  extends 'Langertha::Engine::Ollama';
  sub list_models { [ 'llama3', 'qwen3' ] }
}

subtest 'discovered models do not inherit context_size' => sub {
  my $discover = Langertha::Knarr::Config->new( data => {
    auto_discover => 1,
    models => {
      'llama-big' => { engine => 'TestOllamaDiscover', model => 'llama3',
                       url => 'http://127.0.0.1:1', context_size => 32768,
                       system_prompt => 'Be brief.', temperature => 0.3,
                       response_size => 512 },
    },
  } );
  my $router = Langertha::Knarr::Router->new( config => $discover );

  my ($engine, $model) = $router->resolve('qwen3');
  is( $model, 'qwen3', 'discovered model resolves to itself' );
  isa_ok( $engine, 'LangerthaX::Engine::TestOllamaDiscover' );
  ok( !$engine->has_context_size, 'discovered model has no inherited context_size' );
  my $body = $json->decode( $engine->chat( { role => 'user', content => 'hi' } )->content );
  ok( !exists $body->{options}{num_ctx}, 'no num_ctx on the discovered model\'s wire' );

  is( $engine->url, 'http://127.0.0.1:1', 'keeps the endpoint url' );
  is( $engine->system_prompt, 'Be brief.', 'keeps the endpoint system_prompt' );
  is( $engine->temperature, 0.3, 'keeps the endpoint temperature' );
  is( $engine->response_size, 512, 'keeps the endpoint response_size' );

  my ($configured) = $router->resolve('llama-big');
  is( $configured->context_size, 32768, 'the configured entry keeps its own context_size' );
};

done_testing;
