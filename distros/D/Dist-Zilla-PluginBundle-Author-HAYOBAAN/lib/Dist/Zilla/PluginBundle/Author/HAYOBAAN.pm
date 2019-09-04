package Dist::Zilla::PluginBundle::Author::HAYOBAAN;
use 5.010;                      # For // operator
use strict;
use warnings;

# ABSTRACT: Hayo Baan's Dist::Zilla configuration
our $VERSION = '0.014'; # VERSION

#pod =head1 DESCRIPTION
#pod
#pod This is a L<Dist::Zilla> PluginBundle. It installs and configures
#pod L<Dist::Zilla> plugins according to HAYOBAAN's preferences. The
#pod following plugins are (conditionally) installed and configured:
#pod
#pod =for :list
#pod * L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>
#pod * L<Author::HAYOBAAN::NextVersion|Dist::Zilla::Plugin::Author::HAYOBAAN::NextVersion>
#pod * L<OurPkgVersion|Dist::Zilla::Plugin::OurPkgVersion>
#pod * L<GatherDir|Dist::Zilla::Plugin::GatherDir>
#pod * L<Git::GatherDir|Dist::Zilla::Plugin::Git::GatherDir>
#pod * L<PruneCruft|Dist::Zilla::Plugin::PruneCruft>
#pod * L<ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>
#pod * L<PodWeaver|Dist::Zilla::Plugin::PodWeaver> (and L<SurgicalPodWeaver|Dist::Zilla::Plugin::SurgicalPodWeaver> when enabled)
#pod * L<ReadmeAnyFromPod|Dist::Zilla::Plugin::ReadmeAnyFromPod> (both Text and Markdown generation are configured)
#pod * L<Dist::Zilla::Plugin::MetaYAML>
#pod * L<License|Dist::Zilla::Plugin::License>
#pod * L<InstallGuide|Dist::Zilla::Plugin::InstallGuide>
#pod * L<MinimumPerl|Dist::Zilla::Plugin::MinimumPerl>
#pod * L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>
#pod * L<MetaNoIndex|Dist::Zilla::Plugin::MetaNoIndex>
#pod * L<GitHub::Meta|Dist::Zilla::Plugin::GitHub::Meta>
#pod * L<MetaJSON|Dist::Zilla::Plugin::MetaJSON>
#pod * L<MetaYAML|Dist::Zilla::Plugin::MetaYAML>
#pod * L<MetaProvides::Package|Dist::Zilla::Plugin::MetaProvides::Package>
#pod * L<MetaProvides::Class|Dist::Zilla::Plugin::MetaProvides::Class>
#pod * L<ExecDir|Dist::Zilla::Plugin::ExecDir>
#pod * L<ShareDir|Dist::Zilla::Plugin::ShareDir>
#pod * L<MakeMaker|Dist::Zilla::Plugin::MakeMaker> (default)
#pod * L<ModuleBuild|Dist::Zilla::Plugin::ModuleBuild> (optional)
#pod * L<Manifest|Dist::Zilla::Plugin::Manifest>
#pod * L<CopyFilesFromBuild|Dist::Zilla::Plugin::CopyFilesFromBuild>
#pod * L<Run::AfterBuild|Dist::Zilla::Plugin::Run::AfterBuild>
#pod * L<GitHubREADME::Badge|Dist::Zilla::Plugin::GitHubREADME::Badge>
#pod * L<CheckChangesHasContent|Dist::Zilla::Plugin::CheckChangesHasContent>
#pod * L<Git::CheckFor::CorrectBranch|Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch>
#pod * L<Git::Check|Dist::Zilla::Plugin::Git::Check>
#pod * L<CheckMetaResources|Dist::Zilla::Plugin::CheckMetaResources>
#pod * L<CheckPrereqsIndexed|Dist::Zilla::Plugin::CheckPrereqsIndexed>
#pod * L<Test::Compile|Dist::Zilla::Plugin::Test::Compile>
#pod * L<Test::Perl::Critic|Dist::Zilla::Plugin::Test::Perl::Critic>
#pod * L<Test::EOL|Dist::Zilla::Plugin::Test::EOL>
#pod * L<Test::NoTabs|Dist::Zilla::Plugin::Test::NoTabs>
#pod * L<Test::Version|Dist::Zilla::Plugin::Test::Version>
#pod * L<Test::MinimumVersion|Dist::Zilla::Plugin::Test::MinimumVersion>
#pod * L<MojibakeTests|Dist::Zilla::Plugin::MojibakeTests>
#pod * L<Test::Kwalitee|Dist::Zilla::Plugin::Test::Kwalitee>
#pod * L<Test::Portability|Dist::Zilla::Plugin::Test::Portability>
#pod * L<Test::UnusedVars|Dist::Zilla::Plugin::Test::UnusedVars>
#pod * L<Test::CPAN::Changes|Dist::Zilla::Plugin::Test::CPAN::Changes>
#pod * L<Test::DistManifest|Dist::Zilla::Plugin::Test::DistManifest>
#pod * L<Test::CPAN::Meta::JSON|Dist::Zilla::Plugin::Test::CPAN::Meta::JSON>
#pod * L<MetaTests|Dist::Zilla::Plugin::MetaTests>
#pod * L<PodSyntaxTests|Dist::Zilla::Plugin::PodSyntaxTests>
#pod * L<PodCoverageTests|Dist::Zilla::Plugin::PodCoverageTests>
#pod * L<Author::HAYOBAAN::LinkCheck|Dist::Zilla::Plugin::Author::HAYOBAAN::LinkCheck>
#pod * L<Test::Synopsis|Dist::Zilla::Plugin::Test::Synopsis>
#pod * L<TestRelease|Dist::Zilla::Plugin::TestRelease>
#pod * L<RunExtraTests|Dist::Zilla::Plugin::RunExtraTests>
#pod * L<ConfirmRelease|Dist::Zilla::Plugin::ConfirmRelease>
#pod * L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>
#pod * L<FakeRelease|Dist::Zilla::Plugin::FakeRelease>
#pod * L<NextRelease|Dist::Zilla::Plugin::NextRelease>
#pod * L<Git::Commit|Dist::Zilla::Plugin::Git::Commit>
#pod * L<Git::Tag|Dist::Zilla::Plugin::Git::Tag>
#pod * L<Git::Push|Dist::Zilla::Plugin::Git::Push>
#pod * L<GitHub::Update|Dist::Zilla::Plugin::GitHub::Update>
#pod * L<Run::AfterRelease|Dist::Zilla::Plugin::Run::AfterRelease>
#pod * L<Clean|Dist::Zilla::Plugin::Clean>
#pod
#pod =head1 USAGE
#pod
#pod   # In dist.ini
#pod   [@Author::HAYOBAAN]
#pod
#pod =head1 OPTIONS
#pod
#pod The following additional command-line option is available for the C<dzil> command.
#pod
#pod =head2 --local-release-only
#pod
#pod Adding this option to the C<dzil> command will set the
#pod L</local_release_only> attribute to I<true>.
#pod
#pod C<--local>, C<--local-only>, and C<--local-release> are synonyms for
#pod this option.
#pod
#pod =head2 --make-minor-release
#pod
#pod Adding this option to the C<dzil> command will set the
#pod L</make_minor_release> attribute to I<true>.
#pod
#pod C<--minor>, C<--minor-release>, and C<--make-minor> are synonyms for
#pod this option.
#pod
#pod Note: Implied with L</--local-release-only>, overriden by L</--make-major-release>.
#pod
#pod =head2 --make-major-release
#pod
#pod Adding this option to the C<dzil> command will set the
#pod L</make_major_release> attribute to true.
#pod
#pod C<--major>, C<--major-release>, and C<--make-major> are synonyms for
#pod this option.
#pod
#pod Note: Overrides L<--make-minor-release>.
#pod
#pod =head2 --keep-version
#pod
#pod Adding this option will force keep the version number the same (regardless of the other settings above!).
#pod
#pod C<--keep> is a synonym for this option.
#pod
#pod =head1 CREDITS
#pod
#pod I took inspiration from many people's L<Dist::Zilla> and L<Pod::Weaver> PluginBundles. Most notably from:
#pod
#pod =for :list
#pod * David Golden L<DAGOLDEN|Dist::Zilla::PluginBundle::DAGOLDEN>
#pod * Mike Doherty L<DOHERTY|Dist::Zilla::PluginBundle::Author::DOHERTY>
#pod
#pod =cut

use Getopt::Long;

use Moose 0.99;
use namespace::autoclean 0.09;
use Dist::Zilla 5.014; # default_jobs
with 'Dist::Zilla::Role::PluginBundle::Easy';

# Required non-core Dist::Zilla plugins:
require Dist::Zilla::Plugin::OurPkgVersion;
require Dist::Zilla::Plugin::Git::GatherDir;
require Dist::Zilla::Plugin::PodWeaver; # And Dist::Zilla::Plugin::SurgicalPodWeaver if enabled
use     Dist::Zilla::Plugin::ReadmeAnyFromPod 0.161150;
require Dist::Zilla::Plugin::MetaYAML;
require Dist::Zilla::Plugin::InstallGuide;
require Dist::Zilla::Plugin::MinimumPerl;
require Dist::Zilla::Plugin::GitHub::Meta;
require Dist::Zilla::Plugin::MetaProvides::Package;
require Dist::Zilla::Plugin::MetaProvides::Class;
require Dist::Zilla::Plugin::CopyFilesFromBuild;
require Dist::Zilla::Plugin::Run;
require Dist::Zilla::Plugin::GitHubREADME::Badge;
require Dist::Zilla::Plugin::CheckChangesHasContent;
require Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch;
require Dist::Zilla::Plugin::Git::Check;
require Dist::Zilla::Plugin::CheckMetaResources;
require Dist::Zilla::Plugin::CheckPrereqsIndexed;
require Dist::Zilla::Plugin::Test::Compile;
require Dist::Zilla::Plugin::Test::Perl::Critic;
require Test::Perl::Critic;
require Dist::Zilla::Plugin::Test::EOL;
require Dist::Zilla::Plugin::Test::NoTabs;
require Dist::Zilla::Plugin::Test::Version;
require Dist::Zilla::Plugin::Test::MinimumVersion;
require Dist::Zilla::Plugin::MojibakeTests;
require Dist::Zilla::Plugin::Test::Kwalitee;
require Dist::Zilla::Plugin::Test::Portability;
require Dist::Zilla::Plugin::Test::UnusedVars;
require Dist::Zilla::Plugin::Test::CPAN::Changes;
require Dist::Zilla::Plugin::Test::DistManifest;
require Dist::Zilla::Plugin::Test::CPAN::Meta::JSON;
require Test::CPAN::Meta::JSON;
require Test::CPAN::Meta;
require Test::Pod::Coverage;
require Pod::Coverage::TrustPod;
require Dist::Zilla::Plugin::Author::HAYOBAAN::LinkCheck;
require Pod::Weaver::PluginBundle::Author::HAYOBAAN;
require Pod::Weaver::Section::Author::HAYOBAAN::Bugs;
require Dist::Zilla::Plugin::Test::Synopsis;
require Dist::Zilla::Plugin::RunExtraTests;
require Dist::Zilla::Plugin::Git::Commit;
require Dist::Zilla::Plugin::Git::Tag;
require Dist::Zilla::Plugin::Git::Push;
require Dist::Zilla::Plugin::GitHub::Update;
require Dist::Zilla::Plugin::Clean;

sub mvp_multivalue_args { return qw(git_remote run_after_build run_after_release additional_test disable_test) }

sub mvp_aliases {
    return {
        local         => "local_release_only",
        local_only    => "local_release_only",
        local_release => "local_release_only",
        minor         => "make_minor_release",
        minor_relase  => "make_minor_release",
        make_minor    => "make_minor_release",
        major         => "make_major_release",
        major_relase  => "make_major_release",
        make_major    => "make_major_release",
    }
}

#pod =for Pod::Coverage mvp_multivalue_args mvp_aliases
#pod
#pod =attr is_cpan
#pod
#pod Specifies that this is a distribution that is destined for CPAN. When
#pod true, releases are uploaded to CPAN using
#pod L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>. If false, releases
#pod are made using L<FakeRelease|Dist::Zilla::Plugin::FakeRelease>.
#pod
#pod Default: I<false>.
#pod
#pod =cut

has is_cpan => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{is_cpan} },
);

#pod =attr is_github_hosted
#pod
#pod Specifies that the distribution's repository is hosted on GitHub.
#pod
#pod Default: I<false> (note: setting L</is_cpan> enforces L</is_github_hosted>
#pod to I<true>)
#pod
#pod =cut

has is_github_hosted => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{is_github} || $_[0]->is_cpan },
);

#pod =attr git_remote
#pod
#pod Specifies where to push the distribution on GitHub. Can be used
#pod multiple times to upload to multiple branches.
#pod
#pod Default: C<origin>
#pod
#pod =cut

has git_remote => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { $_[0]->payload->{git_remote} // [ 'origin' ] },
);

#pod =attr no_git
#pod
#pod Specifies that the distribution is not under git version control.
#pod
#pod Default: I<false> (note: setting L</is_github_hosted> enforces this
#pod setting to I<false>)
#pod
#pod =cut

has no_git => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{no_git} && !$_[0]->is_github_hosted },
);

#pod =attr local_release_only
#pod
#pod Setting this to I<true> will:
#pod
#pod =for :list
#pod * inhibit uploading to CPAN,
#pod * inhibit git checking, tagging, commiting, and pushing,
#pod * inhibit checking the F<Changes> file,
#pod * include a minor version number (e.g., C<_001>) in the version string (see L</make_minor_release>).
#pod
#pod When releasing, the L</run_after_release> code is still run so you can
#pod use this flag to I<release> a development version locally for further
#pod use or testing, without e.g., fixing a new major version number.
#pod
#pod C<local>, C<local_only>, and C<local_release> are synonyms for
#pod this setting.
#pod
#pod Default: I<false>
#pod
#pod =cut

has local_release_only => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{local_release_only} }
);

#pod =attr make_minor_release
#pod
#pod If the version string does not yet have a minor release number, this will add one with the value of C<_001>.
#pod
#pod C<minor>, C<minor_release>, and C<make_minor> are synonyms for this
#pod setting.
#pod
#pod Default: value of L</local_release_only>
#pod
#pod Note: Overridden by L</make_major_release>.
#pod
#pod =cut

has make_minor_release => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { exists $_[0]->payload->{make_minor_release} ? $_[0]->payload->{make_minor_release} : $_[0]->local_release_only }
);

#pod =attr make_major_release
#pod
#pod Removes any minor version from the version string.
#pod
#pod C<major>, C<major_release>, and C<make_major> are synonyms for this
#pod setting.
#pod
#pod Default: I<false>
#pod
#pod Note: Overrides L</make_minor_release>.
#pod
#pod =cut

has make_major_release => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{make_major_release} }
);

#pod =attr keep_version
#pod
#pod Will keep the current version number the same when building/releasing.
#pod
#pod =cut

has keep_version => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{keep_version} }
);

#pod =attr use_makemaker
#pod
#pod Uses MakeMaker as build method.
#pod
#pod Default: I<true>
#pod
#pod Note: When both C<use_makemaker> and C<use_modulebuild> are I<false>, MakeMaker will be used!
#pod
#pod =cut

has use_makemaker => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { ($_[0]->payload->{use_makemaker} // 1) || !$_[0]->payload->{use_modulebuild} }
);

#pod =attr use_modulebuild
#pod
#pod Uses L<Module::Build> as build method.
#pod
#pod Default: I<false>
#pod
#pod =cut

has use_modulebuild => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{use_modulebuild} }
);

#pod =attr run_after_build
#pod
#pod Specifies commands to run after the release has been built (but not yet released). Multiple
#pod L</run_after_build> commands can be specified.
#pod
#pod The commands are run from the root of your development tree and has the following special symbols available:
#pod
#pod =for :list
#pod * C<%d> the directory in which the distribution was built
#pod * C<%n> the name of the distribution
#pod * C<%p> path separator ('/' on Unix, '\\' on Win32... useful for cross-platform dist.ini files)
#pod * C<%v> the version of the distribution
#pod * C<%t> -TRIAL if the release is a trial release, otherwise the empty string
#pod * C<%x> full path to the current perl interpreter (like $^X but from Config)
#pod
#pod Default: I<nothing>
#pod
#pod =cut

has run_after_build => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { $_[0]->payload->{run_after_build} // [] },
);

#pod =attr run_after_release
#pod
#pod Specifies commands to run after the release has been made. Use it to e.g.,
#pod automatically install your distibution after releasing. Multiple
#pod run_after_release commands can be specified.
#pod
#pod The commands are run from the root of your development tree and has
#pod the same symbols available as the L</run_after_build>, plus the
#pod following:
#pod
#pod =for :list
#pod * C<%a> the archive of the release
#pod
#pod Default: C<cpanm './%d'>
#pod
#pod =head3 Examples:
#pod
#pod To install using cpanm (this is the default):
#pod
#pod   run_after_release = cpanm './%d'
#pod
#pod To install using cpan:
#pod
#pod   run_after_release = %x -MCPAN -einstall './%d'
#pod
#pod To not do anything:
#pod
#pod   run_after_release =
#pod
#pod =cut

has run_after_release => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { exists $_[0]->payload->{run_after_release} ? $_[0]->payload->{run_after_release} : [ 'cpanm ./%d' ] },
);

#pod =attr additional_test
#pod
#pod Additional test plugin to use. Can be used multiple times to add more
#pod than one additional test.
#pod
#pod By default the following tests are executed:
#pod
#pod =for :list
#pod * L<Test::Compile|Dist::Zilla::Plugin::Test::Compile> -- Checks if perl code compiles correctly
#pod * L<Test::Perl::Critic|Dist::Zilla::Plugin::Test::Perl::Critic> -- Checks Perl source code for best-practices
#pod * L<Test::EOL|Dist::Zilla::Plugin::Test::EOL> -- Checks line endings
#pod * L<Test::NoTabs|Dist::Zilla::Plugin::Test::NoTabs> -- Checks for the use of tabs
#pod * L<Test::Version|Dist::Zilla::Plugin::Test::Version> -- Checks to see if each module has the correct version set
#pod * L<Test::MinimumVersion|Dist::Zilla::Plugin::Test::MinimumVersion> -- Checks the minimum perl version, using L</max_target_perl>
#pod * L<MojibakeTests|Dist::Zilla::Plugin::MojibakeTests> -- Checks source encoding
#pod * L<Test::Kwalitee|Dist::Zilla::Plugin::Test::Kwalitee> -- Checks the Kwalitee
#pod * L<Test::Portability|Dist::Zilla::Plugin::Test::Portability> -- Checks portability of code
#pod * L<Test::UnusedVars|Dist::Zilla::Plugin::Test::UnusedVars> -- Checks for unused variables
#pod * L<Test::CPAN::Changes|Dist::Zilla::Plugin::Test::CPAN::Changes> -- Validation of the Changes file
#pod * L<Test::DistManifest|Dist::Zilla::Plugin::Test::DistManifest> -- Validation of the MANIFEST file
#pod * L<Test::CPAN::Meta::JSON|Dist::Zilla::Plugin::Test::CPAN::Meta::JSON> -- Validation of the META.json file -- only when hosted on GitHub
#pod * L<MetaTests|Dist::Zilla::Plugin::MetaTests> -- Validation of the META.yml file -- only when hosted on GitHub
#pod * L<PodSyntaxTests|Dist::Zilla::Plugin::PodSyntaxTests> -- Checks pod syntax
#pod * L<PodCoverageTests|Dist::Zilla::Plugin::PodCoverageTests> -- Checks pod coverage
#pod * L<LinkCheck|Dist::Zilla::Plugin::Author::HAYOBAAN::LinkCheck> -- Checks pod links
#pod * L<Test::Synopsis|Dist::Zilla::Plugin::Test::Synopsis> -- Checks the pod synopsis
#pod
#pod =cut

has additional_test => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { $_[0]->payload->{additional_test} // [] },
);

#pod =attr disable_test
#pod
#pod Specifies the test you don't want to be run. Can bu used more than
#pod once to disable multiple tests.
#pod
#pod Default: I<none> (i.e., run all default and L</additional_test> tests).
#pod
#pod =cut

has disable_test => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { $_[0]->payload->{disable_test} // [] },
);

#pod =attr max_target_perl
#pod
#pod Defines the highest minimum version of perl you intend to require.
#pod This is passed to L<Test::MinimumVersion|Dist::Zilla::Plugin::Test::MinimumVersion>, which generates
#pod a F<minimum-version.t> test that'll warn you if you accidentally used features
#pod from a higher version of perl than you wanted. (Having a lower required version
#pod of perl is okay.)
#pod
#pod Default: C<5.006>
#pod
#pod =cut

has max_target_perl => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{max_target_perl} // '5.006' },
);

#pod =attr surgical
#pod
#pod If this is set to I<true>,
#pod L<SurgicalPodWeaver|Dist::Zilla::Plugin::SurgicalPodWeaver> is used
#pod instead of the standard L<PodWeaver|Dist::Zilla::Plugin::PodWeaver>
#pod plugin. L<SurgicalPodWeaver|Dist::Zilla::Plugin::SurgicalPodWeaver>
#pod only munges files that contain either a C<# ABSTRACT> or a C<#
#pod Dist::Zilla: +PodWeaver> line.
#pod
#pod Default: I<false>
#pod
#pod =cut

has surgicalpod => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{surgicalpod} // 0 },
);

#pod =attr weaver_config
#pod
#pod Specifies the configuration for L<Pod::Weaver>.
#pod
#pod Default: C<@Author::HAYOBAAN>.
#pod
#pod =cut

has weaver_config => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{weaver_config} // '@Author::HAYOBAAN' },
);

#pod =attr tag_format
#pod
#pod Specifies the format for tagging a release (see
#pod L<Git::Tag|Dist::Zilla::Plugin::Git::Tag> for details).
#pod
#pod Default: C<v%v%t>
#pod
#pod =cut

has tag_format => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{tag_format} // 'v%v%t' },
);

#pod =attr version_regexp
#pod
#pod Specifies the regexp for versions (see
#pod L<Git::NextVersion|Dist::Zilla::Plugin::Git::NextVersion> for details).
#pod
#pod Default: C<^v?([\d.]+(?:_\d+)?)(?:-TRIAL)?$>
#pod
#pod Note: Only used in case of git version controlled repositories
#pod (L<AutoVersion|Dist::Zilla::Plugin::AutoVersion> is used in case of
#pod non-git version controlled repositories).
#pod
#pod =cut

has version_regexp => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{version_regexp} // '^v?([\d.]+(?:_\d+)?)(?:-TRIAL)?$' },
);

################################################################################

# List of files to copy to the root after they were built.
has copy_build_files => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [ ($_[0]->use_modulebuild ? qw(Build.PL) : ()),
                       ($_[0]->use_makemaker ? qw(Makefile.PL) : ()),
                       qw(README README.mkdn) ] },
);

# Files to exclude from gatherer
has exclude_files => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [
        @{$_[0]->copy_build_files},
        qw(MANIFEST),
    ] },
);

# Files that can be "dirty"
has allow_dirty => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [
        @{$_[0]->copy_build_files},
        qw(dist.ini Changes),
    ] },
);

# Directories that should not be indexed
has meta_no_index_dirs => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [ qw(corpus) ] },
);

sub _is_disabled {
    my $self = shift;
    my $plugin = shift;
    return grep { $_ eq $plugin } @{$self->disable_test}
}

# Helper function to add a test, checks for disabled tests
sub _add_test {
    my $self = shift;
    return grep { ! $self->_is_disabled(ref $_ ? $_->[0] : $_) } @_;
}

#pod =for Pod::Coverage configure
#pod
#pod =cut

sub configure {
    my $self = shift;

    {
        # Command-line argument processing

        # Local-relase-only
        my $local;
        GetOptions('local|local-only|local-release|local-release-only!' => \$local);
        $self->local_release_only($local) if defined $local;

        # Make-minor-release
        my $minor;
        GetOptions('minor|minor-relase|make-minor|make-minor-release!' => \$minor);
        $self->make_minor_release($minor) if defined $minor;

        # Make-major-release
        my $major;
        GetOptions('major|major-relase|make-major|make-major-release!' => \$major);
        $self->make_major_release($major) if defined $major;

        # Keep-version
        my $keep;
        GetOptions('keep|keep-version!' => \$keep);
        $self->keep_version($keep) if defined $keep;
    }

    return $self->add_plugins(
        #### Version ####
        $self->no_git ? (
            # Provide automatic version based on date
            'AutoVersion'
        ) : (
            # Provide a version number by bumping the last git release tag
            [
                'Author::HAYOBAAN::NextVersion' => {
                    first_version         => '0.001',                    # First version = 0.001
                    version_by_branch     => 0,                          # Set to 1 if doing maintenance branch
                    version_regexp        => $self->version_regexp,      # Regexp for version format
                    include_minor_version => $self->make_minor_release,  # Minor release?
                    remove_minor_version  => $self->make_major_release,  # Force major release?
                    keep_version          => $self->keep_version,        # Keep release number?
                },
            ],
        ),

        # Adds version to file (no line insertion, using our)
        'OurPkgVersion',

        #### Gather & Prune ####
        # Gather files to include
        [ $self->no_git ? 'GatherDir' : 'Git::GatherDir' => { exclude_filename => $self->exclude_files } ],
        # Remove cruft
        'PruneCruft',
        # Skip files in MANIFEST.SKIP
        'ManifestSkip',

        #### PodWeaver ####
        # Automatically extends POD
        [
            ($self->surgicalpod ? 'SurgicalPodWeaver' : 'PodWeaver') => {
                config_plugin      => $self->weaver_config,
                replacer           => 'replace_with_comment',
                post_code_replacer => 'replace_with_nothing',
            }
        ],

        #### Distribution Files & Metadata ####
        # Create README and README.mkdn from POD
        [ 'ReadmeAnyFromPod', 'Text' ],
        [ 'ReadmeAnyFromPod', 'Markdown' ],

        $self->is_github_hosted ? (
            # Create a LICENSE file
            'License',
            # Create an INSTALL file
            'InstallGuide',
        ) : (),

        # Automatically determine minimum perl version
        'MinimumPerl',
        # Automatically determine prerequisites
        'AutoPrereqs',

        # Do not index certain dirs",
        [ 'MetaNoIndex' => { dir => $self->meta_no_index_dirs } ],

        $self->is_github_hosted ? (
            # Add GitHub metadata",
            'GitHub::Meta',
            # Add META.json",
            'MetaJSON',
            # Add META.yml",
            'MetaYAML',
            # Add provided Packages to META.*",
            'MetaProvides::Package',
            # Add provided Classes to META.*",
            'MetaProvides::Class',
        ) : (),

        #### Build System ####
        # Install content of bin directory as executables
        'ExecDir',
        # Install content of share directory as sharedir
        'ShareDir',
        $self->use_makemaker ? (
            # Build a Makefile.PL that uses ExtUtils::MakeMaker
            [ 'MakeMaker', { default_jobs => 9 } ],
        ) : (),
        $self->use_modulebuild ? (
            # Build a Build.PL that uses Module::Build
            'ModuleBuild',
        ) : (),

        # Add Manifest
        'Manifest',

        #### After Build ####
        # Copy/move specific files after building them
        [ 'CopyFilesFromBuild' => { copy => $self->copy_build_files } ],

        @{$self->run_after_build} ? (
            # Run specified commands
            [ 'Run::AfterBuild' => { run => $self->run_after_build } ],
        ) : (),

        $self->is_github_hosted && $self->is_cpan ? (
            # Add status badges to README.mkdn
            [ 'GitHubREADME::Badge' => { ':version' => '0.16', badges => [ qw(travis cpants) ] } ],
        ) : (),

        #### Before Release Tests ####
        !$self->local_release_only ? (
            # Check if Changes file has content
            'CheckChangesHasContent',
        ) : (),

        !$self->no_git && !$self->local_release_only ? (
            # Check if we're on the correct git branch
            'Git::CheckFor::CorrectBranch',
            # Check git repository for uncommitted files before releasing
            [ 'Git::Check' => { allow_dirty => $self->allow_dirty } ],
            $self->is_cpan ? (
                # Check resources section of meta files
                'CheckMetaResources',
                # Check if prereqs are available on CPAN
                'CheckPrereqsIndexed',
            ) : (),
        ) : (),

        # Extra test (gatherdir)
        # Checks if perl code compiles correctly
        $self->_add_test('Test::Compile'),

        # Extra tests (author)
        # Checks Perl source code for best-practices
        $self->_add_test('Test::Perl::Critic'),
        # Checks line endings
        $self->_add_test('Test::EOL'),
        # Checks for the use of tabs
        $self->_add_test('Test::NoTabs'),

        # Extra tests (release)
        # Checks to see if each module has the correct version set
        $self->_add_test('Test::Version'),
        # Checks the minimum perl version
        $self->_add_test([ 'Test::MinimumVersion' => { max_target_perl => $self->max_target_perl } ]),
        # Checks source encoding
        $self->_add_test('MojibakeTests'),
        # Checks the Kwalitee
        $self->_add_test([ 'Test::Kwalitee' => { $self->is_github_hosted ? () : (skiptest => [ qw(has_meta_yml) ]) } ]),
        # Checks portability of code
        $self->_add_test('Test::Portability'),
        # Checks for unused variables
        $self->_add_test('Test::UnusedVars'),
        !$self->local_release_only ? (
            # Validation of the Changes file
            $self->_add_test('Test::CPAN::Changes'),
        ) : (),
        # Validation of the MANIFEST file
        $self->_add_test('Test::DistManifest'),

        $self->is_github_hosted ? (
            # Validation of the META.json file
            $self->_add_test('Test::CPAN::Meta::JSON'),
            # Validation of the META.yml file
            $self->_add_test('MetaTests'),
        ) : (),

        # Checks pod syntax
        $self->_add_test('PodSyntaxTests'),
        # Checks pod coverage
        $self->_add_test('PodCoverageTests'),
        # Checks pod links
        $self->_add_test('Author::HAYOBAAN::LinkCheck'),
        # Checks the pod synopsis
        $self->_add_test('Test::Synopsis'),

        # Add the additional tests specified
        @{$self->additional_test} ? $self->_add_test(@{$self->additional_test}) : (),

        #### Run tests ####
        # Run provided tests in /t directory before releasing
        'TestRelease',
        # Run the extra tests
        [ 'RunExtraTests' => { default_jobs => 9 } ],

        #### Release ####
        !$self->local_release_only ? (
            # Prompt for confirmation before releasing
            'ConfirmRelease',
        ) : (),
        $self->is_cpan && !$self->local_release_only ? (
            # Upload release to CPAN,
            'UploadToCPAN',
        ) : (
            # Fake release
            'FakeRelease',
        ),

        #### After release ###
        !$self->local_release_only ? (
            # Update the next release number in the changelog
            [ 'NextRelease' => { format => '%-9v %{yyyy-MM-dd}d' } ],
        ) : (),

        !$self->no_git && !$self->local_release_only ? (
            # Commit dirty files
            [ 'Git::Commit' => { allow_dirty => $self->allow_dirty } ],
            # Tag the new version
            [
                'Git::Tag' => {
                    tag_format  => $self->tag_format,
                    tag_message => 'Released ' . $self->tag_format,
                }
            ],
        ) : (),

        $self->is_github_hosted && @{$self->git_remote} && !$self->local_release_only ? (
            # Push current branch
            [ 'Git::Push', { push_to => $self->git_remote } ],
        ) : (),

        $self->is_cpan && !$self->local_release_only ? (
            # Update GitHub repository info on release
            [ 'GitHub::Update' => { metacpan => 1 } ]
        ) : (),

        @{$self->run_after_release} ? (
            # Install the release
            [ 'Run::AfterRelease' => { run => $self->run_after_release } ],
        ) : (),

        # Cleanup
        'Clean',
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::HAYOBAAN - Hayo Baan's Dist::Zilla configuration

=head1 VERSION

version 0.014

=head1 DESCRIPTION

This is a L<Dist::Zilla> PluginBundle. It installs and configures
L<Dist::Zilla> plugins according to HAYOBAAN's preferences. The
following plugins are (conditionally) installed and configured:

=over 4

=item *

L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>

=item *

L<Author::HAYOBAAN::NextVersion|Dist::Zilla::Plugin::Author::HAYOBAAN::NextVersion>

=item *

L<OurPkgVersion|Dist::Zilla::Plugin::OurPkgVersion>

=item *

L<GatherDir|Dist::Zilla::Plugin::GatherDir>

=item *

L<Git::GatherDir|Dist::Zilla::Plugin::Git::GatherDir>

=item *

L<PruneCruft|Dist::Zilla::Plugin::PruneCruft>

=item *

L<ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>

=item *

L<PodWeaver|Dist::Zilla::Plugin::PodWeaver> (and L<SurgicalPodWeaver|Dist::Zilla::Plugin::SurgicalPodWeaver> when enabled)

=item *

L<ReadmeAnyFromPod|Dist::Zilla::Plugin::ReadmeAnyFromPod> (both Text and Markdown generation are configured)

=item *

L<Dist::Zilla::Plugin::MetaYAML>

=item *

L<License|Dist::Zilla::Plugin::License>

=item *

L<InstallGuide|Dist::Zilla::Plugin::InstallGuide>

=item *

L<MinimumPerl|Dist::Zilla::Plugin::MinimumPerl>

=item *

L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>

=item *

L<MetaNoIndex|Dist::Zilla::Plugin::MetaNoIndex>

=item *

L<GitHub::Meta|Dist::Zilla::Plugin::GitHub::Meta>

=item *

L<MetaJSON|Dist::Zilla::Plugin::MetaJSON>

=item *

L<MetaYAML|Dist::Zilla::Plugin::MetaYAML>

=item *

L<MetaProvides::Package|Dist::Zilla::Plugin::MetaProvides::Package>

=item *

L<MetaProvides::Class|Dist::Zilla::Plugin::MetaProvides::Class>

=item *

L<ExecDir|Dist::Zilla::Plugin::ExecDir>

=item *

L<ShareDir|Dist::Zilla::Plugin::ShareDir>

=item *

L<MakeMaker|Dist::Zilla::Plugin::MakeMaker> (default)

=item *

L<ModuleBuild|Dist::Zilla::Plugin::ModuleBuild> (optional)

=item *

L<Manifest|Dist::Zilla::Plugin::Manifest>

=item *

L<CopyFilesFromBuild|Dist::Zilla::Plugin::CopyFilesFromBuild>

=item *

L<Run::AfterBuild|Dist::Zilla::Plugin::Run::AfterBuild>

=item *

L<GitHubREADME::Badge|Dist::Zilla::Plugin::GitHubREADME::Badge>

=item *

L<CheckChangesHasContent|Dist::Zilla::Plugin::CheckChangesHasContent>

=item *

L<Git::CheckFor::CorrectBranch|Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch>

=item *

L<Git::Check|Dist::Zilla::Plugin::Git::Check>

=item *

L<CheckMetaResources|Dist::Zilla::Plugin::CheckMetaResources>

=item *

L<CheckPrereqsIndexed|Dist::Zilla::Plugin::CheckPrereqsIndexed>

=item *

L<Test::Compile|Dist::Zilla::Plugin::Test::Compile>

=item *

L<Test::Perl::Critic|Dist::Zilla::Plugin::Test::Perl::Critic>

=item *

L<Test::EOL|Dist::Zilla::Plugin::Test::EOL>

=item *

L<Test::NoTabs|Dist::Zilla::Plugin::Test::NoTabs>

=item *

L<Test::Version|Dist::Zilla::Plugin::Test::Version>

=item *

L<Test::MinimumVersion|Dist::Zilla::Plugin::Test::MinimumVersion>

=item *

L<MojibakeTests|Dist::Zilla::Plugin::MojibakeTests>

=item *

L<Test::Kwalitee|Dist::Zilla::Plugin::Test::Kwalitee>

=item *

L<Test::Portability|Dist::Zilla::Plugin::Test::Portability>

=item *

L<Test::UnusedVars|Dist::Zilla::Plugin::Test::UnusedVars>

=item *

L<Test::CPAN::Changes|Dist::Zilla::Plugin::Test::CPAN::Changes>

=item *

L<Test::DistManifest|Dist::Zilla::Plugin::Test::DistManifest>

=item *

L<Test::CPAN::Meta::JSON|Dist::Zilla::Plugin::Test::CPAN::Meta::JSON>

=item *

L<MetaTests|Dist::Zilla::Plugin::MetaTests>

=item *

L<PodSyntaxTests|Dist::Zilla::Plugin::PodSyntaxTests>

=item *

L<PodCoverageTests|Dist::Zilla::Plugin::PodCoverageTests>

=item *

L<Author::HAYOBAAN::LinkCheck|Dist::Zilla::Plugin::Author::HAYOBAAN::LinkCheck>

=item *

L<Test::Synopsis|Dist::Zilla::Plugin::Test::Synopsis>

=item *

L<TestRelease|Dist::Zilla::Plugin::TestRelease>

=item *

L<RunExtraTests|Dist::Zilla::Plugin::RunExtraTests>

=item *

L<ConfirmRelease|Dist::Zilla::Plugin::ConfirmRelease>

=item *

L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>

=item *

L<FakeRelease|Dist::Zilla::Plugin::FakeRelease>

=item *

L<NextRelease|Dist::Zilla::Plugin::NextRelease>

=item *

L<Git::Commit|Dist::Zilla::Plugin::Git::Commit>

=item *

L<Git::Tag|Dist::Zilla::Plugin::Git::Tag>

=item *

L<Git::Push|Dist::Zilla::Plugin::Git::Push>

=item *

L<GitHub::Update|Dist::Zilla::Plugin::GitHub::Update>

=item *

L<Run::AfterRelease|Dist::Zilla::Plugin::Run::AfterRelease>

=item *

L<Clean|Dist::Zilla::Plugin::Clean>

=back

=head1 USAGE

  # In dist.ini
  [@Author::HAYOBAAN]

=head1 OPTIONS

The following additional command-line option is available for the C<dzil> command.

=head2 --local-release-only

Adding this option to the C<dzil> command will set the
L</local_release_only> attribute to I<true>.

C<--local>, C<--local-only>, and C<--local-release> are synonyms for
this option.

=head2 --make-minor-release

Adding this option to the C<dzil> command will set the
L</make_minor_release> attribute to I<true>.

C<--minor>, C<--minor-release>, and C<--make-minor> are synonyms for
this option.

Note: Implied with L</--local-release-only>, overriden by L</--make-major-release>.

=head2 --make-major-release

Adding this option to the C<dzil> command will set the
L</make_major_release> attribute to true.

C<--major>, C<--major-release>, and C<--make-major> are synonyms for
this option.

Note: Overrides L<--make-minor-release>.

=head2 --keep-version

Adding this option will force keep the version number the same (regardless of the other settings above!).

C<--keep> is a synonym for this option.

=head1 ATTRIBUTES

=head2 is_cpan

Specifies that this is a distribution that is destined for CPAN. When
true, releases are uploaded to CPAN using
L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>. If false, releases
are made using L<FakeRelease|Dist::Zilla::Plugin::FakeRelease>.

Default: I<false>.

=head2 is_github_hosted

Specifies that the distribution's repository is hosted on GitHub.

Default: I<false> (note: setting L</is_cpan> enforces L</is_github_hosted>
to I<true>)

=head2 git_remote

Specifies where to push the distribution on GitHub. Can be used
multiple times to upload to multiple branches.

Default: C<origin>

=head2 no_git

Specifies that the distribution is not under git version control.

Default: I<false> (note: setting L</is_github_hosted> enforces this
setting to I<false>)

=head2 local_release_only

Setting this to I<true> will:

=over 4

=item *

inhibit uploading to CPAN,

=item *

inhibit git checking, tagging, commiting, and pushing,

=item *

inhibit checking the F<Changes> file,

=item *

include a minor version number (e.g., C<_001>) in the version string (see L</make_minor_release>).

=back

When releasing, the L</run_after_release> code is still run so you can
use this flag to I<release> a development version locally for further
use or testing, without e.g., fixing a new major version number.

C<local>, C<local_only>, and C<local_release> are synonyms for
this setting.

Default: I<false>

=head2 make_minor_release

If the version string does not yet have a minor release number, this will add one with the value of C<_001>.

C<minor>, C<minor_release>, and C<make_minor> are synonyms for this
setting.

Default: value of L</local_release_only>

Note: Overridden by L</make_major_release>.

=head2 make_major_release

Removes any minor version from the version string.

C<major>, C<major_release>, and C<make_major> are synonyms for this
setting.

Default: I<false>

Note: Overrides L</make_minor_release>.

=head2 keep_version

Will keep the current version number the same when building/releasing.

=head2 use_makemaker

Uses MakeMaker as build method.

Default: I<true>

Note: When both C<use_makemaker> and C<use_modulebuild> are I<false>, MakeMaker will be used!

=head2 use_modulebuild

Uses L<Module::Build> as build method.

Default: I<false>

=head2 run_after_build

Specifies commands to run after the release has been built (but not yet released). Multiple
L</run_after_build> commands can be specified.

The commands are run from the root of your development tree and has the following special symbols available:

=over 4

=item *

C<%d> the directory in which the distribution was built

=item *

C<%n> the name of the distribution

=item *

C<%p> path separator ('/' on Unix, '\\' on Win32... useful for cross-platform dist.ini files)

=item *

C<%v> the version of the distribution

=item *

C<%t> -TRIAL if the release is a trial release, otherwise the empty string

=item *

C<%x> full path to the current perl interpreter (like $^X but from Config)

=back

Default: I<nothing>

=head2 run_after_release

Specifies commands to run after the release has been made. Use it to e.g.,
automatically install your distibution after releasing. Multiple
run_after_release commands can be specified.

The commands are run from the root of your development tree and has
the same symbols available as the L</run_after_build>, plus the
following:

=over 4

=item *

C<%a> the archive of the release

=back

Default: C<cpanm './%d'>

=head3 Examples:

To install using cpanm (this is the default):

  run_after_release = cpanm './%d'

To install using cpan:

  run_after_release = %x -MCPAN -einstall './%d'

To not do anything:

  run_after_release =

=head2 additional_test

Additional test plugin to use. Can be used multiple times to add more
than one additional test.

By default the following tests are executed:

=over 4

=item *

L<Test::Compile|Dist::Zilla::Plugin::Test::Compile> -- Checks if perl code compiles correctly

=item *

L<Test::Perl::Critic|Dist::Zilla::Plugin::Test::Perl::Critic> -- Checks Perl source code for best-practices

=item *

L<Test::EOL|Dist::Zilla::Plugin::Test::EOL> -- Checks line endings

=item *

L<Test::NoTabs|Dist::Zilla::Plugin::Test::NoTabs> -- Checks for the use of tabs

=item *

L<Test::Version|Dist::Zilla::Plugin::Test::Version> -- Checks to see if each module has the correct version set

=item *

L<Test::MinimumVersion|Dist::Zilla::Plugin::Test::MinimumVersion> -- Checks the minimum perl version, using L</max_target_perl>

=item *

L<MojibakeTests|Dist::Zilla::Plugin::MojibakeTests> -- Checks source encoding

=item *

L<Test::Kwalitee|Dist::Zilla::Plugin::Test::Kwalitee> -- Checks the Kwalitee

=item *

L<Test::Portability|Dist::Zilla::Plugin::Test::Portability> -- Checks portability of code

=item *

L<Test::UnusedVars|Dist::Zilla::Plugin::Test::UnusedVars> -- Checks for unused variables

=item *

L<Test::CPAN::Changes|Dist::Zilla::Plugin::Test::CPAN::Changes> -- Validation of the Changes file

=item *

L<Test::DistManifest|Dist::Zilla::Plugin::Test::DistManifest> -- Validation of the MANIFEST file

=item *

L<Test::CPAN::Meta::JSON|Dist::Zilla::Plugin::Test::CPAN::Meta::JSON> -- Validation of the META.json file -- only when hosted on GitHub

=item *

L<MetaTests|Dist::Zilla::Plugin::MetaTests> -- Validation of the META.yml file -- only when hosted on GitHub

=item *

L<PodSyntaxTests|Dist::Zilla::Plugin::PodSyntaxTests> -- Checks pod syntax

=item *

L<PodCoverageTests|Dist::Zilla::Plugin::PodCoverageTests> -- Checks pod coverage

=item *

L<LinkCheck|Dist::Zilla::Plugin::Author::HAYOBAAN::LinkCheck> -- Checks pod links

=item *

L<Test::Synopsis|Dist::Zilla::Plugin::Test::Synopsis> -- Checks the pod synopsis

=back

=head2 disable_test

Specifies the test you don't want to be run. Can bu used more than
once to disable multiple tests.

Default: I<none> (i.e., run all default and L</additional_test> tests).

=head2 max_target_perl

Defines the highest minimum version of perl you intend to require.
This is passed to L<Test::MinimumVersion|Dist::Zilla::Plugin::Test::MinimumVersion>, which generates
a F<minimum-version.t> test that'll warn you if you accidentally used features
from a higher version of perl than you wanted. (Having a lower required version
of perl is okay.)

Default: C<5.006>

=head2 surgical

If this is set to I<true>,
L<SurgicalPodWeaver|Dist::Zilla::Plugin::SurgicalPodWeaver> is used
instead of the standard L<PodWeaver|Dist::Zilla::Plugin::PodWeaver>
plugin. L<SurgicalPodWeaver|Dist::Zilla::Plugin::SurgicalPodWeaver>
only munges files that contain either a C<# ABSTRACT> or a C<#
Dist::Zilla: +PodWeaver> line.

Default: I<false>

=head2 weaver_config

Specifies the configuration for L<Pod::Weaver>.

Default: C<@Author::HAYOBAAN>.

=head2 tag_format

Specifies the format for tagging a release (see
L<Git::Tag|Dist::Zilla::Plugin::Git::Tag> for details).

Default: C<v%v%t>

=head2 version_regexp

Specifies the regexp for versions (see
L<Git::NextVersion|Dist::Zilla::Plugin::Git::NextVersion> for details).

Default: C<^v?([\d.]+(?:_\d+)?)(?:-TRIAL)?$>

Note: Only used in case of git version controlled repositories
(L<AutoVersion|Dist::Zilla::Plugin::AutoVersion> is used in case of
non-git version controlled repositories).

=for Pod::Coverage mvp_multivalue_args mvp_aliases

=for Pod::Coverage configure

=head1 BUGS

Please report any bugs or feature requests on the bugtracker
L<website|https://github.com/HayoBaan/Dist-Zilla-PluginBundle-Author-HAYOBAAN/issues>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 CREDITS

I took inspiration from many people's L<Dist::Zilla> and L<Pod::Weaver> PluginBundles. Most notably from:

=over 4

=item *

David Golden L<DAGOLDEN|Dist::Zilla::PluginBundle::DAGOLDEN>

=item *

Mike Doherty L<DOHERTY|Dist::Zilla::PluginBundle::Author::DOHERTY>

=back

=head1 AUTHOR

Hayo Baan <info@hayobaan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Hayo Baan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
