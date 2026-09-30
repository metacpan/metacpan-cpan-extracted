use strict;
use warnings;
use Test::More;
use Dist::Zilla::Tester;
use Dist::Zilla::Chrome::Term;
use Path::Tiny;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);

plan skip_all => "Dist::Zilla::Tester not available"
  unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };
plan skip_all => "git binary not available" unless can_run('git');

# Baut eine echte lokale git-Fixture mit @Author::GETTY und laesst alle
# FileGatherer laufen (Git::GatherDir + GatherAgentContext), dann inspiziert es
# die gesammelten Dateinamen.
sub gathered_files {
  my $tempdir  = tempdir(CLEANUP => 1);
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->child('lib')->mkpath;
  $dist_dir->child('dist.ini')->spew(<<'CONF');
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
CONF
  $dist_dir->child('lib','Foo.pm')->spew("package Foo;\n# ABSTRACT: t\n1;\n");
  $dist_dir->child('CLAUDE.md')->spew("build context\n");
  # owned skill: committed, git-tracked
  $dist_dir->child('.claude','skills','owned','SKILL.md')->parent->mkpath;
  $dist_dir->child('.claude','skills','owned','SKILL.md')->spew("owned\n");
  # consumed skill: git-IGNORED (simuliert skilletor-Zustand), nicht committet
  $dist_dir->child('.claude','skills','consumed','SKILL.md')->parent->mkpath;
  $dist_dir->child('.claude','skills','consumed','SKILL.md')->spew("consumed\n");
  $dist_dir->child('.gitignore')->spew(".claude/skills/consumed/\n");

  for my $args (
    [qw(init -q)],
    [qw(add -A)],
    ['-c','user.email=test@test.de','-c','user.name=Test','commit','-q','-m','init'],
  ) {
    system('git','-C',"$dist_dir",@$args) == 0 or die "git @{$args} failed: $?";
  }

  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => "$dist_dir" },
    { tempdir_root => $tempdir, chrome => Dist::Zilla::Chrome::Term->new },
  );
  $_->gather_files for @{ $tzil->plugins_with(-FileGatherer) };
  return [ sort map { $_->name } @{ $tzil->files } ];
}

my $files = gathered_files();
my %have  = map { $_ => 1 } @$files;

ok $have{'misc/agent-context/CLAUDE.md'},
   '@Author::GETTY wires GatherAgentContext: CLAUDE.md snapshotted';
ok $have{'misc/agent-context/.claude/skills/owned/SKILL.md'},
   'owned skill snapshotted into misc/agent-context/';
ok $have{'misc/agent-context/.claude/skills/consumed/SKILL.md'},
   'git-ignored consumed skill snapshotted (disk read, not git)';
ok !$have{'.claude/skills/consumed/SKILL.md'},
   'git-ignored consumed skill is NOT gathered at repo root by Git::GatherDir';

done_testing;
