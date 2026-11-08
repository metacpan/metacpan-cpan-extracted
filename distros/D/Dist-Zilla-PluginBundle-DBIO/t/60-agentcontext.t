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

sub gathered_files {
  my $tempdir  = tempdir(CLEANUP => 1);
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->child('lib','DBIO')->mkpath;
  $dist_dir->child('dist.ini')->spew(<<'CONF');
name = DBIO-Test
author = Test <test@test.de>
license = Perl_5
copyright_year = 2005

[@DBIO]
CONF
  $dist_dir->child('lib','DBIO','Test.pm')->spew(
    "package DBIO::Test;\n# ABSTRACT: t\nour \$VERSION='0.001';\n1;\n");
  $dist_dir->child('LICENSE')->spew("license\n");
  $dist_dir->child('cpanfile')->spew("requires 'perl','5.020';\n");
  $dist_dir->child('CLAUDE.md')->spew("build context\n");
  $dist_dir->child('.claude','skills','dbio-test','SKILL.md')->parent->mkpath;
  $dist_dir->child('.claude','skills','dbio-test','SKILL.md')->spew("owned\n");

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

my %have = map { $_ => 1 } @{ gathered_files() };

ok $have{'misc/agent-context/CLAUDE.md'},
   '@DBIO wires GatherAgentContext: CLAUDE.md snapshotted';
ok $have{'misc/agent-context/.claude/skills/dbio-test/SKILL.md'},
   'owned skill present in agent-context snapshot';

# Note: GatherSkills' own share/skills/ output is covered by t/50-gatherskills.t
# and its cwd-relative `from` makes it unsuitable to assert via this in-process
# gather_files harness. Coexistence of GatherSkills + GatherAgentContext is
# verified end to end by a real `dzil build` on DBIO (see the plan's Task 8).

done_testing;
