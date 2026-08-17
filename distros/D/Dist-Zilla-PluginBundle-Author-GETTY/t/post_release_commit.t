use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;
use Dist::Zilla::Plugin::BumpVersionAfterRelease;

# @Git::VersionManager bumps the $VERSION of everything its BumpVersionAfterRelease
# finder covers (:InstallModules *and* :ExecFiles by default), but its post-release
# commit only allows ^lib/.*\.pm$ to be dirty. Executables under bin/ would be
# rewritten in the working tree and never committed, leaving git with a bin/ one
# release behind lib/. The bundle closes that gap with an extra allow_dirty_match.

sub configured_plugins {
  my (%payload) = @_;
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { %payload },
  );
  $bundle->configure;
  return @{ $bundle->plugins };
}

sub git_commit {
  my ($suffix, @plugins) = @_;
  my ($plugin) = grep {
    $_->[1] eq 'Dist::Zilla::Plugin::Git::Commit' && $_->[0] =~ m{/\Q$suffix\E$}
  } @plugins;
  return $plugin;
}

{
  my @plugins = configured_plugins();

  my $post_release = git_commit('post-release commit', @plugins);
  ok($post_release, 'the post-release commit plugin was added');

  is_deeply(
    $post_release->[2]{allow_dirty_match},
    [ '^lib/.*\.pm$', '^bin/' ],
    'post-release commit also commits the bumped executables under bin/',
  );

  is(
    $post_release->[2]{commit_msg},
    'increment $VERSION after %v release',
    'the extra allow_dirty_match went to the version bump commit, not somewhere else',
  );

  my $release_snapshot = git_commit('release snapshot', @plugins);
  ok($release_snapshot, 'the release snapshot commit plugin was added');
  ok(
    !exists $release_snapshot->[2]{allow_dirty_match},
    'the release snapshot commit is left untouched',
  );
}

# The bin/ rule and commit_files_after_release feed two different commits and
# must not interfere with each other.
{
  my @plugins = configured_plugins(
    commit_files_after_release => [ 'python/locale_simple.py' ],
  );

  my $post_release = git_commit('post-release commit', @plugins);
  is_deeply(
    $post_release->[2]{allow_dirty_match},
    [ '^lib/.*\.pm$', '^bin/' ],
    'commit_files_after_release does not disturb the bin/ rule',
  );

  my $release_snapshot = git_commit('release snapshot', @plugins);
  is_deeply(
    [ sort @{ $release_snapshot->[2]{allow_dirty} } ],
    [ 'Changes', 'python/locale_simple.py' ],
    'commit_files_after_release still reaches the release snapshot commit',
  );
}

# Why ^bin/ is needed at all: the bump covers :ExecFiles, and with no ExecDir
# plugin configured Dist::Zilla's default exec directory is bin.
{
  my $finder = Dist::Zilla::Plugin::BumpVersionAfterRelease->meta
    ->find_attribute_by_name('finder');
  my $default_finders = eval {
    $finder->default->( bless {}, 'Dist::Zilla::Plugin::BumpVersionAfterRelease' )
  };

 SKIP: {
    skip 'cannot introspect the BumpVersionAfterRelease finder default', 1
      unless ref $default_finders eq 'ARRAY';

    ok(
      ( grep { $_ eq ':ExecFiles' } @$default_finders ),
      'BumpVersionAfterRelease bumps :ExecFiles by default',
    );
  }
}

done_testing;
