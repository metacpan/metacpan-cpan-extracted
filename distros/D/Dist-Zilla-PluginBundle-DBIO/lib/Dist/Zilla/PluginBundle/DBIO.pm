package Dist::Zilla::PluginBundle::DBIO;
# ABSTRACT: Dist::Zilla plugin bundle for DBIO distributions
our $VERSION = '0.900000';
use Moose;
use Dist::Zilla;
with 'Dist::Zilla::Role::PluginBundle::Easy';


use Dist::Zilla::PluginBundle::Basic;
use Dist::Zilla::PluginBundle::Git;
use Dist::Zilla::PluginBundle::Git::VersionManager;

has core => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{core} },
);


has heritage => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{heritage} || 0 },
);

sub configure {
  my ($self) = @_;

  # File gathering — core has extra excludes
  my @exclude_filenames = qw(
    META.yml META.json MANIFEST README LICENSE CLAUDE.md
  );
  my @exclude_match;

  if ($self->core) {
    push @exclude_filenames, qw(
      README.md Dockerfile .mailmap .dir-locals.el .gitattributes
      Features_09 TODO
    );
    push @exclude_match, qw(
      ^maint/ ^inc/ ^cover_db/ ^\.claude/ ^t/var/ docker-compose
    );
  }

  $self->add_plugins([ 'Git::GatherDir' => {
    exclude_filename => \@exclude_filenames,
    @exclude_match ? ( exclude_match => \@exclude_match ) : (),
  }]);

  $self->add_plugins('PruneCruft');

  # Metadata
  $self->add_plugins(qw(
    MetaJSON
    MetaYAML
    MetaConfig
    MetaProvides::Package
    Prereqs::FromCPANfile
  ));

  # Version — core uses VersionFromMainModule, drivers use git tags
  if ($self->core) {
    $self->add_plugins('VersionFromMainModule');
  }

  # POD — heritage uses @DBIO::Heritage which sets heritage=1 in the payload
  $self->add_plugins([
    PodWeaver => {
      config_plugin => $self->heritage ? '@DBIO::Heritage' : '@DBIO',
    }
  ]);

  # Tests
  $self->add_plugins('ExtraTests');

  # Build — core uses MakeMaker::Awesome
  if ($self->core) {
    $self->add_plugins([ 'MakeMaker::Awesome' => { eumm_version => '6.78' } ]);
    $self->add_plugins([ 'ExecDir' => { dir => 'script' } ]);
  } else {
    $self->add_plugins('MakeMaker');
  }

  # Distribution files
  $self->add_plugins(qw(
    License
    Readme
    ManifestSkip
    Manifest
  ));

  # GitHub — drivers get auto-detected GithubMeta, core adds MetaResources manually
  unless ($self->core) {
    $self->add_plugins([ 'GithubMeta' => { issues => 1 } ]);
  }

  # Git checks
  $self->add_plugins([ 'Git::Check' => {
    allow_dirty => [qw( dist.ini Changes cpanfile )],
  }]);

  $self->add_plugins([
    'Git::CheckFor::CorrectBranch' => { release_branch => 'main' },
  ]);

  # Release workflow
  if ($self->core) {
    # Core: simple git workflow, version from module
    # NextRelease replaces {{$NEXT}} in Changes with version + date
    $self->add_plugins([ 'NextRelease' => {
      format => '%-9v %{yyyy-MM-dd}d',
    }]);
    $self->add_plugins(
      'ConfirmRelease',
      'UploadToCPAN',
      [ 'Git::Commit' => { allow_dirty => [qw( dist.ini Changes cpanfile )] } ],
      [ 'Git::Tag' => { tag_format => 'v%V' } ],
      'Git::Push',
    );
  } else {
    # Drivers: version from git tags
    # @Git::VersionManager includes NextRelease
    $self->add_bundle('@Git::VersionManager' => {
      'RewriteVersion::Transitional.fallback_version_provider' => 'Git::NextVersion',
      'RewriteVersion::Transitional.global' => 1,
      'Git::NextVersion.first_version' => '0.900000',
      'Git::Tag.tag_format' => 'v%V',
      'NextRelease.format' => '%-9v %{yyyy-MM-dd}d',
    });

    $self->add_plugins(
      'ConfirmRelease',
      'UploadToCPAN',
      [ 'Git::Push' => { push_to => 'origin' } ],
    );
  }
}

__PACKAGE__->meta->make_immutable;

no Moose;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::DBIO - Dist::Zilla plugin bundle for DBIO distributions

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  # New DBIO distribution (default)
  name = DBIO-PostgreSQL-Async
  author = DBIO Authors
  license = Perl_5

  [@DBIO]

  # Distribution derived from DBIx::Class code
  name = DBIO-PostgreSQL
  author = DBIO Authors
  license = Perl_5

  [@DBIO]
  heritage = 1

  # DBIO core
  name = DBIO
  author = DBIO Authors
  license = Perl_5
  copyright_holder = DBIO Contributors
  copyright_year = 2005

  [@DBIO]
  core = 1
  heritage = 1

=head1 DESCRIPTION

Standard L<Dist::Zilla> plugin bundle for all DBIO distributions.

For drivers: no configuration needed. Version comes from git tags,
copyright is a custom dual notice in POD.

For DBIO core: set C<core = 1> to use L<Dist::Zilla::Plugin::VersionFromMainModule>
and L<Dist::Zilla::Plugin::MakeMaker::Awesome> instead. Add extra plugins
(MetaNoIndex, MetaResources) after the bundle in dist.ini.

=head1 ATTRIBUTES

=head2 core

Set to 1 for DBIO core. Changes version handling and MakeMaker.

=head2 heritage

Set to 1 for distributions derived from DBIx::Class code. Adds
DBIx::Class copyright attribution to generated POD. Default: 0.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
