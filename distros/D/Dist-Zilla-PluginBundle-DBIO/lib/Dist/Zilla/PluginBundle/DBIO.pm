package Dist::Zilla::PluginBundle::DBIO;
# ABSTRACT: Dist::Zilla plugin bundle for DBIO distributions
our $VERSION = '0.900003';
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


has share_skill => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  # Normalise to an arrayref. A direct [@DBIO] section aggregates repeated
  # keys via mvp_multivalue_args, but when the bundle is wrapped in [@Filter]
  # (the async drivers) the reader uses @Filter's multivalue list instead, so
  # a lone share_skill arrives as a plain scalar — accept both.
  default => sub {
    my $v = $_[0]->payload->{share_skill};
    return [] unless defined $v;
    return ref $v eq 'ARRAY' ? $v : [$v];
  },
);

sub mvp_multivalue_args { qw(share_skill) }


has coverage_threshold => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub { $_[0]->payload->{coverage_threshold} // 80 },
);

sub configure {
  my ($self) = @_;

  # Set author and copyright_holder via an inner BeforeBuild plugin — bundles have no $self->zilla
  my $author = $self->heritage ? 'DBIO & DBIx::Class Authors' : 'DBIO Authors';
  my $holder = $self->copyright_holder // $author;
  $self->add_plugins([ 'DBIO::SetMeta' => { author => $author, holder => $holder } ]);

  # LICENSE is always committed in the repo and gathered from git.
  my @exclude_filenames = qw(
    META.yml META.json MANIFEST README CLAUDE.md .proverc
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

  # Ship this dist's own agent skills as a sharedir (see DBIO::Skills).
  # Authored under .claude/skills/, copied into share/skills/ at build time.
  $self->add_plugins([ 'DBIO::GatherSkills' =>
    @{ $self->share_skill } ? { skill => $self->share_skill } : {} ]);
  $self->add_plugins('ShareDir');

  # Metadata
  $self->add_plugins(qw(
    MetaJSON
    MetaYAML
    MetaConfig
    MetaProvides::Package
    Prereqs::FromCPANfile
  ));

  # Version — core uses VersionFromMainModule, drivers use @Git::VersionManager
  if ($self->core) {
    $self->add_plugins('VersionFromMainModule');
  } else {
    $self->add_bundle('@Git::VersionManager' => {
      'RewriteVersion::Transitional.global' => 0,
      'RewriteVersion::Transitional.finder' => [':MainModule'],
      'BumpVersionAfterRelease.finder'      => [':MainModule'],
      'RewriteVersion::Transitional.fallback_version_provider' => 'Git::NextVersion',
      'Git::NextVersion.first_version' => '0.900000',
      'Git::Tag.tag_format' => 'v%V',
      'NextRelease.format' => '%-9v %{yyyy-MM-dd}d',
    });
  }

  # POD — heritage uses @DBIO::Heritage which adds DBIx::Class attribution
  $self->add_plugins([
    PodWeaver => {
      config_plugin => $self->heritage ? '@DBIO::Heritage' : '@DBIO',
    }
  ]);

  # Tests
  # CoverageTest must run before ExtraTests: it gathers xt/release/coverage.t
  # which ExtraTests then promotes into t/ for the release test suite.
  $self->add_plugins([ 'DBIO::CoverageTest' => {
    coverage_threshold => $self->coverage_threshold,
  }]);
  $self->add_plugins('ExtraTests');

  # Build — core uses MakeMaker::Awesome
  if ($self->core) {
    $self->add_plugins([ 'MakeMaker::Awesome' => { eumm_version => '6.78' } ]);
    $self->add_plugins([ 'ExecDir' => { dir => 'bin' } ]);
  } else {
    $self->add_plugins('MakeMaker');
  }

  $self->add_plugins(qw(
    Readme
    ManifestSkip
    Manifest
  ));

  # Repository metadata — derived offline from the git remote
  # (Codeberg/Forgejo or GitHub), no API token. Replaces [GithubMeta] and the
  # external Dist::Zilla::Plugin::Codeberg::Meta.
  $self->add_plugins([ 'DBIO::CodebergMeta' => { issues => 1 } ]);

  # IRC channel — fixed for the whole DBIO family (one source of truth), set
  # for every distribution rather than per-dist. No x_IRC_user.
  $self->add_plugins([ 'MetaResources' => { 'x_IRC' => 'irc://irc.perl.org/#dbio' } ]);

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

version 0.900003

=head1 SYNOPSIS

  # Standard DBIO driver distribution
  name = DBIO-MyDriver

  [@DBIO]

  # Distribution containing code derived from DBIx::Class
  name = DBIO-PostgreSQL

  [@DBIO]
  heritage = 1

  # DBIO core distribution
  name           = DBIO
  copyright_year = 2005

  [@DBIO]
  core     = 1
  heritage = 1

=head1 DESCRIPTION

Standard L<Dist::Zilla> plugin bundle for all DBIO distributions.

=head2 All distributions

Every distribution using C<[@DBIO]> gets an automatic code-coverage test
(F<xt/release/coverage.t>) that scores F<lib/> after a Devel::Cover run, plus:

=over 4

=item * L<Dist::Zilla::Plugin::Git::GatherDir> — gathers files from git

=item * L<Dist::Zilla::Plugin::MetaProvides::Package> + L<Dist::Zilla::Plugin::Prereqs::FromCPANfile> — metadata from cpanfile

=item * L<Dist::Zilla::Plugin::PodWeaver> — POD generation via C<@DBIO> or C<@DBIO::Heritage>

=item * L<Dist::Zilla::Plugin::ExtraTests> — moves F<xt/> tests into F<t/> for release

=item * L<Dist::Zilla::Plugin::DBIO::CoverageTest> — generates F<xt/release/coverage.t>, a coverage gate that reads F<cover_db/> after C<HARNESS_PERL_SWITCHES=-MDevel::Cover>. Default skip-with-diagnose on a missing run; C<COVERAGE_STRICT=1> or C<RELEASE=1> turns the same gap into a failure.

=item * L<Dist::Zilla::Plugin::DBIO::CodebergMeta> — repository, bugtracker and homepage META resources, derived offline from the git remote (Codeberg/Forgejo or GitHub)

=item * L<Dist::Zilla::Plugin::MetaResources> — sets the family-wide IRC channel META resource (C<x_IRC = irc://irc.perl.org/#dbio>) for every distribution; fixed, not per-dist configurable

=item * L<Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch> — enforces release from C<main>

=back

The C<LICENSE> file must be committed in the repository. It is included in
the distribution as-is. No license file is generated during the build.
Heritage distributions use the original DBIx::Class license with DBIO
attribution. Non-heritage distributions use a standard Perl_5 license.

=head2 Versioning

Version is read from the main module's C<$VERSION> via
L<Dist::Zilla::Plugin::VersionFromMainModule> (core) or via
L<Dist::Zilla::PluginBundle::Git::VersionManager> (drivers).
Only the main module carries C<$VERSION> — sub-modules are not versioned.

L<RewriteVersion::Transitional> is configured with C<global = 0> and
C<finder = [:MainModule]> so only the main module is patched on version bump.

=head2 Heritage distributions (C<heritage = 1>)

For distributions containing code derived from L<DBIx::Class>. Uses
L<Pod::Weaver::PluginBundle::DBIO::Heritage> which adds a DBIx::Class
copyright and attribution block to the generated POD. The C<copyright_holder>
defaults to C<DBIO & DBIx::Class Authors>.

=head2 Core distribution (C<core = 1>)

Uses L<Dist::Zilla::Plugin::VersionFromMainModule> (version from C<$VERSION>
in the main module) and L<Dist::Zilla::Plugin::MakeMaker::Awesome> instead
of the standard MakeMaker. Also enables L<Dist::Zilla::Plugin::ExecDir> for
F<bin/>. The release workflow uses NextRelease + Git::Commit/Tag/Push
directly rather than C<@Git::VersionManager>.

=head1 ATTRIBUTES

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

=head2 share_skill

Names of the agent skills this distribution owns (is the source of truth for).
They are shipped as a sharedir (C<share/skills/>) and exposed at runtime via
L<DBIO::Skills>. Repeatable; if omitted, the set is derived from the dist name.
See L<Dist::Zilla::Plugin::DBIO::GatherSkills>.

=head2 coverage_threshold

Statement-coverage percentage required for F<xt/release/coverage.t> to pass.
Default: 80. Set to C<0> to gather the file as a no-op skip (coverage
enforcement disabled). See L<Dist::Zilla::Plugin::DBIO::CoverageTest>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
