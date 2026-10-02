use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env );
use Langertha::Raider::Config;
use Langertha::Raider::EngineResolver;

# The provider choice on its own, without an application around it:
# engine, model and key precedence, and what goes to the engine class.

clear_engine_env();

sub resolver {
  my ( $yml, %args ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  $root->child('.raider.yml')->spew_utf8(YAML::PP->new->dump_string($yml)) if $yml;
  return Langertha::Raider::EngineResolver->new(
    config => Langertha::Raider::Config->new(root => "$root"),
    %args,
  );
}

subtest 'engine: flag, -o, .raider.yml, environment, anthropic' => sub {
  is(resolver()->engine_name, 'anthropic', 'nothing set');
  {
    local $ENV{GROQ_API_KEY} = 'x';
    is(resolver()->engine_name, 'groq', 'first *_API_KEY found');
    is(resolver({ engine => 'mistral' })->engine_name, 'mistral', '.raider.yml beats the environment');
  }
  is(resolver({ engine => 'mistral' }, engine_options => { engine => 'gemini' })->engine_name,
    'gemini', '-o engine= beats .raider.yml');
  is(resolver({ engine => 'mistral' }, engine => 'openai', engine_options => { engine => 'gemini' })
    ->engine_name, 'openai', 'the flag beats -o');
};

subtest 'model and key' => sub {
  my $r = resolver({ default => { temperature => 0.3 } }, engine => 'openai');
  is($r->model, 'gpt-4o-mini', 'cheap default');
  ok($r->has_model, 'has a model');
  is($r->api_key, '', 'no key anywhere');
  is($r->api_key_env, 'OPENAI_API_KEY', 'key variable');
  local $ENV{OPENAI_API_KEY} = 'env-key';
  is(resolver(undef, engine => 'openai')->api_key, 'env-key', 'key from the environment');
  is(resolver(undef, engine => 'openai', engine_options => { api_key => 'opt-key' })->api_key,
    'opt-key', '-o api_key= beats the environment');
  is(resolver(undef, engine => 'ollama')->api_key_env, undef, 'ollama has no key variable');
  is(Langertha::Raider::EngineResolver->default_model_for_engine('groq'), 'llama-3.3-70b-versatile',
    'default model on the class');
};

subtest 'engine names and key variables' => sub {
  my $class = 'Langertha::Raider::EngineResolver';
  is([ $class->engine_names ],
    [qw( anthropic openai deepseek groq mistral gemini minimax cerebras openrouter ollama )],
    'every known engine, fixed order');
  is(dies { resolver(undef, engine => $_)->engine_class }, undef, 'engine class for '.$_)
    for $class->engine_names;
  is([ $class->api_key_env_vars ],
    [qw( ANTHROPIC_API_KEY OPENAI_API_KEY DEEPSEEK_API_KEY GROQ_API_KEY MISTRAL_API_KEY
      GEMINI_API_KEY MINIMAX_API_KEY CEREBRAS_API_KEY OPENROUTER_API_KEY )],
    'key variables in engine order, ollama left out');
  is([ resolver()->api_key_env_vars ], [ $class->api_key_env_vars ], 'same on an instance');
};

subtest 'engine arguments' => sub {
  my $r = resolver({ default => { temperature => 0.3, model => 'yml-model', perl => 1 } },
    engine => 'openai', model => 'flag-model',
    engine_options => { temperature => 0.5, packs => 'caveman', api_key => 'opt-key' });
  is({ $r->engine_args(mcp_servers => []) },
    { temperature => 0.5, model => 'flag-model', api_key => 'opt-key', mcp_servers => [] },
    '-o over .raider.yml, raider keys left out, flag model last');
  is($r->engine_class, 'Langertha::Engine::OpenAI', 'engine class');
  my $engine = $r->build_engine(mcp_servers => []);
  isa_ok($engine, 'Langertha::Engine::OpenAI');
  is($engine->model, 'flag-model', 'built with the model');
  is(dies { resolver(undef, engine => 'nope')->engine_class }, "Unknown engine: nope\n",
    'unknown engine');
};

# karr #86: without -m, an engine with no built-in table default must NOT be
# built with model => '' -- that empty string overrides the engine's own
# default_model (MiniMax-M3, llama3.3, ...) and the provider 400s. Reading
# ->model first mirrors the real order (run.started / explain touch it), which
# used to flip the lazy 'has_explicit_model' predicate and make engine_args
# emit the empty model on the next call.
subtest 'no engine emits an empty model without -m' => sub {
  my $class = 'Langertha::Raider::EngineResolver';
  for my $engine ($class->engine_names) {
    my $r = resolver(undef, engine => $engine);
    $r->model;   # build the lazy slot first, as the application does
    my %args = $r->engine_args;
    ok(!(exists $args{model} && !length $args{model}),
      "$engine: engine_args never carries an empty model")
      or diag "model => '".($args{model} // 'undef')."'";
  }
};

subtest 'engines without a table default let the engine choose' => sub {
  for my $engine (qw( minimax openrouter ollama )) {
    my $r = resolver(undef, engine => $engine);
    $r->model;   # flip attempt
    ok(!$r->has_model, "$engine: has_model is false without -m");
    my %args = $r->engine_args;
    ok(!exists $args{model}, "$engine: engine_args omits model, engine default applies");
  }
};

subtest 'default_model_for_engine shows the engine default the table lacks' => sub {
  my $class = 'Langertha::Raider::EngineResolver';
  require Langertha::Engine::MiniMax;
  require Langertha::Engine::Ollama;
  is($class->default_model_for_engine('minimax'), Langertha::Engine::MiniMax->default_model,
    'minimax mirrors its engine default_model');
  is($class->default_model_for_engine('ollama'), Langertha::Engine::Ollama->default_model,
    'ollama mirrors its engine default_model');
  is($class->default_model_for_engine('openrouter'), undef,
    'openrouter has no default -- it requires an explicit model');
  is($class->default_model_for_engine('anthropic'), 'claude-haiku-4-5',
    "anthropic keeps raider's cheap table default, not core's flagship");
};

done_testing;
