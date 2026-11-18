#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Dist::Zilla::Tester;
use Dist::Zilla::Chrome::Term;
use Path::Tiny;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);

plan skip_all => "git binary not available" unless can_run('git');

# A task builds with @Git and AutoVersion instead of @Git::VersionManager, so
# nothing used to stamp Changes: {{$NEXT}} went into the tarball and
# GitHub::CreateRelease found no release heading. The bundle now adds
# NextRelease for a task, formatted like @Git::VersionManager does, ahead of
# @Git (whose Git::Commit commits the stamped Changes) and of
# GitHub::CreateRelease.

sub task_dist {
  my (%payload) = @_;
  my $tempdir  = tempdir(CLEANUP => 1);
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->child('lib')->mkpath;
  my $extra = join '', map { "$_ = $payload{$_}\n" } sort keys %payload;
  $dist_dir->child('dist.ini')->spew(<<"CONF");
name = Task-Test
author = Test <test\@test.de>
license = Perl_5
copyright_holder = Test

[\@Author::GETTY]
task = 1
no_github = 0
no_github_release = 0
generate_license = 1
$extra
CONF
  $dist_dir->child('lib','Task','Test.pm')->parent->mkpath;
  $dist_dir->child('lib','Task','Test.pm')->spew("package Task::Test;\n# ABSTRACT: t\n1;\n");
  $dist_dir->child('Changes')->spew("{{\$NEXT}}\n\n  - something\n");

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
  $tzil->build;
  return $tzil;
}

sub plugin_index {
  my ($tzil, $class) = @_;
  my $i = 0;
  for my $p (@{ $tzil->plugins }) {
    return $i if ref($p) eq "Dist::Zilla::Plugin::$class";
    $i++;
  }
  return;
}

{
  my $tzil = task_dist();

  my $next = plugin_index($tzil, 'NextRelease');
  ok defined $next, 'task: NextRelease is in the plugin list';

  my $commit = plugin_index($tzil, 'Git::Commit');
  ok defined $commit, 'task: @Git brings Git::Commit';
  ok defined $next && defined $commit && $next < $commit,
    'task: NextRelease comes before Git::Commit, which commits the stamped Changes';

  my $release = plugin_index($tzil, 'Author::GETTY::GitHubRelease');
  ok defined $release && defined $next && $next < $release,
    'task: NextRelease comes before Author::GETTY::GitHubRelease, which reads the notes from Changes';

  ok defined plugin_index($tzil, 'Test::ChangesHasContent'),
    'task: Test::ChangesHasContent is in the plugin list';

  my $changes = $tzil->built_in->child('Changes')->slurp_utf8;
  like $changes, qr/^\d{8}\.000  \d{4}-\d\d-\d\d \d\d:\d\d:\d\dZ$/m,
    'task: built Changes carries "YYYYMMDD.000  <UTC time>"';
  unlike $changes, qr/\Q{{\E\$NEXT\Q}}\E/, 'task: no {{$NEXT}} is left in the built Changes';
  like $changes, qr/^  - something$/m, 'task: the entry stays under the stamped heading';
}

{
  my $tzil = task_dist(no_changes => 1);

  ok !defined plugin_index($tzil, 'NextRelease'),
    'task with no_changes: no NextRelease';
  ok !defined plugin_index($tzil, 'Test::ChangesHasContent'),
    'task with no_changes: no Test::ChangesHasContent';
}

done_testing;
