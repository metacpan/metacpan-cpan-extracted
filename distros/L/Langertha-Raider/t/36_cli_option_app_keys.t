#!/usr/bin/env perl
# ABSTRACT: -o with raider's own keys configures raider, not the engine

use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use Langertha::Raider::CLI;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY DEEPSEEK_API_KEY
  GROQ_API_KEY MISTRAL_API_KEY GEMINI_API_KEY )};

sub root_with {
  my ( $yml ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  $root->child('.raider.yml')->spew_utf8(YAML::PP->new->dump_string($yml)) if $yml;
  return "$root";
}

sub entry {
  my ( $report, $key ) = @_;
  my @hits = grep { $_->{key} eq $key } @{ $report->{values} };
  return wantarray ? @hits : $hits[0];
}

sub app {
  my ( $root, %opts ) = @_;
  return Langertha::Raider::CLI->new(
    root => $root, engine => 'openai', api_key => 'test', model => 'gpt-4o-mini',
    engine_options => \%opts,
  );
}

subtest 'raider keys never reach the engine constructor' => sub {
  my $app = app(root_with(), perl => 1, packs => 'polite', preferred_lib_target => 'x',
    skills => 'notes', engine => 'openai', temperature => 0.3);
  my %args = $app->_engine_args;
  is([ sort grep { $_ ne 'mcp_servers' } keys %args ], [qw( api_key model temperature )],
    'only engine keys');
};

subtest '-o behaves like .raider.yml for raider keys' => sub {
  my $root = root_with();
  my $app = app($root, perl => 1, packs => 'polite,git-guru', preferred_lib_target => 'x');
  is($app->_load_yml_options->{perl}, 1, 'perl');
  is($app->_load_yml_options->{preferred_lib_target}, 'x', 'preferred_lib_target');
  is([ sort @{ $app->packs->enabled_pack_names } ], [qw( git-guru polite )], 'packs, comma list');

  path($root)->child('notes')->mkpath;
  path($root)->child('notes/a.md')->spew_utf8("hello\n");
  my $skills = app($root, skills => 'notes');
  is([ $skills->loaded_skill_names ], ['a.md'], 'skills');
};

subtest '-o wins over .raider.yml, --pack over -o' => sub {
  my $root = root_with({ perl => 1, packs => ['caveman'] });
  my $app = app($root, perl => 0, packs => 'polite');
  is($app->_load_yml_options->{perl}, 0, '-o perl=0 over perl: true');
  is($app->packs->enabled_pack_names, ['polite'], '-o packs over packs:');

  my $flag = Langertha::Raider::CLI->new(root => $root, engine => 'openai', api_key => 'test',
    pack_names => ['teacher'], engine_options => { packs => 'polite' });
  is($flag->packs->enabled_pack_names, ['teacher'], '--pack over -o');
};

subtest '-o engine= picks the engine' => sub {
  my $app = Langertha::Raider::CLI->new(root => root_with({ engine => 'openai' }),
    engine_options => { engine => 'groq' });
  is($app->engine_name, 'groq', '-o engine over engine:');
};

subtest 'explain names -o and applies_to raider' => sub {
  my $root = root_with({ perl => 1 });
  path($root)->child('notes')->mkpath;
  my $report = app($root, perl => 0, packs => 'polite', skills => 'notes', seed => 3)->explain_config;
  like(entry($report, 'perl'), { value => 0, source => '-o', shadowed => ['.raider.yml'],
    applies_to => 'raider' }, 'perl');
  like(entry($report, 'packs'), { value => ['polite'], source => '-o', applies_to => 'raider' }, 'packs');
  like([ entry($report, 'skills') ], [ { value => ['notes'], source => '-o', merged => 1,
    applies_to => 'raider' } ], 'skills');
  like(entry($report, 'seed'), { source => '-o', applies_to => 'engine' }, 'engine key unchanged');

  my $eng = Langertha::Raider::CLI->new(root => root_with({ engine => 'openai' }),
    engine_options => { engine => 'groq' })->explain_config;
  like(entry($eng, 'engine'), { value => 'groq', source => '-o', shadowed => ['.raider.yml'] }, 'engine');
};

done_testing;
