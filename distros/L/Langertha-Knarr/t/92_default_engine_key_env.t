use strict;
use warnings;
use Test2::V0;
use YAML::PP;

# Regression (k45): --from-env and `knarr init` wrote the default engine as
# `default: { engine: OpenAI }` without api_key_env. Langertha's OpenAI
# engine reads only LANGERTHA_OPENAI_API_KEY by itself, so with the
# documented OPENAI_API_KEY every request answered by the default engine
# croaked for a missing key. The generated default names the variable that
# was actually found, like the models: entries do.

use Langertha::Knarr::Config;
use Langertha::Knarr::Router;

my @OPENAI_VARS = qw( LANGERTHA_OPENAI_API_KEY OPENAI_API_KEY TEST_LANGERTHA_OPENAI_API_KEY );

for my $var (@OPENAI_VARS) {
  local @ENV{@OPENAI_VARS};
  delete $ENV{$_} for @OPENAI_VARS;
  $ENV{$var} = "sk-from-$var";

  my $config = Langertha::Knarr::Config->from_env;
  is $config->default_engine, { engine => 'OpenAI', api_key_env => $var },
    "from_env: default names $var";

  # The engine the default builds carries the key -- no LANGERTHA_* needed.
  my $router = Langertha::Knarr::Router->new( config => $config );
  my ($engine) = $router->resolve(undef);
  is $engine->api_key, "sk-from-$var", "from_env: default engine reads its key from $var";

  my $found  = Langertha::Knarr::Config->scan_env;
  my $parsed = YAML::PP->new->load_string(
    Langertha::Knarr::Config->generate_config( engines => $found ) );
  is $parsed->{default}, { engine => 'OpenAI', api_key_env => $var },
    "generate_config: default names $var";

  my $generated = Langertha::Knarr::Config->new( data => $parsed );
  ($engine) = Langertha::Knarr::Router->new( config => $generated )->resolve(undef);
  is $engine->api_key, "sk-from-$var", "generate_config: default engine reads its key from $var";
}

# No OpenAI key: no default engine, as before.
{
  local @ENV{@OPENAI_VARS};
  delete $ENV{$_} for @OPENAI_VARS;
  local $ENV{LANGERTHA_ANTHROPIC_API_KEY} = 'sk-ant';
  is( Langertha::Knarr::Config->from_env->default_engine, undef, 'from_env: no OpenAI key, no default' );
  my $parsed = YAML::PP->new->load_string( Langertha::Knarr::Config->generate_config(
    engines => Langertha::Knarr::Config->scan_env ) );
  ok !exists $parsed->{default}, 'generate_config: no OpenAI key, default stays commented out';
}

done_testing;
