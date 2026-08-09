use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

# Default: version_finder is an empty arrayref (no override -> plugins use their own defaults)
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => {},
  );

  is_deeply(
    $bundle->version_finder,
    [],
    'version_finder defaults to an empty arrayref',
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

# manual_version path without version_finder: PkgVersion stays at defaults
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { manual_version => 1 },
  );
  $bundle->configure;

  my ($pkg_version) = grep { $_->[1] eq 'Dist::Zilla::Plugin::PkgVersion' } @{ $bundle->plugins };
  ok($pkg_version, 'PkgVersion was added on manual_version path');
  ok(!exists $pkg_version->[2]{finder}, 'PkgVersion has no finder override when version_finder is unset');
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

done_testing;
