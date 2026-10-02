use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::CLI;
use Langertha::Raider::Hall;

# Golden fixtures for the legacy .raider.yml (t/fixtures/raider-yml/). Every
# reader of the file must agree on what it means: engine options, packs,
# perl, skills and the engine choice. Asserted through the public surfaces
# (Langertha::Raider::CLI, bin/raider, the Hall's spawn command), so the
# fixtures pin behaviour, not the resolver's internals. No live API calls.

my $repo     = path(__FILE__)->absolute->parent->parent;
my $bin      = $repo->child('bin', 'raider');
my $fixtures = $repo->child('t', 'fixtures', 'raider-yml');

delete $ENV{RAIDER_HALL_SOCKET};
clear_engine_env();

# A fresh root holding the named fixture as .raider.yml plus extra files.
sub fixture_root {
  my ( $fixture, %files ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  $fixtures->child($fixture)->copy($root->child('.raider.yml')) if defined $fixture;
  for my $rel (sort keys %files) {
    my $f = $root->child($rel);
    $f->parent->mkpath;
    $f->spew_utf8($files{$rel});
  }
  return $root;
}

sub app {
  my ( $root, %args ) = @_;
  return Langertha::Raider::CLI->new(
    root    => "$root",
    engine  => 'openai',
    api_key => 'test',
    model   => 'gpt-4o-mini',
    trace   => 0,
    %args,
  );
}

sub perl_tools_on { scalar(@{ $_[0]->_mcps }) == 4 }   # files, bash, web + perl

sub run_raider {
  my ( @args ) = @_;
  my @cmd = ($^X, '-I'.$repo->child('lib'), "$bin", @args);
  my $out = `@{[ join ' ', map { "'$_'" } @cmd ]} 2>&1 </dev/null`;
  return ($? >> 8, $out);
}

subtest 'flat file' => sub {
  my $app = app(fixture_root('flat.yml'));
  is($app->_engine_yml_options, { temperature => 0.2 }, 'engine options');
  is($app->packs->active_pack_names, ['git-guru'], 'packs from yml');
  ok(perl_tools_on($app), 'perl: true enables PerlTools');
};

subtest 'flat file after /model keeps its flat keys' => sub {
  my $app = app(fixture_root('flat-after-model.yml'));
  is($app->_engine_yml_options, { temperature => 0.2, model => 'gpt-4o' },
    'flat temperature and saved model both reach the engine');
  is($app->packs->active_pack_names, ['git-guru'], 'packs survive');
  ok(perl_tools_on($app), 'perl survives');
};

subtest 'sectioned file: default then engine section' => sub {
  my $root = fixture_root('sectioned.yml');
  is(app($root)->_engine_yml_options, { temperature => 0.7, response_size => 1024 },
    'openai section over default');
  is(app($root, engine => 'anthropic')->_engine_yml_options,
    { temperature => 0.3, response_size => 8192 }, 'anthropic section over default');
  is(app($root, engine => 'groq')->_engine_yml_options,
    { temperature => 0.3, response_size => 1024 }, 'no section: default only');
  is(app($root)->packs->active_pack_names, ['caveman'], 'pack defaults untouched');
};

subtest 'skills as a hash does not disable flat keys' => sub {
  my $root = fixture_root('skills-hash.yml', 'myskills/style.md' => "# Style\n");
  my $app = app($root);
  is([ $app->loaded_skill_names ], ['style.md'], 'hash skill spec loaded');
  ok(perl_tools_on($app), 'perl: true still applies');
  is($app->_engine_yml_options, { temperature => 0.3 }, 'temperature still applies');
};

subtest 'skills under default: are loaded' => sub {
  my $root = fixture_root('skills-default.yml', 'AGENTS.md' => "# Agents\n");
  my $app = app($root);
  is([ $app->loaded_skill_names ], ['AGENTS.md'], 'default: skills loaded');
  is([ $app->ignored_agent_files ], [], 'AGENTS.md not reported as ignored');
  is($app->_engine_yml_options, { temperature => 0.4 }, 'skills is no engine option');
};

subtest 'CLI skills merge with yml skills' => sub {
  my $root = fixture_root('skills-list.yml',
    'AGENTS.md' => "# Agents\n", 'extra/tips.md' => "# Tips\n");
  my $app = app($root, cli_skill_sources => [ { type => 'dir', path => 'extra' } ]);
  is([ $app->loaded_skill_names ], ['AGENTS.md', 'tips.md'], 'yml and CLI skills both loaded');

  my $dup = app($root, cli_skill_sources => [ { type => 'file', path => 'AGENTS.md' } ]);
  is([ $dup->loaded_skill_names ], ['AGENTS.md'], 'same source given twice loads once');

  my $explicit = app($root, skill_sources => [ { type => 'dir', path => 'extra' } ]);
  is([ $explicit->loaded_skill_names ], ['tips.md'],
    'explicit skill_sources (Perl API) still replace the yml list');
};

subtest 'bin/raider persists --skills like --claude' => sub {
  my $root = fixture_root('skills-list.yml', 'extra/tips.md' => "# Tips\n");
  my $out = $root->child('SKILL.md');
  my ( $exit, $log ) = run_raider('-k', 'test', '-e', 'openai', '-r', "$root",
    '--claude', '--skills', 'extra', "--export-skill=$out");
  is($exit, 0, 'raider exits cleanly') or diag $log;
  my $yml = YAML::PP->new->load_string($root->child('.raider.yml')->slurp_utf8);
  is($yml->{skills}, ['openai', 'claude', 'extra'], 'profile and dir appended once');

  ( $exit, $log ) = run_raider('-k', 'test', '-e', 'openai', '-r', "$root",
    '--claude', '--skills', 'extra', "--export-skill=$out");
  is($exit, 0, 'second run exits cleanly') or diag $log;
  $yml = YAML::PP->new->load_string($root->child('.raider.yml')->slurp_utf8);
  is($yml->{skills}, ['openai', 'claude', 'extra'], 'no duplicates on repeat');
};

subtest 'engine: in yml picks the engine' => sub {
  local $ENV{ANTHROPIC_API_KEY} = 'from-env';
  my $root = fixture_root('engine.yml');
  my $app = Langertha::Raider::CLI->new(root => "$root", trace => 0);
  is($app->engine_name, 'openai', 'yml engine beats key autodetection');
  is($app->_engine_yml_options, { temperature => 0.1 }, 'engine is no constructor option');
  is(Langertha::Raider::CLI->new(root => "$root", engine => 'groq')->engine_name, 'groq',
    'explicit engine beats yml');
  is(Langertha::Raider::CLI->new(root => "$root", trace => 0)->engine_name, 'openai',
    'stable across instances');
  my $none = fixture_root(undef);
  is(Langertha::Raider::CLI->new(root => "$none")->engine_name, 'anthropic',
    'no yml: autodetection unchanged');
};

subtest 'broken YAML fails loudly' => sub {
  my $root = fixture_root('broken.yml');
  like(dies { app($root)->packs }, qr/\.raider\.yml/, 'CLI reports the unparsable file');

  my $out = $root->child('SKILL.md');
  my ( $exit, $log ) = run_raider('-k', 'test', '-e', 'openai', '-r', "$root",
    "--export-skill=$out");
  isnt($exit, 0, 'raider exits non-zero');
  like($log, qr/\.raider\.yml/, 'error names the file');
  ok(!-f $out, 'nothing ran on a broken config');

  ( $exit, $log ) = run_raider('-k', 'test', '-e', 'openai', '-r', "$root",
    '--claude', "--export-skill=$out");
  isnt($exit, 0, 'persisting --claude refuses too');
  is($root->child('.raider.yml')->slurp_utf8, $fixtures->child('broken.yml')->slurp_utf8,
    'broken file is not overwritten');
};

subtest 'Hall without engine leaves the choice to raider' => sub {
  my $tmp = path(tempdir(CLEANUP => 1));
  $tmp->child('.raider-hall.yml')->spew_utf8(YAML::PP->new->dump_string({
    raiders => {
      Bjorn => { model => 'some-model' },
      Ivar  => { engine => 'openai' },
    },
  }));
  my $hall = Langertha::Raider::Hall->new(root => $tmp);
  local $ENV{RAIDER_HALL_RAIDER_BIN} = "$bin";

  my @cmds;
  no warnings qw( once redefine );
  local *IO::Async::Process::new = sub {
    my ( $class, %args ) = @_;
    push @cmds, $args{command};
    die "captured\n";
  };
  eval { $hall->_spawn_raider('Bjorn', 'Bjorn', 'mission') };
  eval { $hall->_spawn_raider('Ivar',  'Ivar',  'mission') };

  is(scalar @cmds, 2, 'both spawns reached the process');
  ok(!(grep { $_ eq '--engine' } @{ $cmds[0] }), 'no --engine when none configured');
  like(join(' ', @{ $cmds[0] }), qr/--model some-model/, 'model still passed');
  like(join(' ', @{ $cmds[1] }), qr/--engine openai/, 'configured engine passed');
};

done_testing;
