#!/usr/bin/env perl
# ABSTRACT: <root>/.raider/instructions.md next to the legacy .raider.md (ADR 0011, k127)

use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider;
use Langertha::Raider::Instructions;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;
use Langertha::Raider::Skill;

clear_engine_env();

# The instructions file in use is .raider/instructions.md when it exists,
# else .raider.md. Both present: the new one is used, the legacy one is not
# read and is reported. -M replaces either (ADR 0014); the prompt-builder
# writes the file in use and never creates .raider/instructions.md.

my $NEW    = "New instructions.\n";
my $LEGACY = "Legacy instructions.\n";
my $IGNORED_REASON = 'both .raider.md and .raider/instructions.md exist; only .raider/instructions.md is used';

sub project {
  my ( %files ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  if (defined $files{new}) {
    $root->child('.raider')->mkpath;
    $root->child('.raider', 'instructions.md')->spew_utf8($files{new});
  }
  $root->child('.raider.md')->spew_utf8($files{legacy}) if defined $files{legacy};
  return $root;
}

sub app {
  my ( $root, %args ) = @_;
  return Langertha::Raider::CLI->new(root => "$root", engine => 'openai', api_key => 'test',
    model => 'gpt-4o-mini', trace => 0, %args);
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; my $t = decode_utf8($buf); $buf = ''; seek $fh, 0, 0; $t } );
}

sub report_text {
  my ( $report ) = @_;
  my ( $fh, $read ) = buffer();
  Langertha::Raider::CLI::Output->new(out => $fh, color => 0)->config_report($report);
  return $read->();
}

sub banner_persona {
  my ( $app ) = @_;
  my ( $fh, $read ) = buffer();
  Langertha::Raider::CLI::REPL->new(
    app    => $app,
    output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0),
    in     => do { open my $in, '<', \'' or die $!; $in },
  )->banner('none');
  return $read->() =~ /^persona:  (.*)$/m ? $1 : undef;
}

sub skill_persona { Langertha::Raider::Skill->new(app => $_[0])->markdown =~ /^- Persona: (.*)$/m ? $1 : undef }

subtest 'only .raider/instructions.md' => sub {
  my $root = project(new => $NEW);
  my $file = $root->child('.raider', 'instructions.md');
  my $ins = Langertha::Raider::Instructions->new(root => "$root");
  is($ins->file->stringify, $file->stringify, 'file in use');
  ok($ins->is_native, 'native');
  is($ins->label, '.raider/instructions.md', 'label');
  is($ins->text, $NEW, 'text');
  is([ $ins->ignored_files ], [], 'nothing ignored');

  my $app = app($root);
  my $m = $app->mission;
  like($m, qr/\QUser's custom instructions (from $file):\E\n\nNew instructions\.\n/, 'in the mission, with its path');
  like($m, qr/change persona entirely via C<\.raider\/instructions\.md> in working dir/, 'persona points at it');
  unlike($m, qr/\.raider\.md/, 'no mention of .raider.md');
  is($app->mission_source, '.raider/instructions.md', 'mission_source');

  my $report = $app->explain_config;
  like($report, { instructions => '.raider/instructions.md', ignored_instructions_files => [] }, 'explain');
  like(report_text($report), qr{^instructions: \.raider/instructions\.md\n(?!  ignored)}m, 'config explain line');
  is(banner_persona($app), 'custom (.raider/instructions.md loaded)', 'banner');
  is(skill_persona($app), 'custom (loaded from '.$file.')', 'skill export');
};

subtest 'only .raider.md: unchanged' => sub {
  my $root = project(legacy => $LEGACY);
  my $file = path("$root")->child('.raider.md');
  my $ins = Langertha::Raider::Instructions->new(root => "$root");
  is($ins->file->stringify, $file->stringify, 'file in use');
  ok(!$ins->is_native, 'not native');
  is($ins->label, '.raider.md', 'label');
  is([ $ins->ignored_files ], [], 'nothing ignored');

  my $app = app($root);
  my $m = $app->mission;
  like($m, qr/\QUser's custom instructions (from $file):\E\n\nLegacy instructions\.\n/, 'in the mission');
  like($m, qr/change persona entirely via C<\.raider\.md> in working dir/, 'persona text as before');
  unlike($m, qr/instructions\.md/, 'no mention of .raider/instructions.md');
  is($app->mission_source, '.raider.md', 'mission_source');
  like($app->explain_config, { instructions => '.raider.md', ignored_instructions_files => [] }, 'explain');
  unlike(report_text($app->explain_config), qr/ignored/, 'nothing ignored in config explain');
  is(banner_persona($app), 'custom (.raider.md loaded)', 'banner');

  my $none = app(project());
  like($none->mission, qr/change persona entirely via C<\.raider\.md> in working dir/, 'no file: persona names .raider.md');
  is($none->mission_source, 'default', 'no file: default');
  is(banner_persona($none), 'Langertha (default)', 'no file: banner');
};

subtest 'a .raider/ directory without instructions.md keeps .raider.md' => sub {
  my $root = project(legacy => $LEGACY);
  $root->child('.raider', 'lib')->mkpath;
  my $app = app($root);
  is($app->mission_source, '.raider.md', 'legacy in use');
  like($app->mission, qr/Legacy instructions/, 'legacy read');
};

subtest 'both: the new file wins, the legacy file is reported' => sub {
  my $root = project(new => $NEW, legacy => $LEGACY);
  my $ins = Langertha::Raider::Instructions->new(root => "$root");
  is($ins->label, '.raider/instructions.md', 'new file in use');
  is([ $ins->ignored_files ], [ {
    file   => $root->child('.raider.md')->absolute->stringify,
    reason => $IGNORED_REASON,
  } ], 'legacy file reported');

  my $app = app($root);
  like($app->mission, qr/New instructions/, 'new text in the mission');
  unlike($app->mission, qr/Legacy instructions/, 'legacy text not');
  is($app->mission_source, '.raider/instructions.md', 'mission_source');

  my $report = $app->explain_config;
  is($report->{ignored_instructions_files}, [ $ins->ignored_files ], 'explain_config reports it');
  like(report_text($report),
    qr{^instructions: \.raider/instructions\.md\n  ignored file \S+/\.raider\.md: \Q$IGNORED_REASON\E\n}m,
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
  my $stderr = $read_err->();
  like($stderr, qr{^warning: ignoring \S+/\.raider\.md: \Q$IGNORED_REASON\E$}m, 'warned on stderr');
  is(scalar(() = $stderr =~ /^warning:/mg), 1, 'once');
  like($read_out->(), qr{^instructions: \.raider/instructions\.md\n  ignored file }m, 'report');

  for my $case ([ legacy => project(legacy => $LEGACY) ], [ new => project(new => $NEW) ]) {
    ( $out, $read_out ) = buffer();
    ( $err, $read_err ) = buffer();
    Langertha::Raider::CLI::Main->new(
      output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
      err    => $err,
    )->run('-r', "$case->[1]", '-e', 'openai', '-k', 'test', '--no-trace', 'config', 'explain');
    is($read_err->(), '', 'no warning with only the '.$case->[0].' file');
  }
};

subtest '-M and --bare replace either file' => sub {
  my $root = project(new => $NEW, legacy => $LEGACY);
  my $app = app($root, mission => 'The -M mission.');
  unlike($app->mission, qr/New instructions|Legacy instructions/, '-M: neither file');
  like($app->mission, qr/\AThe -M mission\./, '-M text first');
  is($app->mission_source, '-M', 'mission_source');
  like($app->explain_config, { instructions => '-M', ignored_instructions_files => [ { file => qr/\.raider\.md\z/ } ] },
    'the conflict is still reported under -M');
  is(banner_persona($app), 'from -M (.raider/instructions.md not used)', 'banner');
  is(skill_persona($app), 'from -M (.raider/instructions.md not used)', 'skill export');

  my $bare = app(project(new => $NEW), bare => 1);
  unlike($bare->mission, qr/New instructions/, '--bare: file not read');
  is($bare->mission_source, 'default', '--bare: default');
  is(skill_persona($bare),
    'Langertha (default viking persona), bare (no .raider/instructions.md or skills, only explicit packs)', '--bare skill');

  my $legacy = app(project(legacy => $LEGACY), mission => 'X');
  is(banner_persona($legacy), 'from -M (.raider.md not used)', 'legacy -M banner as before');
};

subtest '/reload sees a file created during the session' => sub {
  my $root = project(legacy => $LEGACY);
  my $app = app($root);
  like($app->raider->mission, qr/Legacy instructions/, 'legacy at start');
  $root->child('.raider')->mkpath;
  $root->child('.raider', 'instructions.md')->spew_utf8($NEW);
  my ( $fh, $read ) = buffer();
  Langertha::Raider::CLI::Commands->new(app => $app,
    output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0))->cmd_reload;
  like($read->(), qr/^mission reloaded: custom \(\.raider\/instructions\.md loaded\)/, '/reload names it');
  like($app->raider->mission, qr/New instructions/, 'new text after reload');
  unlike($app->raider->mission, qr/Legacy instructions/, 'legacy gone');
};

subtest 'the prompt-builder writes the file in use' => sub {
  my @missions;
  my $mock = mock 'Langertha::Raider' => (
    around => [ new => sub {
      my ( $orig, $class, %args ) = @_;
      push @missions, $args{mission};
      return $class->$orig(%args);
    } ],
  );
  my $run = sub {
    my ( $root ) = @_;
    @missions = ();
    open my $in, '<', \"/cancel\n" or die $!;
    my ( $fh, $read ) = buffer();
    Langertha::Raider::CLI::Commands->new(app => app($root), in => $in,
      output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0))->cmd_prompt;
    like($read->(), qr/prompt-builder cancelled/, 'cancelled');
    is(scalar @missions, 1, 'one builder raider');
    return $missions[0] =~ /save to:\n\s+(\S+)\n/ ? $1 : undef;
  };

  my $root = project(new => $NEW, legacy => $LEGACY);
  is($run->($root), $root->child('.raider', 'instructions.md')->stringify, 'both: into .raider/instructions.md');
  like($missions[0], qr/Current \.raider\/instructions\.md content:\n---\nNew instructions\./, 'shows the new file');

  $root = project(new => $NEW);
  is($run->($root), $root->child('.raider', 'instructions.md')->stringify, 'new only: into it');

  $root = project(legacy => $LEGACY);
  is($run->($root), $root->child('.raider.md')->stringify, 'legacy only: into .raider.md');
  like($missions[0], qr/Current \.raider\.md content:\n---\nLegacy instructions\./, 'legacy wording as before');

  $root = project();
  is($run->($root), $root->child('.raider.md')->stringify, 'no file: .raider.md, never .raider/instructions.md');
  like($missions[0], qr/\(no \.raider\.md yet/, 'says there is none yet');
  ok(!-e $root->child('.raider'), 'no .raider/ created');
};

done_testing;
