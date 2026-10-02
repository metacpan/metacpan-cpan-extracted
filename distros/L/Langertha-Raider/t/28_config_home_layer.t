#!/usr/bin/env perl
# ABSTRACT: ~/.raider/config.yml as the layer under the project config (ADR 0011, k128)

use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::Config;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;

clear_engine_env();

# A Config without any home (no $HOME, no password entry).
{
  package Test::NoHome;
  use parent -norequire, 'Langertha::Raider::Home';
  sub home_base { return }

  package Test::Config::NoHome;
  use Moose;
  extends 'Langertha::Raider::Config';
  sub home_class { 'Test::NoHome' }
  __PACKAGE__->meta->make_immutable;
}

# default < home < project < command line. Per key: scalars and packs are
# replaced by the project, skills and no_detect add up, detect: is merged
# per pack when both files hold a map. The writers only write the project
# file. Run in the home itself, the one file is the project file.

sub yaml { ref $_[0] ? YAML::PP->new->dump_string($_[0]) : $_[0] }

# A fresh home with ~/.raider/config.yml (unless undef); HOME points at it.
sub home {
  my ( $content ) = @_;
  my $home = path(tempdir(CLEANUP => 1));
  if (defined $content) {
    $home->child('.raider')->mkpath;
    $home->child('.raider', 'config.yml')->spew_utf8(yaml($content));
  }
  $ENV{HOME} = "$home";
  return $home;
}

sub project {
  my ( %files ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  if (defined $files{new}) {
    $root->child('.raider')->mkpath;
    $root->child('.raider', 'config.yml')->spew_utf8(yaml($files{new}));
  }
  $root->child('.raider.yml')->spew_utf8(yaml($files{legacy})) if defined $files{legacy};
  $root->child($_)->spew_utf8("x\n") for @{ $files{touch} // [] };
  return $root;
}

sub config { Langertha::Raider::Config->new(root => "$_[0]") }

sub app { Langertha::Raider::CLI->new(root => "$_[0]", engine => 'openai', api_key => 'test', @_[1 .. $#_]) }

sub load { YAML::PP->new->load_string(path(@_)->slurp_utf8) }

sub entry {
  my ( $report, $key ) = @_;
  my ( $hit ) = grep { $_->{key} eq $key } @{ $report->{values} };
  return $hit;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; decode_utf8($buf) } );
}

sub run_cli {
  my ( @args ) = @_;
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  local $ENV{ANSI_COLORS_DISABLED};
  my $exit = Langertha::Raider::CLI::Main->new(
    output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
    err    => $err,
  )->run(@args);
  return ( $exit, $read_out->(), $read_err->() );
}

subtest 'no home file: no home layer' => sub {
  my $home = home();
  my $root = project(new => { model => 'p' });
  my $config = config($root);
  is($config->home_file->stringify, $home->child('.raider', 'config.yml')->stringify, 'home_file');
  ok(!$config->uses_home, 'not used');
  is($config->home_data, {}, 'no home data');
  my $report = $config->explain('openai');
  ok(!exists $report->{home_file}, 'explain has no home_file');
  ok(!exists entry($report, 'model')->{merged_with}, 'no merged_with');

  my ( $exit, $out ) = run_cli('-r', "$root", '-e', 'openai', '-k', 'test', '--no-trace', 'config', 'explain');
  is($exit, 0, 'exit 0');
  unlike($out, qr/^home:/m, 'no home line');

  my $none = Test::Config::NoHome->new(root => "$root");
  is($none->home_file, undef, 'no home at all: home_file undef');
  ok(!$none->uses_home, 'and not used');
  is($none->options('openai'), { model => 'p' }, 'project alone');
};

subtest 'scalars: the project replaces the home' => sub {
  my $home = home({ model => 'home-m', temperature => 0.9, seed => 3, openai => { response_size => 99 } });
  my $root = project(new => { model => 'proj-m', default => { seed => 4 } });
  my $config = config($root);
  ok($config->uses_home, 'home used');
  is($config->engine_options('openai'),
    { model => 'proj-m', temperature => 0.9, seed => 4, response_size => 99 }, 'effective options');

  my $report = $config->explain('openai');
  is($report->{home_file}, $home->child('.raider', 'config.yml')->stringify, 'home_file in explain');
  like(entry($report, 'model'), { source => 'top', shadowed => ['home top'] }, 'project over home');
  like(entry($report, 'seed'), { source => 'default', shadowed => ['home top'] }, 'project default: over home top');
  like(entry($report, 'temperature'), { source => 'home top', shadowed => [] }, 'home alone');
  like(entry($report, 'response_size'), { source => 'home openai' }, 'home engine section');
  is($config->layer_label('home openai'), 'home openai:', 'layer_label home section');
  is($config->layer_label('home top'), 'home', 'layer_label home top');
  is($config->layer_label('default'), '.raider/config.yml default:', 'layer_label project');

  # a project top-level key beats a home engine section
  home({ openai => { temperature => 0.9 } });
  my $over = config(project(new => { temperature => 0.1 }));
  is($over->engine_options('openai'), { temperature => 0.1 }, 'project top over home openai:');
  like(entry($over->explain('openai'), 'temperature'), { source => 'top', shadowed => ['home openai'] },
    'shadowed names the home section');

  # sections of an inactive engine are reported per file
  home({ anthropic => { model => 'x' } });
  is(config(project())->explain('openai')->{ignored},
    [ { key => 'home anthropic', reason => 'section of an inactive engine' } ], 'inactive home section');

  # the legacy project file sits over the home the same way
  home({ model => 'home-m', seed => 1 });
  my $legacy = config(project(legacy => { model => 'old-m' }));
  is($legacy->engine_options('openai'), { model => 'old-m', seed => 1 }, 'legacy .raider.yml over home');
  is($legacy->layer_label('top'), '.raider.yml', 'label unchanged');
};

subtest 'engine and api_key from home' => sub {
  home({ engine => 'groq', api_key => 'home-secret', model => 'home-m' });
  my $root = project();
  my $app = Langertha::Raider::CLI->new(root => "$root");
  is($app->engine_name, 'groq', 'engine: from home');
  is($app->api_key, 'home-secret', 'api_key: from home');
  my $report = $app->explain_config;
  like(entry($report, 'engine'), { value => 'groq', source => 'home' }, 'engine source');
  like(entry($report, 'api_key'), { value => '(set)', source => 'home' }, 'api_key source, no value');
  like(entry($report, 'model'), { value => 'home-m', source => 'home' }, 'model source');

  my $proj = project(new => { engine => 'openai', api_key => 'proj-secret' });
  my $papp = Langertha::Raider::CLI->new(root => "$proj");
  is($papp->engine_name, 'openai', 'project engine: over home');
  is($papp->api_key, 'proj-secret', 'project api_key over home');
  like(entry($papp->explain_config, 'api_key'), { source => '.raider/config.yml', shadowed => ['home'] },
    'api_key shadows home');
};

subtest 'command line over project over home' => sub {
  home({ model => 'home-m', temperature => 0.9 });
  my $root = project(new => { default => { model => 'proj-m' } });
  my $app = app($root, model => 'cli-m', engine_options => { temperature => 0.2 });
  my $report = $app->explain_config;
  like(entry($report, 'model'), { value => 'cli-m', source => '-m',
    shadowed => [ '.raider/config.yml default:', 'home' ] }, '-m over project over home');
  like(entry($report, 'temperature'), { value => 0.2, source => '-o', shadowed => ['home'] }, '-o over home');
  is($app->model, 'cli-m', 'model');

  my ( $exit, $out ) = run_cli('-r', "$root", '-e', 'openai', '-k', 'test', '--no-trace', 'config', 'explain');
  is($exit, 0, 'exit 0');
  like($out, qr/^home:   \S+\/\.raider\/config\.yml$/m, 'home line with the path');
  like($out, qr/^  model\s+proj-m  \(from \.raider\/config\.yml default:, overrides home; engine\)$/m,
    'model line');
  like($out, qr/^  temperature\s+0\.9  \(from home; engine\)$/m, 'home value line');
};

subtest 'skills: union, home first' => sub {
  home({ skills => [ 'claude', 'home-skills' ] });
  my $root = project(new => { skills => [ 'notes', 'claude' ] });
  my $config = config($root);
  is([ $config->skill_specs('openai') ], [
    { type => 'file',   path => 'CLAUDE.md' },
    { type => 'claude', path => '.claude/skills' },
    { type => 'dir',    path => 'home-skills' },
    { type => 'dir',    path => 'notes' },
  ], 'both lists, deduplicated');
  is([ $config->profiles('openai') ], ['claude'], 'profiles');
  my @skills = grep { $_->{key} eq 'skills' } @{ app($root)->explain_config->{values} };
  is([ map { $_->{source} } @skills ], [ 'home', '.raider/config.yml' ], 'one entry per file');
};

subtest 'packs: the project replaces the home' => sub {
  home({ packs => ['caveman'] });
  my $root = project(new => { packs => ['polite'] });
  is(config($root)->options('openai')->{packs}, ['polite'], 'project list');
  my $app = app($root);
  ok($app->packs->is_active('polite'), 'polite on');
  ok(!$app->packs->is_active('caveman'), 'home caveman not on');
  my ( $polite ) = grep { $_->{name} eq 'polite' } @{ $app->explain_config->{packs} };
  like($polite, { source => 'config', reason => '.raider/config.yml packs:' }, 'project label');
  like(entry($app->explain_config, 'packs'), { source => '.raider/config.yml', shadowed => ['home'] },
    'packs shadows home');

  my $only = app(project());
  ok($only->packs->is_active('caveman'), 'home packs apply without a project list');
  my ( $caveman ) = grep { $_->{name} eq 'caveman' } @{ $only->explain_config->{packs} };
  like($caveman, { source => 'config', reason => 'home packs:' }, 'home label');
};

subtest 'perl: from home' => sub {
  home({ perl => 1 });
  is(app(project())->perl_tools_grant, { enabled => 1, reason => 'perl: true (home)' }, 'home grant');
  is(app(project(new => { perl => 0 }))->perl_tools_grant,
    { enabled => 0, reason => 'perl: false (.raider/config.yml)' }, 'project denial over home');
};

subtest 'no_detect: union' => sub {
  home({ no_detect => 'perl, rust' });
  my $root = project(new => { no_detect => [ 'go', 'rust' ] }, touch => ['cpanfile']);
  my $config = config($root);
  is($config->options('openai')->{no_detect}, [ 'perl', 'rust', 'go' ], 'union, home first');
  is($config->detect_settings('openai')->{off}, { perl => 'no_detect', rust => 'no_detect', go => 'no_detect' },
    'all switched off');
  like(entry($config->explain('openai'), 'no_detect'), { source => 'top', merged_with => ['home top'], shadowed => [] },
    'merged_with in Config explain');

  my $app = app($root);
  like($app->packs->detections->{perl}, { result => 'skipped', reason => 'no_detect' }, 'home no_detect applies');
  like(entry($app->explain_config, 'no_detect'), { value => [ 'perl', 'rust', 'go' ],
    source => '.raider/config.yml', merged_with => ['home'] }, 'merged_with in explain_config');
  like(entry(app($root, engine_options => { no_detect => 'x' })->explain_config, 'no_detect'),
    { value => 'x', source => '-o', shadowed => [ '.raider/config.yml', 'home' ] }, '-o replaces the union');

  my ( undef, $out ) = run_cli('-r', "$root", '-e', 'openai', '-k', 'test', '--no-trace', 'config', 'explain');
  like($out, qr/^  no_detect\s+\["perl","rust","go"\]  \(from \.raider\/config\.yml, merged with home; raider\)$/m,
    'config explain line');

  home({ no_detect => ['perl'] });
  is(config(project())->options('openai')->{no_detect}, ['perl'], 'home alone unchanged');
  home({ no_detect => [ ['perl'] ] });
  like(dies { config(project(new => { no_detect => ['go'] }))->detect_settings('openai') },
    qr/no_detect: must be a list of pack names/, 'invalid home value still croaks');
};

subtest 'detect: per pack' => sub {
  my $never = { must => [ { file => 'NEVER-THERE' } ] };
  home({ detect => { perl => $never, go => { must => [ { file => 'go.mod' } ] } } });
  my $root = project(new => { detect => { perl => { must => [ { file => 'cpanfile' } ] } } }, touch => ['cpanfile']);
  my $config = config($root);
  is($config->options('openai')->{detect}, {
    perl => { must => [ { file => 'cpanfile' } ] },
    go   => { must => [ { file => 'go.mod' } ] },
  }, 'project rule replaces the home rule for perl, home go stays');
  is($config->detect_rule_label('openai', 'perl'), '.raider/config.yml detect:', 'perl rule from project');
  is($config->detect_rule_label('openai', 'go'), 'home detect:', 'go rule from home');

  my $app = app($root);
  like($app->packs->detections->{perl}, { rule_from => '.raider/config.yml detect:', result => 'matched' },
    'perl detected by the project rule');
  like($app->packs->detections->{go}, { rule_from => 'home detect:', result => 'skipped', reason => 'unknown pack' },
    'home rule listed with its source');
  like(entry($app->explain_config, 'detect'), { source => '.raider/config.yml', merged_with => ['home'] },
    'detect merged_with');

  # a project pack: false turns off a home rule for that pack only
  my $off = config(project(new => { detect => { go => 0 } }));
  is($off->detect_settings('openai'), { enabled => 1, rules => { perl => $never }, off => { go => 'detect: go: false' } },
    'per pack false');

  # not both maps: the project value replaces the home one
  my $all_off = app(project(new => { detect => 0 }, touch => ['cpanfile']));
  is([ $all_off->detection_state ], [ 0, 'detect: false' ], 'project detect: false over a home map');
  like(entry($all_off->explain_config, 'detect'), { value => 0, shadowed => ['home'] }, 'replaced, not merged');
  ok(!exists entry($all_off->explain_config, 'detect')->{merged_with}, 'no merged_with');

  home({ detect => 0 });
  my $on = app(project(new => { detect => { perl => { must => [ { file => 'cpanfile' } ] } } }, touch => ['cpanfile']));
  is([ $on->detection_state ], [ 1, 'default' ], 'a project map over home detect: false switches detection on');
  is(( app(project(touch => ['cpanfile']))->detection_state )[0], 0, 'home detect: false alone');

  home({ detect => { perl => { must => [ { file => 'cpanfile' } ] } } });
  my $home_only = app(project(touch => ['cpanfile']));
  like($home_only->packs->detections->{perl}, { rule_from => 'home detect:', result => 'matched' },
    'home rule alone');
};

subtest 'home is the project root: one file, read once' => sub {
  my $home = home({ model => 'm', skills => ['claude'], no_detect => ['perl'] });
  my $config = config($home);
  ok(!$config->uses_home, 'no home layer');
  is($config->label, '.raider/config.yml', 'the file is the project file');
  is($config->home_data, {}, 'home data empty');
  is($config->options('openai')->{no_detect}, ['perl'], 'no_detect not doubled');
  my $report = $config->explain('openai');
  ok(!exists $report->{home_file}, 'no home_file');
  like(entry($report, 'model'), { source => 'top', shadowed => [] }, 'model not shadowing itself');
  is([ grep { $_->{key} eq 'skills' } @{ $report->{values} } ], [ D() ], 'one skills entry');

  my ( $exit, $out ) = run_cli('-r', "$home", '-e', 'openai', '-k', 'test', '--no-trace', 'config', 'explain');
  is($exit, 0, 'exit 0');
  unlike($out, qr/^home:/m, 'no home line');

  # the same directory reached through a symlink
  my $link = path(tempdir(CLEANUP => 1))->child('home-link');
  symlink("$home", "$link") or skip_all('no symlinks');
  $ENV{HOME} = "$link";
  ok(!config($home)->uses_home, 'HOME through a symlink: still one file');
  $ENV{HOME} = "$home";
  ok(!config($link)->uses_home, 'root through a symlink: still one file');

  # writers write it as the project file
  config($home)->set_model('new-m');
  is(load($home, '.raider', 'config.yml')->{default}{model}, 'new-m', 'written');
  ok(!-e $home->child('.raider.yml'), 'no .raider.yml created');
};

subtest 'writers never write the home file' => sub {
  my $home = home({ model => 'home-m', skills => ['claude'] });
  my $before = $home->child('.raider', 'config.yml')->slurp_utf8;

  my $root = project(new => { temperature => 0.1 });
  my $config = config($root);
  $config->set_model('gpt-4o');
  is([ $config->add_skills('notes') ], ['notes'], 'add_skills');
  like(load($root, '.raider', 'config.yml'), { temperature => 0.1, default => { model => 'gpt-4o' }, skills => ['notes'] },
    'project file written');
  is($home->child('.raider', 'config.yml')->slurp_utf8, $before, 'home file untouched');
  is($config->engine_options('openai')->{model}, 'gpt-4o', 're-read: project model over home');

  my $none = project();
  config($none)->set_model('gpt-4o');
  is(load($none, '.raider.yml'), { default => { model => 'gpt-4o' } }, 'no project file: .raider.yml created');
  is($home->child('.raider', 'config.yml')->slurp_utf8, $before, 'home file untouched');

  my ( $exit ) = run_cli('-r', "$none", '-e', 'openai', '-k', 'test', '--no-trace', '--claude',
    '--export-skill', "$none/S.md");
  is($exit, 0, 'exit 0');
  is(load($none, '.raider.yml')->{skills}, ['claude'], '--claude persisted into the project file');
  is($home->child('.raider', 'config.yml')->slurp_utf8, $before, 'home file untouched');
};

subtest 'a broken home file fails loud' => sub {
  my $home = home("a: [\n");
  my $root = project(new => { model => 'm' });
  my $file = $home->child('.raider', 'config.yml');
  like(dies { config($root)->options('openai') }, qr/^Cannot parse \Q$file\E: /, 'readers croak with the path');
  ok(lives { config($root)->set_model('x') }, 'the project writer does not read the home file');

  my ( $exit, $out, $err ) = run_cli('-r', "$root", '-e', 'openai', '-k', 'test', '--no-trace', 'config', 'explain');
  is($exit, 3, 'exit 3');
  like($err, qr/^Cannot parse \Q$file\E: \S/m, 'message names the home file');

  home({ packs => { a => 1 } });
  like(dies { config($root)->options('openai') }, qr/Cannot use \S+\/\.raider\/config\.yml: packs: configures raider/,
    'raider key as a mapping in home croaks');

  home("- a\n- b\n");
  like(dies { config($root)->options('openai') }, qr/the top level must be a mapping/, 'top level not a mapping');

  home('');
  my $fresh = project(new => { model => 'm' });
  ok(config($fresh)->uses_home, 'an empty home file is used');
  is(config($fresh)->options('openai'), { model => 'm' }, 'and adds nothing');
};

done_testing;
