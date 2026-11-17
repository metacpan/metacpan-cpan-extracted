package Dist::Zilla::PluginBundle::DBIO;
# ABSTRACT: Dist::Zilla plugin bundle for DBIO distributions
our $VERSION = '0.900007';
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


has eumm_version => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  lazy    => 1,
  default => sub { $_[0]->payload->{eumm_version} },
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

  # Version — core and drivers alike through @Git::VersionManager: every module
  # under lib/ is rewritten to the version of the dist and raised after the release
  $self->add_bundle('@Git::VersionManager' => {
    'RewriteVersion::Transitional.global' => 1,
    'RewriteVersion::Transitional.finder' => [':InstallModules'],
    'BumpVersionAfterRelease.finder'      => [':InstallModules'],
    'RewriteVersion::Transitional.fallback_version_provider' => 'Git::NextVersion',
    'Git::NextVersion.first_version' => '0.900000',
    'Git::Tag.tag_format' => 'v%V',
    'NextRelease.format' => '%-9v %{yyyy-MM-dd}d',
  });

  # POD — heritage uses @DBIO::Heritage which adds DBIx::Class attribution
  $self->add_plugins([
    PodWeaver => {
      config_plugin => $self->heritage ? '@DBIO::Heritage' : '@DBIO',
    }
  ]);

  # Tests
  # ExtraTests promotes the xt/ files gathered by PodCheckerTest and
  # VersionLockstepTest into t/. The order here is only for readability:
  # munging runs after all gathering.
  # PodCheckerTest gathers xt/author/pod-checker.t, promoted the same way: a
  # Pod::Checker run over the built (woven) POD under AUTHOR_TESTING.
  $self->add_plugins('DBIO::PodCheckerTest');
  # Core only: a test fails when a module deviates from the main module's
  # $VERSION, whatever the way it got out of step.
  $self->add_plugins('DBIO::VersionLockstepTest') if $self->core;
  $self->add_plugins('ExtraTests');

  # Scripts under bin/ are installed (and woven) for every dist; without a
  # bin/ the plugin finds nothing and the build is unchanged.
  $self->add_plugins([ 'ExecDir' => { dir => 'bin' } ]);

  # Build — core uses MakeMaker::Awesome
  if ($self->core) {
    $self->add_plugins([ 'MakeMaker::Awesome' =>
      { eumm_version => defined $self->eumm_version ? $self->eumm_version : '6.78' } ]);
  } elsif (defined $self->eumm_version) {
    $self->add_plugins([ 'MakeMaker' => { eumm_version => $self->eumm_version } ]);
  } else {
    $self->add_plugins('MakeMaker');
  }

  # The coverage gate is a TestRunner: Dist::Zilla runs the TestRunners in
  # plugin order, so it stands behind the build plugin and judges cover_db/
  # when the suite of the build directory is through.
  $self->add_plugins([ 'DBIO::CoverageGate' => {
    coverage_threshold => $self->coverage_threshold,
  }]);

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
  # A driver is released against the core version it was written for: its
  # runtime prereq on DBIO must be at least its own version (core is the
  # source of that version and has no such prereq).
  my @release_checks = (
    ($self->core ? () : 'DBIO::RequireCoreVersion'),
    'TestRelease',
    'Test::ChangesHasContent',
    [ 'InstallRelease' => { install_command => 'cpanm .' } ],
  );
  # NextRelease, the release snapshot, the tag and the post-release commit
  # come from @Git::VersionManager above.
  $self->add_plugins(
    @release_checks,
    'ConfirmRelease',
    'UploadToCPAN',
    [ 'Git::Push' => { push_to => 'origin' } ],
  );
}

__PACKAGE__->meta->make_immutable;

no Moose;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::DBIO - Dist::Zilla plugin bundle for DBIO distributions

=head1 VERSION

version 0.900007

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

Every distribution using C<[@DBIO]> gets an automatic code-coverage gate that
scores F<lib/> after the whole test suite has run under Devel::Cover, plus:

=over 4

=item * L<Dist::Zilla::Plugin::Git::GatherDir> — gathers the tracked files (see L</The tarball>)

=item * L<Dist::Zilla::Plugin::DBIO::LicenseFile> — checks the committed F<LICENSE> (see L</LICENSE>)

=item * L<Dist::Zilla::Plugin::MetaProvides::Package> + L<Dist::Zilla::Plugin::Prereqs::FromCPANfile> — metadata from cpanfile

=item * L<Dist::Zilla::Plugin::PodWeaver> — POD generation via C<@DBIO> or C<@DBIO::Heritage>

=item * L<Dist::Zilla::Plugin::ExtraTests> — promotes F<xt/author/>, F<xt/release/> and F<xt/smoke/> tests into F<t/> for release; tests lying flat in F<xt/> are not promoted and are therefore not covered by the release gate

=item * L<Dist::Zilla::Plugin::DBIO::CoverageGate> — a test runner behind the build plugin that reads F<cover_db/> of the build directory once the whole suite has run (C<HARNESS_PERL_SWITCHES=-MDevel::Cover>), for C<dzil test> and C<dzil release>. It scores the F<lib/> of the dist. A score below the threshold logs a warning by default and aborts under C<COVERAGE_STRICT=1> or C<RELEASE=1>; without a measured coverage (no F<cover_db/>, no L<Devel::Cover::DB>) it aborts under C<RELEASE=1>, because a release without a coverage run is a failed release, and only logs a note otherwise.

=item * L<Dist::Zilla::Plugin::DBIO::PodCheckerTest> — generates F<xt/author/pod-checker.t>, a L<Pod::Checker> run over the built (woven) POD under F<lib/> and F<bin/>. Any Pod::Checker error — above all an unresolved internal link — fails C<dzil test> and C<dzil release>; skipped on a plain install.

=item * L<Dist::Zilla::Plugin::ExecDir> — installs the scripts under F<bin/>, and PodWeaver weaves their POD; a distribution without F<bin/> is not affected

=item * L<Dist::Zilla::Plugin::DBIO::CodebergMeta> — repository, bugtracker and homepage META resources, derived offline from the git remote (codeberg.org only; for another host or an unusable remote the build logs why and adds no resources)

=item * L<Dist::Zilla::Plugin::MetaResources> — sets the family-wide IRC channel META resource (C<x_IRC = irc://irc.perl.org/#dbio>) for every distribution; fixed, not per-dist configurable

=item * L<Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch> — enforces release from C<main>

=back

=head2 The tarball

What is tracked in git is what ships. L<Dist::Zilla::Plugin::Git::GatherDir>
gathers every tracked file, dotfiles included, for core and drivers alike;
only what the build generates itself stays out (F<META.yml>, F<META.json>,
F<MANIFEST>, F<README>, F<README.md>), plus F<.karr>; these are the six
C<exclude_filename> names, and there is no C<exclude_match>. There is no
C<PruneCruft>: a file that should not ship is not tracked.
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

Before L<Dist::Zilla::Plugin::ConfirmRelease>, for core and drivers alike (the first item is for drivers only):

=over 4

=item * L<Dist::Zilla::Plugin::DBIO::RequireCoreVersion> — every dist but core: the runtime prereq C<DBIO> in the prereqs (the F<cpanfile>) must ask for at least the version being released. A lower minimum version stops the release with a message that names both versions and the line to write (C<requires 'DBIO', 'E<lt>versionE<gt>';>). A dist without a runtime prereq on C<DBIO> has nothing to check. It changes no prereq.

=item * L<Dist::Zilla::Plugin::TestRelease> — runs the tests of the built dist and stops the release when they fail

=item * L<Dist::Zilla::Plugin::Test::ChangesHasContent> — fails when F<Changes> has no entry under C<{{$NEXT}}>

=item * L<Dist::Zilla::Plugin::InstallRelease> — installs the released dist locally with C<cpanm .>

=back

=head2 Versioning

Core and drivers version alike, through
L<Dist::Zilla::PluginBundle::Git::VersionManager>. The version is the main
module's C<$VERSION>; only when it has none does L<Git::NextVersion> take it
from the git tags (C<first_version = 0.900000>). L<RewriteVersion::Transitional> is
configured with C<global = 1> and C<finder = [:InstallModules]>, so B<every>
module under F<lib/> is versioned: each C<.pm> carries its own literal
C<$VERSION> assignment, and all of them are rewritten in lockstep at the
release. Right after the release C<BumpVersionAfterRelease> raises all of them
to the next version, so between two releases the source carries the next
version.

For C<core = 1> the bundle also adds
L<Dist::Zilla::Plugin::DBIO::VersionLockstepTest>: a test that fails when a
module under F<lib/> has no C<$VERSION> or one that differs from the main
module's. Non-core distributions do not get it.

=head2 Heritage distributions (C<heritage = 1>)

For distributions containing code derived from L<DBIx::Class>. Uses
L<Pod::Weaver::PluginBundle::DBIO::Heritage> which adds a DBIx::Class
copyright and attribution block to the generated POD. The C<copyright_holder>
defaults to C<DBIO & DBIx::Class Authors>.

=head2 Core distribution (C<core = 1>)

Uses L<Dist::Zilla::Plugin::MakeMaker::Awesome> instead of the standard
MakeMaker. Versioning and release workflow are those of the drivers
(L</Versioning>, L</Release checks>), except that core has no
L<Dist::Zilla::Plugin::DBIO::RequireCoreVersion>. It also gets
L<Dist::Zilla::Plugin::DBIO::VersionLockstepTest>.

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

=head2 eumm_version

Minimum version of L<ExtUtils::MakeMaker> the build asks for. It is written
into the C<use ExtUtils::MakeMaker> line of F<Makefile.PL> and into
C<configure_requires> of the META files. For a driver it goes to
L<Dist::Zilla::Plugin::MakeMaker>, for the core (C<core = 1>) to
L<Dist::Zilla::Plugin::MakeMaker::Awesome>. Without it a driver keeps the
default of C<MakeMaker> and the core asks for C<6.78>.

=head2 share_skill

Names of the agent skills this distribution owns (is the source of truth for).
They are shipped as a sharedir (C<share/skills/>) and exposed at runtime via
L<DBIO::Skills>. Repeatable; if omitted, the set is derived from the dist name.
See L<Dist::Zilla::Plugin::DBIO::GatherSkills>.

=head2 coverage_threshold

Statement-coverage percentage the suite run must reach. Default: 80. Set to
C<0> to switch the coverage gate off. See
L<Dist::Zilla::Plugin::DBIO::CoverageGate>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
