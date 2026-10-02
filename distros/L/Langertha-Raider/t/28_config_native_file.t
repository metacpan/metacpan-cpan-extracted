#!/usr/bin/env perl
# ABSTRACT: <root>/.raider/config.yml next to the legacy .raider.yml (ADR 0011, k126)

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
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;

clear_engine_env();

# The file in use is .raider/config.yml when it exists, else .raider.yml.
# Both present: the new one is loaded, the legacy one not even read, and
# the conflict is reported. Writers write the file in use and never create
# .raider/config.yml.

my $NEW    = { model => 'new-model', temperature => 0.1, packs => ['caveman'] };
my $LEGACY = { model => 'old-model', seed => 7 };

sub project {
  my ( %files ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  if (defined $files{new}) {
    $root->child('.raider')->mkpath;
    $root->child('.raider', 'config.yml')->spew_utf8(
      ref $files{new} ? YAML::PP->new->dump_string($files{new}) : $files{new});
  }
  $root->child('.raider.yml')->spew_utf8(
    ref $files{legacy} ? YAML::PP->new->dump_string($files{legacy}) : $files{legacy})
    if defined $files{legacy};
  return $root;
}

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

subtest 'only .raider/config.yml' => sub {
  my $root = project(new => $NEW);
  my $config = Langertha::Raider::Config->new(root => "$root");
  is($config->file->stringify, $root->child('.raider', 'config.yml')->stringify, 'file in use');
  ok($config->is_native, 'native');
  is($config->label, '.raider/config.yml', 'label');
  is([ $config->ignored_files ], [], 'nothing ignored');
  is($config->engine_options('openai'), { model => 'new-model', temperature => 0.1 }, 'same keys as .raider.yml');
  is($config->options('openai')->{packs}, ['caveman'], 'raider keys too');

  my $report = Langertha::Raider::CLI->new(root => "$root", engine => 'openai', api_key => 'test')->explain_config;
  like($report, { file => $config->file->stringify, exists => 1, label => '.raider/config.yml',
    ignored_files => [] }, 'explain names the file');
  like(entry($report, 'model'), { value => 'new-model', source => '.raider/config.yml' }, 'value source');
  like(entry($report, 'packs'), { source => '.raider/config.yml' }, 'raider key source');
  my ( $pack ) = grep { $_->{name} eq 'caveman' } @{ $report->{packs} };
  like($pack, { active => 1, source => 'config', reason => '.raider/config.yml packs:' }, 'pack source label');
};

subtest 'only .raider.yml: unchanged' => sub {
  my $root = project(legacy => $LEGACY);
  my $config = Langertha::Raider::Config->new(root => "$root");
  is($config->file->stringify, $root->child('.raider.yml')->stringify, 'file in use');
  ok(!$config->is_native, 'not native');
  is($config->label, '.raider.yml', 'label');
  is([ $config->ignored_files ], [], 'nothing ignored');
  my $report = Langertha::Raider::CLI->new(root => "$root", engine => 'openai', api_key => 'test')->explain_config;
  like($report, { label => '.raider.yml', ignored_files => [] }, 'explain');
  like(entry($report, 'model'), { value => 'old-model', source => '.raider.yml' }, 'value source');
};

subtest 'a .raider/ directory without config.yml keeps .raider.yml' => sub {
  my $root = project(legacy => $LEGACY);
  $root->child('.raider', 'lib')->mkpath;
  my $config = Langertha::Raider::Config->new(root => "$root");
  is($config->label, '.raider.yml', 'legacy in use');
  is($config->engine_options('openai')->{seed}, 7, 'legacy read');
};

subtest 'both: the new file wins, the legacy file is reported' => sub {
  my $root = project(new => $NEW, legacy => $LEGACY);
  my $config = Langertha::Raider::Config->new(root => "$root");
  is($config->label, '.raider/config.yml', 'new file in use');
  is($config->engine_options('openai'), { model => 'new-model', temperature => 0.1 },
    'legacy values not merged in');
  is([ $config->ignored_files ], [ {
    file   => $root->child('.raider.yml')->absolute->stringify,
    reason => 'both .raider.yml and .raider/config.yml exist; only .raider/config.yml is loaded',
  } ], 'legacy file reported');
  is(Langertha::Raider::Config->new(root => "$root")->explain('openai')->{ignored_files},
    [ $config->ignored_files ], 'in explain');

  my $broken = project(new => $NEW, legacy => "a: [\n");
  ok(lives { Langertha::Raider::Config->new(root => "$broken")->data }, 'an ignored legacy file is not parsed');

  my $app = Langertha::Raider::CLI->new(root => "$root", engine => 'openai', api_key => 'test');
  my $report = $app->explain_config;
  like($report->{ignored_files}, [ { file => qr/\.raider\.yml\z/ } ], 'explain_config reports it');
  ok(!entry($report, 'seed'), 'no legacy key in explain');

  my ( $fh, $read ) = buffer();
  Langertha::Raider::CLI::Output->new(out => $fh, color => 0)->config_report($report);
  like($read->(), qr{\Afile:   \S+/\.raider/config\.yml\n  ignored file \S+/\.raider\.yml: both \.raider\.yml and \.raider/config\.yml exist; only \.raider/config\.yml is loaded\n},
    'config explain shows the file in use and the conflict');
};

subtest 'CLI: warning on stderr, config explain' => sub {
  my $root = project(new => $NEW, legacy => $LEGACY);
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  local $ENV{ANSI_COLORS_DISABLED};
  my $exit = Langertha::Raider::CLI::Main->new(
    output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
    err    => $err,
  )->run('-r', "$root", '-e', 'openai', '-k', 'test', '--no-trace', 'config', 'explain');
  is($exit, 0, 'exit 0');
  like($read_err->(), qr{^warning: ignoring \S+/\.raider\.yml: both \.raider\.yml and \.raider/config\.yml exist; only \.raider/config\.yml is loaded$}m,
    'warned on stderr');
  like($read_out->(), qr{^file:   \S+/\.raider/config\.yml\n  ignored file }m, 'report');

  my $legacy = project(legacy => $LEGACY);
  ( $out, $read_out ) = buffer();
  ( $err, $read_err ) = buffer();
  Langertha::Raider::CLI::Main->new(
    output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
    err    => $err,
  )->run('-r', "$legacy", '-e', 'openai', '-k', 'test', '--no-trace', 'config', 'explain');
  is($read_err->(), '', 'no warning with one file');
};

subtest 'writers write the file in use' => sub {
  my $root = project(new => $NEW);
  Langertha::Raider::Config->new(root => "$root")->set_model('gpt-4o');
  is(load($root, '.raider', 'config.yml')->{default}{model}, 'gpt-4o', 'set_model into .raider/config.yml');
  ok(!-e $root->child('.raider.yml'), 'no .raider.yml created');

  $root = project(new => $NEW, legacy => $LEGACY);
  my $config = Langertha::Raider::Config->new(root => "$root");
  is([ $config->add_skills('claude') ], ['claude'], 'add_skills');
  is(load($root, '.raider', 'config.yml')->{skills}, ['claude'], 'into the new file');
  is(load($root, '.raider.yml'), $LEGACY, 'ignored legacy file untouched');

  $root = project(legacy => $LEGACY);
  Langertha::Raider::Config->new(root => "$root")->set_model('gpt-4o');
  is(load($root, '.raider.yml')->{default}{model}, 'gpt-4o', 'legacy only: into .raider.yml');
  ok(!-e $root->child('.raider'), 'no .raider/ created');

  $root = project();
  Langertha::Raider::Config->new(root => "$root")->add_skills('claude');
  is(load($root, '.raider.yml')->{skills}, ['claude'], 'no file: .raider.yml is created');
  ok(!-e $root->child('.raider', 'config.yml'), 'never .raider/config.yml');

  # /model in the REPL
  $root = project(new => $NEW, legacy => $LEGACY);
  my $app = Langertha::Raider::CLI->new(root => "$root", engine => 'openai', api_key => 'test', trace => 0);
  my ( $fh, $read ) = buffer();
  Langertha::Raider::CLI::Commands->new(app => $app,
    output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0))->cmd_model('gpt-4o');
  like($read->(), qr/^model saved: gpt-4o/, '/model saved');
  is(load($root, '.raider', 'config.yml')->{default}{model}, 'gpt-4o', '/model into .raider/config.yml');
  is(load($root, '.raider.yml'), $LEGACY, 'legacy file untouched');

  # --claude persisted at startup
  $root = project(new => $NEW);
  my ( $out ) = buffer();
  my ( $err ) = buffer();
  Langertha::Raider::CLI::Main->new(
    output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
    err    => $err,
  )->run('-r', "$root", '-e', 'openai', '-k', 'test', '--no-trace', '--claude', '--export-skill', "$root/S.md");
  is(load($root, '.raider', 'config.yml')->{skills}, ['claude'], '--claude into .raider/config.yml');
  ok(!-e $root->child('.raider.yml'), 'no .raider.yml created');
};

done_testing;
