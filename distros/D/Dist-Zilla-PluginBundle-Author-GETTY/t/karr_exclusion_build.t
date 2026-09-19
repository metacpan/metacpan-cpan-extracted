use strict;
use warnings;
use Test::More;
use Dist::Zilla::Tester;
use Dist::Zilla::Chrome::Term;
use Path::Tiny;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);

# effective_gather_exclude_filename (unit-tested in t/readme_exclusion.t) is
# the only place that decides whether .karr is excluded, and it feeds
# straight into [Git::GatherDir]'s exclude_filename. This test proves that
# wiring end to end: a real (local-only, no remote, no network) git repo is
# gathered through the actual bundle-assembled Git::GatherDir plugin, and
# .karr either survives or doesn't depending on no_cpan.

plan skip_all => "Dist::Zilla::Tester not available"
  unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };

plan skip_all => "git binary not available"
  unless can_run('git');

sub gathered_files {
  my ($dzil_config) = @_;

  my $tempdir = tempdir(CLEANUP => 1);
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->mkpath;

  $dist_dir->child('dist.ini')->spew($dzil_config);
  $dist_dir->child('lib', 'Foo.pm')->parent->mkpath;
  $dist_dir->child('lib', 'Foo.pm')->spew("package Foo;\n1;\n");
  $dist_dir->child('.karr')->spew("karr state\n");

  # Git::GatherDir only gathers files tracked by git (`git ls-files`), so the
  # fixture must be a real git working copy. `-C $dist_dir` runs each command
  # inside that fixture repo regardless of this test's own cwd (which is
  # itself inside this repo's git working copy). No remote is ever configured
  # and no network is touched -- this is a plain local `git init` + commit.
  for my $args (
    [qw(init -q)],
    [qw(add -A)],
    ['-c', 'user.email=test@test.de', '-c', 'user.name=Test', 'commit', '-q', '-m', 'init'],
  ) {
    system('git', '-C', "$dist_dir", @$args) == 0
      or die "git @{$args} failed in $dist_dir: $?";
  }

  my $tzil = Dist::Zilla::Tester->from_config({
    dist_root => "$dist_dir",
  }, {
    tempdir_root => $tempdir,
    chrome => Dist::Zilla::Chrome::Term->new,
  });

  # Run only the gather phase (exactly what Dist::Zilla::Dist::Builder::build_in
  # does before pruning/munging/registering prereqs), so this stays a targeted
  # exercise of Git::GatherDir's exclude_filename rather than a full release build.
  $_->gather_files for @{ $tzil->plugins_with(-FileGatherer) };

  return [ sort map { $_->name } @{ $tzil->files } ];
}

# Default (no_cpan unset, the CPAN-release default): .karr must not reach the
# gathered files.
{
  my $files = gathered_files(<<'CONF');
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
CONF

  ok(!(grep { $_ eq '.karr' } @$files), '.karr is not gathered on the CPAN-release default (no_cpan unset)');
  ok((grep { $_ eq 'lib/Foo.pm' } @$files), 'sanity: gathering actually ran and picked up tracked files');
}

# no_cpan = 1: .karr is kept in the built distribution.
{
  my $files = gathered_files(<<'CONF');
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
no_cpan = 1
CONF

  ok((grep { $_ eq '.karr' } @$files), '.karr is gathered when no_cpan = 1');
}

done_testing;
