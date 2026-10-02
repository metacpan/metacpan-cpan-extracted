#!/usr/bin/env perl
# ABSTRACT: raider config migrate: .raider.yml / .raider.md to .raider/ (ADR 0011, k130)

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
my $HOME = isolate_home();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::Config;
use Langertha::Raider::Config::Migrate;

clear_engine_env();
delete $ENV{ANSI_COLORS_DISABLED};

# The legacy files move into .raider/: the new file atomically, the legacy
# one renamed to its .bak. Afterwards the same effective config is read
# (F01), minus api_key, which a project must not carry (handoff 5.2).

my $YML = <<'YML';
# project settings
temperature: 0.3
skills: [claude]
packs: [caveman]
default:
  model: yml-model
openai:
  seed: 4 # per engine
anthropic:
  model: other
YML

my $YML_KEYS = <<'YML';
# project settings
temperature: 0.3
api_key: sk-top-secret
default:
  model: yml-model
  api_key: sk-default-secret
openai:
  seed: 4 # per engine
  api_key: sk-openai-secret
YML

my $MD = "You are Bob, a careful reviewer.\n\nBe brief.\n";

sub project {
  my ( %files ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  $root->child('.raider.yml')->spew_utf8($files{yml}) if defined $files{yml};
  $root->child('.raider.md')->spew_utf8($files{md}) if defined $files{md};
  return $root;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; decode_utf8($buf) } );
}

sub main_run {
  my ( @argv ) = @_;
  my $class = ref $argv[0] eq 'SCALAR' ? ${ shift @argv } : 'Langertha::Raider::CLI::Main';
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  local $ENV{ANSI_COLORS_DISABLED};
  my $exit = $class->new(
    output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
    err    => $err,
  )->run(@argv);
  return ( $exit, $read_out->(), $read_err->() );
}

# Every file below $root with its content (directories as such).
sub snapshot {
  my ( $root ) = @_;
  my %tree;
  $root->visit(sub {
    my ( $p ) = @_;
    $tree{ $p->relative($root)->stringify } = -d $p ? '(dir)' : $p->slurp_raw;
  }, { recurse => 1 });
  return \%tree;
}

# What explain says, with the new file names mapped to the legacy ones and
# without api_key: equal before and after a migration.
sub normalize {
  my ( $data ) = @_;
  return [ map { normalize($_) } @$data ] if ref $data eq 'ARRAY';
  return { map { $_ => normalize($data->{$_}) } keys %$data } if ref $data eq 'HASH';
  return $data if ref $data || !defined $data;
  ( my $s = $data ) =~ s{\.raider/config\.yml}{.raider.yml}g;
  $s =~ s{\.raider/instructions\.md}{.raider.md}g;
  return $s;
}

sub effective {
  my ( $root ) = @_;
  my $config = Langertha::Raider::Config->new(root => "$root");
  my $app = Langertha::Raider::CLI->new(root => "$root", engine => 'openai', api_key => 'test');
  my $report = $app->explain_config;
  delete @$report{qw( file label exists )};
  $report->{values} = [ grep { $_->{key} ne 'api_key' } @{ $report->{values} } ];
  return normalize({
    config  => [ grep { $_->{key} ne 'api_key' } @{ $config->explain('openai')->{values} } ],
    options => { %{ $config->engine_options('openai') }, api_key => undef },
    report  => $report,
    mission => $app->mission,
  });
}

subtest 'nothing to migrate' => sub {
  my $root = project();
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$root");
  is($exit, 0, 'exit 0');
  like($out, qr/\Anothing to migrate: no \.raider\.yml or \.raider\.md in \Q$root\E\n\z/, 'said so');
  is($err, '', 'no diagnostics');
  ok(!-e $root->child('.raider'), 'no .raider/ created');
};

subtest 'dry run writes nothing' => sub {
  my $root = project(yml => $YML_KEYS, md => $MD);
  my $before = snapshot($root);
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '--dry-run', '-r', "$root");
  is($exit, 0, 'exit 0');
  is($err, '', 'no diagnostics');
  is(snapshot($root), $before, 'the tree is untouched');
  like($out, qr/^\.raider\.yml -> \.raider\/config\.yml$/m, 'config step');
  like($out, qr/^  backup:  \.raider\.yml\.bak \(\.raider\.yml is renamed to it\)$/m, 'config backup');
  like($out, qr/^  content: copied without its api_key lines 3, 6, 9 \(6 lines left\)$/m, 'lines left out');
  like($out, qr/^  not copied: api_key in the top level, default:, openai:$/m, 'where the keys were');
  like($out, qr/^\.raider\.md -> \.raider\/instructions\.md$/m, 'instructions step');
  like($out, qr/^  content: copied unchanged \(3 lines\)$/m, 'instructions unchanged');
  like($out, qr/^creates \.raider\/\.gitignore \(sessions\/, lib\/\)$/m, '.gitignore announced');
  like($out, qr/^api_key is not copied: .*~\/\.raider\/config\.yml.*_API_KEY.*\.raider\.yml\.bak still holds it/m,
    'where the key should go');
  like($out, qr/\ndry run: nothing written\n\z/, 'dry run said last');
  unlike($out, qr/sk-/, 'no key value printed');
};

subtest 'only .raider.yml' => sub {
  my $root = project(yml => $YML);
  my $want = effective($root);
  my $mode = 0640;
  chmod $mode, $root->child('.raider.yml');
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$root");
  is($exit, 0, 'exit 0');
  is($err, '', 'no diagnostics');
  like($out, qr/^  content: copied unchanged \(10 lines\)$/m, 'unchanged');
  like($out, qr/^migrated \.raider\.yml -> \.raider\/config\.yml \(backup \.raider\.yml\.bak\)$/m, 'done line');
  unlike($out, qr/instructions|dry run|api_key/, 'nothing else');

  my $new = $root->child('.raider', 'config.yml');
  is($new->slurp_utf8, $YML, 'byte for byte, comments kept');
  is((stat $new)[2] & 07777, $mode, 'permissions of the legacy file');
  ok(!-e $root->child('.raider.yml'), 'legacy file gone');
  is($root->child('.raider.yml.bak')->slurp_utf8, $YML, 'backup holds it');
  is($root->child('.raider', '.gitignore')->slurp_utf8, "sessions/\nlib/\n", '.gitignore created');
  ok(!-e $root->child('.raider', 'instructions.md'), 'no instructions.md made up');
  is([ grep { /^\.config\.yml\./ } map { $_->basename } $root->child('.raider')->children ], [],
    'no temporary file left');

  my $config = Langertha::Raider::Config->new(root => "$root");
  ok($config->is_native, '.raider/config.yml is the file in use');
  is([ $config->ignored_files ], [], 'nothing ignored');
  is(effective($root), $want, 'same effective config and sources (F01)');
};

subtest 'only .raider.md' => sub {
  my $root = project(md => $MD);
  my $want = effective($root);
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$root");
  is($exit, 0, 'exit 0');
  is($err, '', 'no diagnostics');
  like($out, qr/^migrated \.raider\.md -> \.raider\/instructions\.md \(backup \.raider\.md\.bak\)$/m, 'done line');
  unlike($out, qr/config\.yml/, 'no config step');
  is($root->child('.raider', 'instructions.md')->slurp_utf8, $MD, 'byte for byte');
  ok(!-e $root->child('.raider.md'), 'legacy file gone');
  is($root->child('.raider.md.bak')->slurp_utf8, $MD, 'backup');
  ok(!-e $root->child('.raider', 'config.yml'), 'no config.yml made up');
  my $app = Langertha::Raider::CLI->new(root => "$root", engine => 'openai', api_key => 'test');
  is($app->mission_source, '.raider/instructions.md', 'the new file is used');
  like($app->mission, qr/You are Bob/, 'its text in the mission');
  is(effective($root), $want, 'same mission and config');
};

subtest 'both files' => sub {
  my $root = project(yml => $YML, md => $MD);
  my $want = effective($root);
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$root");
  is($exit, 0, 'exit 0');
  is($err, '', 'no diagnostics');
  is([ $out =~ /^migrated (\S+)/mg ], [ '.raider.yml', '.raider.md' ], 'config first, then instructions');
  is([ sort map { $_->basename } $root->children ], [ '.raider', '.raider.md.bak', '.raider.yml.bak' ],
    'only the backups left in the root');
  is(effective($root), $want, 'same effective config, sources and mission (F01)');

  # A second run finds nothing to do.
  ( $exit, $out ) = main_run('config', 'migrate', '-r', "$root");
  is($exit, 0, 'again: exit 0');
  like($out, qr/\Anothing to migrate/, 'again: nothing to migrate');
};

subtest 'api_key is left out and reported' => sub {
  my $root = project(yml => $YML_KEYS);
  my $want = effective($root);
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$root");
  is($exit, 0, 'exit 0');
  is($err, '', 'no diagnostics');
  like($out, qr/^  not copied: api_key in the top level, default:, openai:$/m, 'reported with its places');
  unlike($out, qr/sk-/, 'no key value printed');
  my $text = $root->child('.raider', 'config.yml')->slurp_utf8;
  unlike($text, qr/api_key|secret/, 'no key in the shareable file');
  like($text, qr/^# project settings$/m, 'comment kept');
  like($text, qr/^  seed: 4 # per engine$/m, 'trailing comment kept');
  is(YAML::PP->new->load_string($text),
    { temperature => 0.3, default => { model => 'yml-model' }, openai => { seed => 4 } },
    'everything else is there');
  like($root->child('.raider.yml.bak')->slurp_utf8, qr/sk-top-secret/, 'the backup still has it');
  is(effective($root), $want, 'same effective config apart from api_key');
  my $config = Langertha::Raider::Config->new(root => "$root");
  ok(!exists $config->options('openai')->{api_key}, 'no api_key from the project any more');
};

subtest 'api_key the lines cannot be dropped from: rewritten' => sub {
  my $yml = "# comment\nopenai: { api_key: sk-flow-secret, seed: 4 }\ntemperature: 0.3\n";
  my $root = project(yml => $yml);
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '--dry-run', '-r', "$root");
  is($exit, 0, 'dry run');
  like($out, qr/^  content: rewritten from the parsed YAML, comments and layout are not kept$/m, 'said so');
  like($out, qr/^    \| temperature: 0\.3$/m, 'the new content is shown');
  unlike($out, qr/sk-/, 'without the key');
  ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$root");
  is($exit, 0, 'migrated');
  my $text = $root->child('.raider', 'config.yml')->slurp_utf8;
  unlike($text, qr/api_key|secret/, 'no key');
  is(YAML::PP->new->load_string($text), { openai => { seed => 4 }, temperature => 0.3 }, 'the rest');

  # An engine section holding nothing but the key stays a section.
  my $only = project(yml => "openai:\n  api_key: sk-only-secret\nseed: 1\n");
  my $m = Langertha::Raider::Config->new(root => "$only")->migration_content;
  ok($m->{rewritten}, 'dropping the line would turn openai: into a top-level key');
  is(YAML::PP->new->load_string($m->{text}), { openai => {}, seed => 1 }, 'an empty section instead');
  is($m->{api_keys}, ['openai'], 'reported');
};

subtest 'refused: a new file already exists' => sub {
  my $root = project(yml => $YML, md => $MD);
  $root->child('.raider')->mkpath;
  $root->child('.raider', 'instructions.md')->spew_utf8("new\n");
  my $before = snapshot($root);
  for my $dry ( [], ['--dry-run'] ) {
    my ( $exit, $out, $err ) = main_run('config', 'migrate', @$dry, '-r', "$root");
    is($exit, 1, 'exit 1 '.join('', @$dry));
    is($out, '', 'no report');
    like($err, qr/^raider config migrate: \.raider\/instructions\.md already exists next to \.raider\.md: nothing is merged;.*config explain/m,
      'says why');
    like($err, qr/nothing written\n\z/, 'and that nothing was written');
  }
  is(snapshot($root), $before, 'nothing written, also not the config step');

  my $yml = project(yml => $YML);
  $yml->child('.raider')->mkpath;
  $yml->child('.raider', 'config.yml')->spew_utf8("seed: 1\n");
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$yml");
  is($exit, 1, 'config.yml exists: exit 1');
  like($err, qr/\.raider\/config\.yml already exists next to \.raider\.yml/, 'said so');
};

subtest 'refused: a backup exists, .raider is a file, the home directory' => sub {
  my $root = project(yml => $YML);
  $root->child('.raider.yml.bak')->spew_utf8("old\n");
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$root");
  is($exit, 1, 'backup exists: exit 1');
  like($err, qr/\.raider\.yml\.bak already exists: move it away first/, 'said so');
  is($root->child('.raider.yml.bak')->slurp_utf8, "old\n", 'backup untouched');
  ok(-f $root->child('.raider.yml') && !-e $root->child('.raider'), 'nothing moved');

  my $file = project(md => $MD);
  $file->child('.raider')->spew_utf8("not a dir\n");
  ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$file");
  is($exit, 1, '.raider is a file: exit 1');
  like($err, qr/\.raider exists and is not a directory/, 'said so');

  my $home = path($HOME);
  $home->child('.raider.yml')->spew_utf8($YML);
  ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$home");
  is($exit, 1, 'home directory: exit 1');
  like($err, qr/is the home directory: there \.raider\/config\.yml is the home config of every project/, 'said so');
  ok(!-e $home->child('.raider', 'config.yml'), 'no home config written');
  $home->child('.raider.yml')->remove;
};

subtest 'a broken .raider.yml' => sub {
  my $root = project(yml => "a: [\n", md => $MD);
  my $before = snapshot($root);
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$root");
  is($exit, 3, 'exit 3');
  like($err, qr/\ACannot parse .*\.raider\.yml: [^\n]+\n\z/, 'one line naming the file');
  is(snapshot($root), $before, 'nothing written');
};

subtest 'usage' => sub {
  my $root = project(yml => $YML);
  my $before = snapshot($root);
  my ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$root", 'now');
  is($exit, 2, 'a word after it');
  like($err, qr/\AUsage: raider config migrate \[--dry-run\]/, 'usage');
  ( $exit, $out, $err ) = main_run('config', 'migrate', '-r', "$root", '--json');
  is($exit, 2, 'a machine format');
  like($err, qr/no machine output/, 'said so');
  ( $exit, $out, $err ) = main_run('config', 'migrate', '--bogus');
  is($exit, 2, 'unknown option');
  ( $exit, $out, $err ) = main_run('config', 'migrate', '--help');
  is($exit, 0, '--help');
  like($out, qr/\AUsage: raider config migrate \[--dry-run\] \[options\]\n/, 'its own usage');
  like($out, qr/--dry-run\s+Show what would happen/, 'names --dry-run');
  ( $exit, $out, $err ) = main_run('config', 'nope');
  is($exit, 2, 'unknown config subcommand');
  like($err, qr/raider config migrate \[--dry-run\]/, 'usage names migrate');
  ( $exit, $out ) = main_run('--help');
  like($out, qr/raider config migrate \[--dry-run\]/, 'raider --help names it');
  is(snapshot($root), $before, 'nothing written');
};

# A step that fails leaves its legacy file in use and no new file; the
# steps before it stay migrated.
package My::Migrate {
  use Moose;
  extends 'Langertha::Raider::Config::Migrate';
  has fail_on => ( is => 'ro' );
  sub _move {
    my ( $self, $from, $to ) = @_;
    die "cannot rename\n" if $to->basename eq $self->fail_on;
    return $self->SUPER::_move($from, $to);
  }
  __PACKAGE__->meta->make_immutable;
}

subtest 'failure mid-way' => sub {
  # The backup rename of the instructions fails after its new file was
  # written: the new file goes again, the config step stays done.
  my $root = project(yml => $YML, md => $MD);
  my $migrate = My::Migrate->new(root => "$root", fail_on => '.raider.md.bak');
  my @results = $migrate->apply($migrate->plan);
  is(scalar @results, 2, 'both steps reported');
  ok(!$results[0]{error}, 'config migrated');
  like($results[1]{error}, qr/cannot rename/, 'instructions failed');
  ok(-f $root->child('.raider', 'config.yml') && !-e $root->child('.raider.yml'), 'config: new file in use');
  ok(-f $root->child('.raider.md'), 'instructions: legacy file still there');
  ok(!-e $root->child('.raider', 'instructions.md'), 'instructions: no new file');
  ok(!-e $root->child('.raider.md.bak'), 'instructions: no backup');
  is([ grep { /^\.instructions\.md\./ } map { $_->basename } $root->child('.raider')->children ], [],
    'no temporary file left');
  my $app = Langertha::Raider::CLI->new(root => "$root", engine => 'openai', api_key => 'test');
  is($app->mission_source, '.raider.md', 'the legacy instructions are used');
  is([ $app->instructions->ignored_files ], [], 'no conflict left behind');

  # Writing the first new file fails: nothing moved, the next step skipped.
  my $first = project(yml => $YML, md => $MD);
  $migrate = My::Migrate->new(root => "$first", fail_on => 'config.yml');
  @results = $migrate->apply($migrate->plan);
  like($results[0]{error}, qr/cannot rename/, 'config failed');
  ok($results[1]{skipped}, 'instructions skipped');
  ok(-f $first->child('.raider.yml') && -f $first->child('.raider.md'), 'both legacy files in use');
  is([ sort map { $_->basename } $first->child('.raider')->children ], ['.gitignore'],
    'only .raider/.gitignore, no new or temporary file');

  # Through the CLI: a new file that appears between plan and apply.
  my $race = project(yml => $YML, md => $MD);
  package My::Main {
    use Moose;
    extends 'Langertha::Raider::CLI::Main';
    sub migrate_class { 'My::RaceMigrate' }
    __PACKAGE__->meta->make_immutable;
  }
  package My::RaceMigrate {
    use Moose;
    extends 'Langertha::Raider::Config::Migrate';
    sub _apply_step {
      my ( $self, $step ) = @_;
      $step->{to}->spew_utf8("appeared\n") if $step->{kind} eq 'instructions';
      return $self->SUPER::_apply_step($step);
    }
    __PACKAGE__->meta->make_immutable;
  }
  my ( $exit, $out, $err ) = main_run(\'My::Main', 'config', 'migrate', '-r', "$race");
  is($exit, 1, 'exit 1');
  like($out, qr/^migrated \.raider\.yml/m, 'the config step is reported done');
  like($err, qr/^raider config migrate: \.raider\.md not migrated, it stays in use: \.raider\/instructions\.md already exists$/m,
    'the failed step');
  is($race->child('.raider', 'instructions.md')->slurp_utf8, "appeared\n", 'the file that appeared is not replaced');
  ok(-f $race->child('.raider.md'), 'legacy instructions kept');
};

subtest 'an existing .raider/ keeps its .gitignore' => sub {
  my $root = project(yml => $YML);
  $root->child('.raider')->mkpath;
  $root->child('.raider', '.gitignore')->spew_utf8("mine\n");
  my ( $exit, $out ) = main_run('config', 'migrate', '-r', "$root");
  is($exit, 0, 'exit 0');
  unlike($out, qr/creates \.raider\/\.gitignore/, 'not announced');
  is($root->child('.raider', '.gitignore')->slurp_utf8, "mine\n", 'untouched');
};

done_testing;
