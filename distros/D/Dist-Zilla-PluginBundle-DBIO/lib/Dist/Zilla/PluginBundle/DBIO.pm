package Dist::Zilla::PluginBundle::DBIO;
# ABSTRACT: Dist::Zilla plugin bundle for DBIO distributions
our $VERSION = '0.900001';
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


has copyright_holder => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  lazy    => 1,
  default => sub { $_[0]->payload->{copyright_holder} },
);

sub configure {
  my ($self) = @_;

  # Set copyright_holder via an inner BeforeBuild plugin — bundles have no $self->zilla
  my $holder = $self->copyright_holder
    // ( $self->heritage ? 'DBIO & DBIx::Class Authors' : 'DBIO Authors' );
  $self->add_plugins([ 'DBIO::SetCopyrightHolder' => { holder => $holder } ]);

  # LICENSE is always committed in the repo and gathered from git.
  my @exclude_filenames = qw(
    META.yml META.json MANIFEST README CLAUDE.md
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

  # POD — heritage uses @DBIO::Heritage which adds DBIx::Class attribution
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

  $self->add_plugins(qw(
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

package Dist::Zilla::Plugin::DBIO::SetCopyrightHolder;
use Moose;
with 'Dist::Zilla::Role::Plugin', 'Dist::Zilla::Role::BeforeBuild';

has holder => (is => 'ro', isa => 'Str', required => 1);

sub before_build {
  my ($self) = @_;
  my $zilla = $self->zilla;
  my ($attr) = grep { $_->name eq '_copyright_holder' } $zilla->meta->get_all_attributes;
  $attr->set_value($zilla, $self->holder);
}

__PACKAGE__->meta->make_immutable;
no Moose;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::DBIO - Dist::Zilla plugin bundle for DBIO distributions

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  # New DBIO distribution — LICENSE committed in repo
  name = DBIO-PostgreSQL-Async
  author = DBIO Authors
  license = Perl_5

  [@DBIO]

  # Distribution derived from DBIx::Class code — LICENSE committed in repo
  name = DBIO-PostgreSQL
  author = DBIO & DBIx::Class Authors
  license = Perl_5

  [@DBIO]
  heritage = 1

  # DBIO core — copyright from 2005, explicit copyright_holder override
  name = DBIO
  author = DBIx::Class & DBIO Contributors (see AUTHORS file)
  license = Perl_5
  copyright_year = 2005

  [@DBIO]
  core = 1
  heritage = 1
  copyright_holder = DBIO Contributors

=head1 DESCRIPTION

Standard L<Dist::Zilla> plugin bundle for all DBIO distributions.

=head2 All distributions

Every distribution using C<[@DBIO]> gets:

=over 4

=item * L<Dist::Zilla::Plugin::Git::GatherDir> — gathers files from git

=item * L<Dist::Zilla::Plugin::MetaProvides::Package> + L<Dist::Zilla::Plugin::Prereqs::FromCPANfile> — metadata from cpanfile

=item * L<Dist::Zilla::Plugin::PodWeaver> — POD generation via C<@DBIO> or C<@DBIO::Heritage>

=item * L<Dist::Zilla::Plugin::ExtraTests> — moves F<xt/> tests into F<t/> for release

=item * L<Dist::Zilla::Plugin::GithubMeta> — auto-detects GitHub repository URL and issues link

=item * L<Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch> — enforces release from C<main>

=back

The C<LICENSE> file must be committed in the repository. It is included in
the distribution as-is. No license file is generated during the build.
Heritage distributions use the original DBIx::Class license with DBIO
attribution. Non-heritage distributions use a standard Perl_5 license.

=head2 Driver distributions (default)

Version is taken from git tags via L<Dist::Zilla::PluginBundle::Git::VersionManager>.
For brand-new distributions without any tags yet, the first version will be
C<0.900000>. The release workflow uses
C<@Git::VersionManager> (which includes NextRelease), followed by
L<Dist::Zilla::Plugin::ConfirmRelease>, L<Dist::Zilla::Plugin::UploadToCPAN>,
and L<Dist::Zilla::Plugin::Git::Push>.

=head2 Heritage distributions (C<heritage = 1>)

For distributions containing code derived from L<DBIx::Class>. Uses
L<Pod::Weaver::PluginBundle::DBIO::Heritage> which adds a DBIx::Class
copyright and attribution block to the generated POD. The C<copyright_holder>
defaults to C<DBIO & DBIx::Class Authors>.

=head2 Core distribution (C<core = 1>)

Uses L<Dist::Zilla::Plugin::VersionFromMainModule> (version from C<$VERSION>
in the main module) and L<Dist::Zilla::Plugin::MakeMaker::Awesome> instead
of the standard MakeMaker. Also enables L<Dist::Zilla::Plugin::ExecDir> for
F<script/>. The release workflow uses NextRelease + Git::Commit/Tag/Push
directly rather than C<@Git::VersionManager>.

=head1 ATTRIBUTES

=head2 core

Set to 1 for the DBIO core distribution. Switches to
L<Dist::Zilla::Plugin::VersionFromMainModule> for versioning,
L<Dist::Zilla::Plugin::MakeMaker::Awesome> for building, enables
L<Dist::Zilla::Plugin::ExecDir> for F<script/>, and uses a simplified
git release workflow without C<@Git::VersionManager>.

=head2 heritage

Set to 1 for distributions derived from L<DBIx::Class> code. Switches
L<Dist::Zilla::Plugin::PodWeaver> to use
L<Pod::Weaver::PluginBundle::DBIO::Heritage> instead of
L<Pod::Weaver::PluginBundle::DBIO>, which adds a DBIx::Class copyright and
attribution block to the generated POD. Also changes the default
C<copyright_holder> to C<DBIO & DBIx::Class Authors>. Default: 0.

=head2 copyright_holder

Override the copyright holder string. If not set, defaults to
C<DBIO & DBIx::Class Authors> for heritage distributions and
C<DBIO Authors> for all others.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
