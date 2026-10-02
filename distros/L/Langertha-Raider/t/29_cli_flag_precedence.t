use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Langertha::Raider::CLI;

# Explicit CLI flags (-m, -k, -o, -e) beat .raider.yml, and the model the
# banner shows ($app->model) is the one the engine is built with.

sub root_with {
  my ( $yml ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  $root->child('.raider.yml')->spew_utf8(YAML::PP->new->dump_string($yml));
  return "$root";
}

sub app {
  my ( $root, %args ) = @_;
  return Langertha::Raider::CLI->new(root => $root, engine => 'openai', trace => 0, %args);
}

my $root = root_with({ default => { model => 'yml-model', temperature => 0.3 } });

subtest '-m beats model: from .raider.yml' => sub {
  my $app = app($root, api_key => 'test', model => 'flag-model');
  is($app->model, 'flag-model', 'banner model');
  is($app->_engine->model, 'flag-model', 'engine model');
  is($app->_engine->temperature, 0.3, 'other yml options still apply');
};

subtest 'model: from .raider.yml beats the engine default' => sub {
  my $app = app($root, api_key => 'test');
  is($app->model, 'yml-model', 'banner shows the yml model');
  is($app->_engine->model, 'yml-model', 'engine model');
};

subtest '-o model= beats .raider.yml, -m beats -o' => sub {
  my $opt = app($root, api_key => 'test', engine_options => { model => 'opt-model' });
  is($opt->model, 'opt-model', 'banner model from -o');
  is($opt->_engine->model, 'opt-model', 'engine model from -o');

  my $both = app($root, api_key => 'test', model => 'flag-model',
    engine_options => { model => 'opt-model' });
  is($both->model, 'flag-model', 'banner model from -m');
  is($both->_engine->model, 'flag-model', 'engine model from -m');
};

subtest 'no model anywhere: engine default' => sub {
  my $app = app(root_with({}), api_key => 'test');
  is($app->model, 'gpt-4o-mini', 'cheap default');
  is($app->_engine->model, 'gpt-4o-mini', 'engine model');
};

subtest '-k beats api_key: from .raider.yml' => sub {
  my $keyed = root_with({ default => { api_key => 'yml-key' } });
  is(app($keyed, api_key => 'flag-key')->_engine->api_key, 'flag-key', 'flag key wins');
  local $ENV{OPENAI_API_KEY} = 'env-key';
  is(app($keyed)->_engine->api_key, 'yml-key', 'yml key beats the environment');
};

subtest '-e beats engine: from .raider.yml' => sub {
  my $engined = root_with({ engine => 'anthropic', anthropic => { model => 'a-model' } });
  my $app = app($engined, api_key => 'test');
  is($app->engine_name, 'openai', 'flag engine');
  is($app->model, 'gpt-4o-mini', 'inactive engine section not applied');
};

done_testing;
