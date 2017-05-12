use 5.006;
use strict;
use warnings;

package Dist::Zilla::Util::RoleDB::Items::Core;

our $VERSION = '0.004001';

# ABSTRACT: A collection of roles that are provided by Dist::Zilla itself.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

my @items;









sub all {
  return @items if @items;
  _add_items();
  return @items;
}

sub _add_entry {
  my ( $name, $description, @extra ) = @_;
  require Dist::Zilla::Util::RoleDB::Entry;
  push @items, Dist::Zilla::Util::RoleDB::Entry->new( name => $name, description => $description, @extra );
  return;
}

sub _add_phase {
  my ( $name, $description, $phase_method, @extra ) = @_;
  require Dist::Zilla::Util::RoleDB::Entry::Phase;
  push @items,
    Dist::Zilla::Util::RoleDB::Entry::Phase->new(
    name         => $name,
    description  => $description,
    phase_method => $phase_method,
    @extra,
    );
  return;
}

sub _add_items {
  _add_phase( q[-AfterBuild]    => q[something that runs after building is mostly complete], 'after_build' );
  _add_phase( q[-AfterMint]     => q[something that runs after minting is mostly complete],  'after_mint' );
  _add_phase( q[-AfterRelease]  => q[something that runs after release is mostly complete],  'after_release' );
  _add_phase( q[-BeforeArchive] => q[something that runs before the archive file is built],  'before_archive' );
  _add_phase( q[-BeforeBuild]   => q[something that runs before building really begins],     'before_build' );
  _add_phase( q[-BeforeMint]    => q[something that runs before minting really begins],      'before_mint' );
  _add_phase( q[-BeforeRelease] => q[something that runs before release really begins],      'before_release' );
  _add_phase( q[-BuildRunner] => q[something that runs a built dists 'build' logic (like in 'dzil run/test')], 'build' );
  _add_phase( q[-EncodingProvider] => q[something that sets a files' encoding],                       'set_file_encoding' );
  _add_phase( q[-FileGatherer]     => q[something that gathers files into the distribution],          'gather_files' );
  _add_phase( q[-FileMunger]       => q[something that alters a file's destination or content],       'munge_files' );
  _add_phase( q[-FilePruner]       => q[something that removes found files from the distribution],    'prune_files' );
  _add_phase( q[-InstallTool]      => q[something that creates an install program for a dist],        'setup_installer' );
  _add_phase( q[-LicenseProvider]  => q[something that provides a license for the dist],              'provide_license' );
  _add_phase( q[-MetaProvider]     => q[something that provides metadata (for META.yml/json)],        'metadata' );
  _add_phase( q[-MintingProfile]   => q[something that can find a minting profile dir],               'profile_dir' );
  _add_phase( q[-ModuleMaker]      => q[something that injects module files into the dist],           'make_module' );
  _add_phase( q[-NameProvider]     => q[something that provides a name for the dist],                 'provide_name', );
  _add_phase( q[-PluginBundle]     => q[something that bundles a bunch of plugins],                   'bundle_config' );
  _add_phase( q[-PrereqSource]     => q[something that registers prerequisites],                      'register_prereqs' );
  _add_phase( q[-Releaser]         => q[something that makes a release of the dist],                  'release' );
  _add_phase( q[-ShareDir]         => q[something that picks a directory to install as shared files], 'share_dir_map' );
  _add_phase( q[-TestRunner]       => q[something used as a delegating agent to 'dzil test'],         'test' );
  _add_phase( q[-VersionProvider]  => q[something that provides a version number for the dist],       'provide_version' );

  _add_entry( q[-BuildPL]                  => q[Common ground for Build.PL based builders] );
  _add_entry( q[-Chrome]                   => q[something that provides a user interface for Dist::Zilla] );
  _add_entry( q[-ConfigDumper]             => q[something that can dump its (public, simplified) configuration] );
  _add_entry( q[-ExecFiles]                => q[something that finds files to install as executables] );
  _add_entry( q[-FileFinderUser]           => q[something that uses FileFinder plugins] );
  _add_entry( q[-FileFinder]               => q[something that finds files within the distribution] );
  _add_entry( q[-FileInjector]             => q[something that can add files to the distribution] );
  _add_entry( q[-File]                     => q[something that can act like a file] );
  _add_entry( q[-MintingProfile::ShareDir] => q[something that keeps its minting profile in a sharedir] );
  _add_entry( q[-MutableFile]              => q[something that can act like a file with changeable contents] );
  _add_entry( q[-PPI]                      => q[a role for plugins which use PPI] );
  _add_entry( q[-PluginBundle::Easy]       => q[something that bundles a bunch of plugins easily] );
  _add_entry( q[-Plugin]                   => q[something that gets plugged in to Dist::Zilla] );
  _add_entry( q[-Stash::Authors]           => q[a stash that provides a list of author strings] );
  _add_entry( q[-Stash::Login]             => q[a stash with username/password credentials] );
  _add_entry( q[-Stash]                    => q[something that stores options or data for later reference] );
  _add_entry( q[-StubBuild]                => q[provides an empty BUILD methods] );
  _add_entry( q[-TextTemplate]             => q[something that renders a Text::Template template string] );
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::RoleDB::Items::Core - A collection of roles that are provided by Dist::Zilla itself.

=head1 VERSION

version 0.004001

=head1 METHODS

=head2 C<all>

Returns all items in this item set, as a list

    my @entries = $class->all();.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
