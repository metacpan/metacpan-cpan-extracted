use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use Path::Tiny;

use Dist::Zilla::Chrome::Term;
use Dist::Zilla::PluginBundle::Author::GETTY;
use Dist::Zilla::Tester;

# CPAN default: version Perl modules and Perl executables, not every executable
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => {},
  );

  is_deeply(
    $bundle->version_finder,
    [':InstallModules', ':PerlExecFiles'],
    'version_finder defaults to install modules and Perl executables',
  );
}

# Single value (as dist.ini would deliver it after mvp_multivalue parsing)
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { version_finder => [':MainModule'] },
  );

  is_deeply(
    $bundle->version_finder,
    [':MainModule'],
    'version_finder accepts a single finder',
  );
}

# Multiple values
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { version_finder => [':MainModule', ':ExecFiles'] },
  );

  is_deeply(
    $bundle->version_finder,
    [':MainModule', ':ExecFiles'],
    'version_finder passes through as a multi-value list',
  );
}

ok(
  ( grep { $_ eq 'version_finder' } Dist::Zilla::PluginBundle::Author::GETTY->mvp_multivalue_args ),
  'version_finder is declared as a multi-value argument',
);

# no_cpan implies :MainModule -- a dist that never reaches CPAN needs no
# per-package version, so the main module carries the only $VERSION.
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { no_cpan => 1 },
  );

  is_deeply(
    $bundle->version_finder,
    [':MainModule'],
    'version_finder defaults to :MainModule when no_cpan is set',
  );
}

# ... but an explicit version_finder still wins over the no_cpan default
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { no_cpan => 1, version_finder => [':InstallModules'] },
  );

  is_deeply(
    $bundle->version_finder,
    [':InstallModules'],
    'explicit version_finder overrides the no_cpan default',
  );
}

# Default path (no task, no manual_version): version_finder must be forwarded
# to @Git::VersionManager as RewriteVersion::Transitional.finder and
# BumpVersionAfterRelease.finder.
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { version_finder => [':MainModule'] },
  );
  $bundle->configure;

  my ($pkg_version_plugin) = grep { $_->[1] eq 'Dist::Zilla::Plugin::PkgVersion' } @{ $bundle->plugins };
  ok(!$pkg_version_plugin, 'no PkgVersion plugin added on default (@Git::VersionManager) path');

  my ($rewrite_version) = grep { $_->[1] eq 'Dist::Zilla::Plugin::RewriteVersion::Transitional' } @{ $bundle->plugins };
  ok($rewrite_version, 'RewriteVersion::Transitional was added');
  is_deeply(
    $rewrite_version->[2]{finder},
    [':MainModule'],
    'RewriteVersion::Transitional.finder receives version_finder',
  );

  my ($bump_version) = grep {
    $_->[1] eq 'Dist::Zilla::Plugin::BumpVersionAfterRelease'
    || $_->[1] eq 'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional'
  } @{ $bundle->plugins };
  ok($bump_version, 'BumpVersionAfterRelease (Transitional) was added');
  is_deeply(
    $bump_version->[2]{finder},
    [':MainModule'],
    'BumpVersionAfterRelease.finder receives version_finder',
  );
}

# manual_version path: PkgVersion gets the finder
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => {
      manual_version => 1,
      version_finder => [':MainModule'],
    },
  );
  $bundle->configure;

  my ($pkg_version) = grep { $_->[1] eq 'Dist::Zilla::Plugin::PkgVersion' } @{ $bundle->plugins };
  ok($pkg_version, 'PkgVersion was added on manual_version path');
  is_deeply(
    $pkg_version->[2]{finder},
    [':MainModule'],
    'PkgVersion.finder receives version_finder on manual_version path',
  );
}

# manual_version path without an explicit version_finder: PkgVersion gets the
# CPAN default rather than its broader :ExecFiles default.
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { manual_version => 1 },
  );
  $bundle->configure;

  my ($pkg_version) = grep { $_->[1] eq 'Dist::Zilla::Plugin::PkgVersion' } @{ $bundle->plugins };
  ok($pkg_version, 'PkgVersion was added on manual_version path');
  is_deeply(
    $pkg_version->[2]{finder},
    [':InstallModules', ':PerlExecFiles'],
    'PkgVersion.finder receives the CPAN default',
  );
}

# no_cpan without an explicit version_finder: the :MainModule default reaches
# the version plugins, on both the @Git::VersionManager and the PkgVersion path.
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { no_cpan => 1 },
  );
  $bundle->configure;

  my ($rewrite_version) = grep { $_->[1] eq 'Dist::Zilla::Plugin::RewriteVersion::Transitional' } @{ $bundle->plugins };
  ok($rewrite_version, 'RewriteVersion::Transitional was added on the no_cpan default path');
  is_deeply(
    $rewrite_version->[2]{finder},
    [':MainModule'],
    'RewriteVersion::Transitional.finder receives the no_cpan default',
  );
}

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { no_cpan => 1, manual_version => 1 },
  );
  $bundle->configure;

  my ($pkg_version) = grep { $_->[1] eq 'Dist::Zilla::Plugin::PkgVersion' } @{ $bundle->plugins };
  ok($pkg_version, 'PkgVersion was added on the no_cpan + manual_version path');
  is_deeply(
    $pkg_version->[2]{finder},
    [':MainModule'],
    'PkgVersion.finder receives the no_cpan default',
  );
}

# The CPAN default must keep Perl executables versioned without sending shell
# executables through the PPI-based version rewriters.
subtest 'default version finders select Perl executables only' => sub {
  plan skip_all => 'git binary not available' unless can_run('git');

  my $tempdir = tempdir(CLEANUP => 1);
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->mkpath;

  $dist_dir->child('dist.ini')->spew(<<'CONF');
name = Finder-Test
version = 0.001
author = Test <test@example.com>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
no_github = 1
CONF

  $dist_dir->child('lib', 'Finder', 'Test.pm')->parent->mkpath;
  $dist_dir->child('lib', 'Finder', 'Test.pm')->spew(<<'PERL');
package Finder::Test;
our $VERSION = '0.001';
1;
PERL

  $dist_dir->child('bin')->mkpath;
  $dist_dir->child('bin', 'perl-tool')->spew(<<'PERL');
#!/usr/bin/env perl
our $VERSION = '0.001';
PERL
  $dist_dir->child('bin', 'bash-tool')->spew(<<'BASH');
#!/usr/bin/env bash
VERSION=0.001
BASH

  for my $args (
    [qw(init -q)],
    [qw(add -A)],
    ['-c', 'user.email=test@example.com', '-c', 'user.name=Test', 'commit', '-q', '-m', 'init'],
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

  $_->gather_files for @{ $tzil->plugins_with(-FileGatherer) };

  my @cases = (
    [ 'RewriteVersion::Transitional', 'Dist::Zilla::Plugin::RewriteVersion::Transitional' ],
    [ 'BumpVersionAfterRelease',      'Dist::Zilla::Plugin::BumpVersionAfterRelease' ],
  );

  for my $case (@cases) {
    my ($label, $class) = @$case;
    my ($plugin) = grep { $_->isa($class) } @{ $tzil->plugins };
    ok($plugin, "$label was configured");
    is_deeply(
      [ map { $_->name } @{ $plugin->found_files } ],
      [ 'bin/perl-tool', 'lib/Finder/Test.pm' ],
      "$label includes Perl executables but excludes Bash executables",
    );
  }
};

done_testing;
