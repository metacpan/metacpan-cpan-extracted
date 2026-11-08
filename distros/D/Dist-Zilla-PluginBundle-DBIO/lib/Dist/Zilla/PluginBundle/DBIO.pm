package Dist::Zilla::PluginBundle::DBIO;
# ABSTRACT: Dist::Zilla plugin bundle for DBIO distributions
our $VERSION = '0.900004';
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

  # What is tracked in git ships; only build products stay out. LICENSE is a
  # committed file gathered here and checked by DBIO::LicenseFile.
  $self->add_plugins([ 'Git::GatherDir' => {
    include_dotfiles => 1,
    exclude_filename => [qw( META.yml META.json MANIFEST README README.md .karr )],
  }]);
  $self->add_plugins([ 'DBIO::LicenseFile' => { heritage => $self->heritage } ]);

  # Ship this dist's own agent skills as a sharedir (see DBIO::Skills).
  # Authored under .claude/skills/, copied into share/skills/ at build time.
  $self->add_plugins([ 'DBIO::GatherSkills' =>
    @{ $self->share_skill } ? { skill => $self->share_skill } : {} ]);
  $self->add_plugins('ShareDir');

  # Snapshot the full agent context (.claude/.codex/CLAUDE.md/...) into the build
  # under misc/agent-context/ for build provenance (not installed). This is
  # separate from GatherSkills above: GatherSkills ships only the owned dbio-*
  # skills as an installed runtime sharedir; GatherAgentContext records the whole
  # as-built context, including skilletor-installed (git-ignored) skills.
  $self->add_plugins('GatherAgentContext');

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
      'RewriteVersion::Transitional.global' => 1,
      'RewriteVersion::Transitional.finder' => [':InstallModules'],
      'BumpVersionAfterRelease.finder'      => [':InstallModules'],
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
  # ExtraTests promotes the xt/ files gathered by CoverageTest and
  # PodCheckerTest into t/. The order here is only for readability: munging
  # runs after all gathering.
  $self->add_plugins([ 'DBIO::CoverageTest' => {
    coverage_threshold => $self->coverage_threshold,
  }]);
  # PodCheckerTest gathers xt/author/pod-checker.t, promoted the same way: a
  # Pod::Checker run over the built (woven) POD under AUTHOR_TESTING.
  $self->add_plugins('DBIO::PodCheckerTest');
  # Core only: nothing rewrites the modules other than the main one, so a
  # test fails when one deviates from the main module's $VERSION (k14).
  $self->add_plugins('DBIO::VersionLockstepTest') if $self->core;
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
  # (Codeberg, or a Forgejo instance via host=), no API token. Replaces [GithubMeta] and the
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
  my @release_checks = (
    'TestRelease',
    'Test::ChangesHasContent',
    [ 'InstallRelease' => { install_command => 'cpanm .' } ],
  );
  if ($self->core) {
    $self->add_plugins([ 'NextRelease' => {
      format => '%-9v %{yyyy-MM-dd}d',
    }]);
    $self->add_plugins(
      @release_checks,
      'ConfirmRelease',
      'UploadToCPAN',
      [ 'Git::Commit' => { allow_dirty => [qw( dist.ini Changes cpanfile )] } ],
      [ 'Git::Tag' => { tag_format => 'v%V' } ],
      'Git::Push',
    );
  } else {
    $self->add_plugins(
      @release_checks,
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

version 0.900004

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

=item * L<Dist::Zilla::Plugin::Git::GatherDir> — gathers the tracked files (see L</The tarball>)

=item * L<Dist::Zilla::Plugin::DBIO::LicenseFile> — checks the committed F<LICENSE> (see L</LICENSE>)

=item * L<Dist::Zilla::Plugin::MetaProvides::Package> + L<Dist::Zilla::Plugin::Prereqs::FromCPANfile> — metadata from cpanfile

=item * L<Dist::Zilla::Plugin::PodWeaver> — POD generation via C<@DBIO> or C<@DBIO::Heritage>

=item * L<Dist::Zilla::Plugin::ExtraTests> — promotes F<xt/author/>, F<xt/release/> and F<xt/smoke/> tests into F<t/> for release; tests lying flat in F<xt/> are not promoted and are therefore not covered by the release gate

=item * L<Dist::Zilla::Plugin::DBIO::CoverageTest> — generates F<xt/release/coverage.t>, a coverage gate that reads F<cover_db/> after C<HARNESS_PERL_SWITCHES=-MDevel::Cover>. A missing F<cover_db/> skips the test, even under C<COVERAGE_STRICT=1> or C<RELEASE=1>; a score below the threshold passes with a diagnostic by default and fails under C<COVERAGE_STRICT=1> or C<RELEASE=1>.

=item * L<Dist::Zilla::Plugin::DBIO::PodCheckerTest> — generates F<xt/author/pod-checker.t>, a L<Pod::Checker> run over the built (woven) POD under F<lib/> and F<bin/>. Any Pod::Checker error — above all an unresolved internal link — fails C<dzil test> and C<dzil release>; skipped on a plain install.

=item * L<Dist::Zilla::Plugin::DBIO::CodebergMeta> — repository, bugtracker and homepage META resources, derived offline from the git remote (codeberg.org only; no resources for other hosts)

=item * L<Dist::Zilla::Plugin::MetaResources> — sets the family-wide IRC channel META resource (C<x_IRC = irc://irc.perl.org/#dbio>) for every distribution; fixed, not per-dist configurable

=item * L<Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch> — enforces release from C<main>

=back

=head2 The tarball

What is tracked in git is what ships. L<Dist::Zilla::Plugin::Git::GatherDir>
gathers every tracked file, dotfiles included, for core and drivers alike;
only what the build generates itself stays out (F<META.yml>, F<META.json>,
F<MANIFEST>, F<README>, F<README.md>), plus F<.karr>. There is no
C<PruneCruft> and no exclude list: a file that should not ship is not tracked.
Untracked files, such as the git-ignored skills skilletor installs, are never
gathered by it.

=head2 LICENSE

The F<LICENSE> file is committed in the repository and gathered like any other
tracked file; no license file is generated during the build.
L<Dist::Zilla::Plugin::DBIO::LicenseFile> then checks it and aborts the build
when it is missing or deviates. Non-heritage distributions must carry the
standard Perl_5 license text of the dist (C<dzil genlicense> writes it);
heritage distributions must carry the fixed DBIx::Class license with the DBIO
attribution preamble, which the plugin holds as its reference text.

=head2 Release checks

Before L<Dist::Zilla::Plugin::ConfirmRelease>, for core and drivers alike:

=over 4

=item * L<Dist::Zilla::Plugin::TestRelease> — runs the tests of the built dist and stops the release when they fail

=item * L<Dist::Zilla::Plugin::Test::ChangesHasContent> — fails when F<Changes> has no entry under C<{{$NEXT}}>

=item * L<Dist::Zilla::Plugin::InstallRelease> — installs the released dist locally with C<cpanm .>

=back

=head2 Versioning

Version is read from the main module's C<$VERSION> via
L<Dist::Zilla::Plugin::VersionFromMainModule> (core) or via
L<Dist::Zilla::PluginBundle::Git::VersionManager> (drivers).

For drivers, L<RewriteVersion::Transitional> is configured with C<global = 1>
and C<finder = [:InstallModules]>, so B<every> module under F<lib/> is
versioned: each C<.pm> carries its own literal C<$VERSION> assignment, and all
of them are rewritten in lockstep on version bump.

Core versions only from the main module (VersionFromMainModule) and rewrites
no other file, yet every core module carries a literal C<$VERSION>. For
C<core = 1> the bundle therefore adds
L<Dist::Zilla::Plugin::DBIO::VersionLockstepTest>: a test that fails when a
module under F<lib/> has no C<$VERSION> or one that differs from the main
module's. At a version bump the core raises every module by hand; the test
fails the build until none is left behind. Non-core distributions do not get it.

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
directly rather than C<@Git::VersionManager>. It also gets
L<Dist::Zilla::Plugin::DBIO::VersionLockstepTest> (see L</Versioning>).

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
