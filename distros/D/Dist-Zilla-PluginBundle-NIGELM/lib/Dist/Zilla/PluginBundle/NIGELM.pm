package Dist::Zilla::PluginBundle::NIGELM;

# ABSTRACT: Build your distributions like I do

use strict;
use warnings;

our $VERSION = '0.27'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose 1.00;
use Method::Signatures::Simple;
use Moose::Util::TypeConstraints;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Email qw(EmailAddress);
use MooseX::Types::Moose qw(Bool Str CodeRef);
use MooseX::Types::Structured 0.20 qw(Map Dict Optional);
use MooseX::Types::Moose qw{ ArrayRef Str };
use namespace::autoclean -also => 'lower';

# these are all the modules used, listed purely for the dep generator
use Dist::Zilla 5.033;    # force recent version of dzil
use Dist::Zilla::Plugin::Authority 1.005;
use Dist::Zilla::Plugin::AutoPrereqs;
use Dist::Zilla::Plugin::CheckChangeLog;
use Dist::Zilla::Plugin::CopyReadmeFromBuild;
use Dist::Zilla::Plugin::ExecDir;
use Dist::Zilla::Plugin::ExtraTests;
use Dist::Zilla::Plugin::FakeRelease;
use Dist::Zilla::Plugin::GatherDir;
use Dist::Zilla::Plugin::Git::Check;
use Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch;
use Dist::Zilla::Plugin::Git::CheckFor::Fixups;
use Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts;
use Dist::Zilla::Plugin::Git::Commit;
use Dist::Zilla::Plugin::Git::CommitBuild 1.110480;
use Dist::Zilla::Plugin::Git::NextVersion;
use Dist::Zilla::Plugin::Git::Push;
use Dist::Zilla::Plugin::Git::Tag;
use Dist::Zilla::Plugin::HasVersionTests;
use Dist::Zilla::Plugin::InlineFiles;
use Dist::Zilla::Plugin::InstallGuide;
use Dist::Zilla::Plugin::License;
use Dist::Zilla::Plugin::MakeMaker;
use Dist::Zilla::Plugin::Manifest;
use Dist::Zilla::Plugin::ManifestSkip;
use Dist::Zilla::Plugin::MetaConfig;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::MetaProvides::Class;
use Dist::Zilla::Plugin::MetaProvides::Package;
use Dist::Zilla::Plugin::MetaResources;
use Dist::Zilla::Plugin::MetaTests;
use Dist::Zilla::Plugin::MetaYAML;
use Dist::Zilla::Plugin::NextRelease;
use Dist::Zilla::Plugin::OurPkgVersion;
use Dist::Zilla::Plugin::PodCoverageTests;
use Dist::Zilla::Plugin::PodSyntaxTests;
use Dist::Zilla::Plugin::PodWeaver;
use Dist::Zilla::Plugin::PruneCruft;
use Dist::Zilla::Plugin::PruneFiles;
use Dist::Zilla::Plugin::ReadmeAnyFromPod;
use Dist::Zilla::Plugin::ShareDir;
use Dist::Zilla::Plugin::TaskWeaver;
use Dist::Zilla::Plugin::Test::Compile;
use Dist::Zilla::Plugin::Test::DistManifest;
use Dist::Zilla::Plugin::Test::EOL;
use Dist::Zilla::Plugin::Test::Kwalitee;
use Dist::Zilla::Plugin::Test::MinimumVersion;
use Dist::Zilla::Plugin::Test::NoTabs;
use Dist::Zilla::Plugin::Test::Perl::Critic;
use Dist::Zilla::Plugin::Test::PodSpelling;
use Dist::Zilla::Plugin::Test::Portability;
use Dist::Zilla::Plugin::Test::ReportPrereqs;
use Dist::Zilla::Plugin::Test::Synopsis;
use Dist::Zilla::Plugin::Test::UnusedVars;
use Dist::Zilla::Plugin::UploadToCPAN;
use Pod::Weaver::PluginBundle::DAGOLDEN;


has dist => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has build_process => (
    predicate => 'has_build_process',
    is        => 'ro',
    isa       => Str,
);


# if set, trigger FakeRelease instead of UploadToCPAN
has no_cpan => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $ENV{NO_CPAN} || $_[0]->payload->{no_cpan} || 0 }
);


has authority => (
    is      => 'ro',
    isa     => Str,
    default => 'cpan:NIGELM',
);


has auto_prereqs => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);


has skip_prereqs => (
    is  => 'ro',
    isa => Str,
);


has is_task => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_task',
);

method _build_is_task () {
    return $self->dist =~ /^Task-/ ? 1 : 0;
}


has weaver_config_plugin => (
    is      => 'ro',
    isa     => Str,
    default => '@DAGOLDEN',
);


has bugtracker_url => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_bugtracker_url',
    handles => { bugtracker_url => 'as_string', },
);

method _build_bugtracker_url () {
    return sprintf $self->_rt_uri_pattern, $self->dist;
}


has bugtracker_email => (
    is      => 'ro',
    isa     => EmailAddress,
    lazy    => 1,
    builder => '_build_bugtracker_email',
);

method _build_bugtracker_email () {
    return sprintf 'bug-%s@rt.cpan.org', $self->dist;
}

has _rt_uri_pattern => (
    is      => 'ro',
    isa     => Str,
    default => 'http://rt.cpan.org/Public/Dist/Display.html?Name=%s',
);


has disable_pod_coverage_tests => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has disable_pod_spelling_tests => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has disable_trailing_whitespace_tests => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has disable_unused_vars_tests => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has disable_no_tabs_tests => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has fake_home => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has homepage_url => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_homepage_url',
    handles => { homepage_url => 'as_string', },
);

method _build_homepage_url () {
    return sprintf $self->_cpansearch_pattern, $self->dist;
}

has _cpansearch_pattern => (
    is      => 'ro',
    isa     => Str,
    default => 'https://metacpan.org/release/%s',
);


has repository_at => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_repository_at',
);


has repository => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_repository_url',
    handles => {
        repository_url    => 'as_string',
        repository_scheme => 'scheme',
    },
);

sub lower { lc shift }

my $map_tc = Map [
    Str,
    Dict [
        pattern     => CodeRef,
        web_pattern => CodeRef,
        type        => Optional [Str],
        mangle      => Optional [CodeRef],
    ]
];

coerce $map_tc,
    from Map [
    Str,
    Dict [
        pattern     => Str | CodeRef,
        web_pattern => Str | CodeRef,
        type        => Optional [Str],
        mangle      => Optional [CodeRef],
    ]
    ],
    via {
    my %in = %{$_};
    return {
        map {
            my $k = $_;
            (   $k => {
                    %{ $in{$k} },
                    (   map {
                            my $v = $_;
                            (   ref $in{$k}->{$v} ne 'CODE'
                                ? ( $v => sub { $in{$k}->{$v} } )
                                : ()
                                ),
                        } qw(pattern web_pattern)
                    ),
                }
                )
        } keys %in
    };
    };

method _build__repository_host_map () {
    my $github_pattern     = sub { sprintf 'https://github.com/%s/%%s.git', $self->github_user };
    my $github_web_pattern = sub { sprintf 'https://github.com/%s/%%s',     $self->github_user };
    my $scsys_web_pattern_proto = sub {
        return sprintf 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=%s/%%s.git;a=summary', $_[0];
    };

    return {
        github => {
            type        => 'git',
            pattern     => $github_pattern,
            web_pattern => $github_web_pattern,
            mangle      => \&lower,
        },
        GitHub => {
            type        => 'git',
            pattern     => $github_pattern,
            web_pattern => $github_web_pattern,
        },
        gitmo => {
            type        => 'git',
            pattern     => 'git://git.moose.perl.org/%s.git',
            web_pattern => $scsys_web_pattern_proto->('gitmo'),
        },
        catsvn => {
            type        => 'svn',
            pattern     => 'http://dev.catalyst.perl.org/repos/Catalyst/%s/',
            web_pattern => 'http://dev.catalystframework.org/svnweb/Catalyst/browse/%s',
        },
        (   map {
                (   $_ => {
                        type        => 'git',
                        pattern     => "git://git.shadowcat.co.uk/${_}/%s.git",
                        web_pattern => $scsys_web_pattern_proto->($_),
                    }
                    )
            } qw(catagits p5sagit dbsrgits)
        ),
    };
}

method _build_repository_url () {
    return $self->_resolve_repository_with( $self->repository_at, 'pattern' )
        if $self->has_repository_at;
    confess "Cannot determine repository url without repository_at. "
        . "Please provide either repository_at or repository.";
}

has _repository_host_map => (
    traits  => [qw(Hash)],
    isa     => $map_tc,
    coerce  => 1,
    lazy    => 1,
    builder => '_build__repository_host_map',
    handles => { _repository_data_for => 'get', },
);


has repository_web => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_repository_web',
    handles => { repository_web => 'as_string', },
);

method _build_repository_web () {
    return $self->_resolve_repository_with( $self->repository_at, 'web_pattern' )
        if $self->has_repository_at;
    confess "Cannot determine repository web url without repository_at. "
        . "Please provide either repository_at or repository_web.";
}

method _resolve_repository_with ($service, $thing) {
    my $dist = $self->dist;
    my $data = $self->_repository_data_for($service);
    confess "unknown repository service $service" unless $data;
    return sprintf $data->{$thing}->(),
        (
        exists $data->{mangle}
        ? $data->{mangle}->($dist)
        : $dist
        );
}


has repository_type => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_repository_type',
);

method _build_repository_type () {
    my $data = $self->_repository_data_for( $self->repository_at );
    return $data->{type} if exists $data->{type};

    for my $vcs (qw(git svn)) {
        return $vcs if $self->repository_scheme eq $vcs;
    }

    confess "Unable to guess repository type based on the repository url. " . "Please provide repository_type.";
}


has github_user => (
    is      => 'ro',
    isa     => Str,
    default => 'nigelm',
);


has tag_format => (
    is      => 'ro',
    isa     => Str,
    default => 'release/%v%t',
);

has tag_message => (
    is      => 'ro',
    isa     => Str,
    default => 'Release of %v%t',
);

has version_regexp => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_version_regexp',
);

method _build_version_regexp () {
    my $version_regexp = $self->tag_format;
    $version_regexp =~ s/\%v/\(\\d+\(\?:\\.\\d+\)\+\)/;
    $version_regexp =~ s/\%t/\(\?:\[-_\]\.+\)\?/;
    return sprintf( '^%s$', $version_regexp );
}

has git_autoversion => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);


# git allow dirty references
has git_allow_dirty => (
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [Str],
    builder => '_build_git_allow_dirty',
);


# git allow dirty references
has git_release_branch => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    default => 'master',
);


has changelog => ( is => 'ro', isa => Str, default => 'Changes' );

sub mvp_multivalue_args { return ('git_allow_dirty'); }

sub _build_git_allow_dirty { [ 'dist.ini', shift->changelog, 'README', 'README.pod' ] }

override BUILDARGS => sub {
    my $class = shift;

    my $args = $class->SUPER::BUILDARGS(@_);
    return { %{ $args->{payload} }, %{$args} };
};


has prune_directories => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { return [ 'local', 'vendor' ] },    # skip carton dirs
);

method configure () {

    # Build a list of all the plugins we want...
    my @wanted = (

        # -- Git versioning
        (   $self->git_autoversion
            ? [ 'Git::NextVersion' => {
                    first_version  => '0.01',
                    version_regexp => $self->version_regexp,
                }
                ]
            : ()
        ),
        [ 'Git::Check'                   => { allow_dirty    => $self->git_allow_dirty } ],
        [ 'Git::CheckFor::CorrectBranch' => { release_branch => $self->git_release_branch } ],

        # ['Git::CheckFor::Fixups'],    ## removed as this has issues with versioning
        ['Git::CheckFor::MergeConflicts'],

        # -- fetch & generate files
        [ GatherDir            => { prune_directory => $self->prune_directories } ],
        [ 'Test::Compile'      => { fake_home       => $self->fake_home } ],
        [ 'Test::Perl::Critic' => {} ],
        [ MetaTests            => {} ],
        ( $self->disable_pod_coverage_tests ? () : [ PodCoverageTests => {} ] ),
        [ PodSyntaxTests => {} ],
        ( $self->disable_pod_spelling_tests ? () : [ 'Test::PodSpelling' => {} ] ),
        (    # Disabling pod coverage scores you a fail on Kwalitee too!
            $self->disable_pod_coverage_tests ? () : [ 'Test::Kwalitee' => {} ]
        ),
        [ 'Test::Portability'    => {} ],
        [ 'Test::Synopsis'       => {} ],
        [ 'Test::MinimumVersion' => {} ],
        [ HasVersionTests        => {} ],
        [ 'Test::DistManifest'   => {} ],
        ( $self->disable_unused_vars_tests ? () : [ 'Test::UnusedVars' => {} ] ),
        ( $self->disable_no_tabs_tests     ? () : [ 'Test::NoTabs'     => {} ] ),
        [ 'Test::EOL' => { trailing_whitespace => $self->disable_trailing_whitespace_tests ? 0 : 1 } ],
        [ 'Test::ReportPrereqs' => {} ],
        [ InlineFiles           => {} ],

        # -- remove some files
        [ PruneCruft   => {} ],
        [ PruneFiles   => { filenames => [qw(perltidy.LOG)] } ],
        [ ManifestSkip => {} ],

        # -- get prereqs
        (   $self->auto_prereqs
            ? [ AutoPrereqs => $self->skip_prereqs ? { skip => $self->skip_prereqs } : {} ]
            : ()
        ),

        # -- gather metadata
        [ MetaConfig              => {} ],
        [ 'MetaProvides::Class'   => {} ],
        [ 'MetaProvides::Package' => {} ],
        [   MetaResources => {
                'repository.type'   => $self->repository_type,
                'repository.url'    => $self->repository_url,
                'repository.web'    => $self->repository_web,
                'bugtracker.web'    => $self->bugtracker_url,
                'bugtracker.mailto' => $self->bugtracker_email,
                'homepage'          => $self->homepage_url,
            }
        ],
        [   Authority => {
                authority      => $self->authority,
                do_metadata    => 1,
                locate_comment => 1,
            }
        ],

        # -- munge files
        [ ExtraTests    => {} ],
        [ NextRelease   => {} ],
        [ OurPkgVersion => {} ],

        (   $self->is_task
            ? [ 'TaskWeaver' => {} ]
            : [ 'PodWeaver' => { config_plugin => $self->weaver_config_plugin } ]
        ),
        ## -- not sure about these - leaving out for now.
        ## # -- dynamic meta-information
        ## [ ExecDir                 => {} ],
        ## [ ShareDir                => {} ],
        ## [ 'MetaProvides::Package' => {} ],

        # -- generate meta files
        [ License => {} ],
        (   $self->has_build_process
            ? [ ( '=inc::' . $self->build_process ) => $self->build_process => {} ]
            : [ MakeMaker => {} ]
        ),
        [ MetaYAML         => {} ],
        [ MetaJSON         => {} ],
        [ ReadmeAnyFromPod => ReadmeTextInBuild => { type => 'text', filename => 'README', location => 'build', } ],
        [ ReadmeAnyFromPod => ReadmePodInRoot => { type => 'pod', filename => 'README.pod', location => 'root', } ],
        [ InstallGuide     => {} ],
        [ Manifest => {} ],    # should come last

        # -- Git release process
        [ 'Git::Commit' => { allow_dirty => $self->git_allow_dirty } ],
        [   'Git::Tag' => {
                tag_format  => $self->tag_format,
                tag_message => $self->tag_message,
            }
        ],
        [ 'Git::CommitBuild' => { branch => '', release_branch => 'cpan', release_message => 'CPAN Release of %v%t' } ],
        [ 'Git::Push'        => {} ],

        # -- release
        [ CheckChangeLog => {} ],
        (   $self->no_cpan
            ? [ FakeRelease => {} ]
            : [ UploadToCPAN => {} ]
        ),
    );

    $self->add_plugins(@wanted);
}

with 'Dist::Zilla::Role::PluginBundle::Easy';

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::NIGELM - Build your distributions like I do

=head1 VERSION

version 0.27

=for test_synopsis 1;
__END__

=for stopwords NIGELM Tweakables catagits catsvn changelog dbsrgits gitmo sagit p5sagit svn RT dist inc

=for Pod::Coverage mvp_multivalue_args

=head1 SYNOPSIS

In your F<dist.ini>:

  [@NIGELM]
  dist = Distribution-Name
  repository_at = github

=head1 DESCRIPTION

This is the L<Dist::Zilla> configuration I use to build my distributions. It
was originally based on the @FLORA bundle but additionally pulls in ideas from
@MARCEL bundle.

It is roughly equivalent to:

    [Git::NextVersion]
        first_version  = 0.01,
        version_regexp = release/(\d+.\d+)
    [Git::Check]
    [Git::CheckFor::CorrectBranch]
        release_branch = master
    # [Git::CheckFor::Fixups]
    [Git::CheckFor::MergeConflicts]
    [GatherDir]
    [Test::Compile]
    [Test::Perl::Critic]
    [MetaTests]
    [PodCoverageTests]
    [PodSyntaxTests]
    [Test::PodSpelling]
    [Test::Kwalitee]
    [Test::Portability]
    [Test::Synopsis]
    [Test::MinimumVersion]
    [HasVersionTests]
    [Test::DistManifest]
    [Test::UnusedVars]
    [Test::NoTabs]
    [Test::EOL]
    [Test::ReportPrereqs]
    [InlineFiles]
    [PruneCruft]
    [PruneFiles]
        filenames = dist.ini
    [ManifestSkip]
    [AutoPrereqs]
    [MetaConfig]
    [MetaProvides::Class]
    [MetaProvides::Package]
    [MetaResources]
    [Authority]
        authority   = cpan:NIGELM
        do_metadata = 1
        locate_comment = 1
    [ExtraTests]
    [NextRelease]
    [OurPkgVersion]
    [PodWeaver]
        config_plugin = @DAGOLDEN
    [License]
    [MakeMaker]
    [MetaYAML]
    [MetaJSON]
    [ReadmeAnyFromPod]
        type = pod
        filename = README.pod
        location = root
    [InstallGuide]
    [Manifest]
    [Git::Commit]
    [Git::Tag]
    [Git::CommitBuild]
        branch =
        release_branch = cpan
    [Git::Push]
    [CheckChangeLog]
    [UploadToCPAN] or [FakeRelease]

=head2 Required Parameters

=head3 dist

The distribution name, as given in the main Dist::Zilla configuration section
(the C<name> parameter). Unfortunately this cannot be extracted from the main
config.

=head2 Tweakables - Major Configuration

=head3 build_process

Overrides build process system - basically this causes the standard Module
Build generation to be suppressed and replaced by a call to a module in the
local inc directory specified by this parameter instead.

=head3 no_cpan

If C<no_cpan> or the environment variable C<NO_CPAN> is set, then the upload to
CPAN is suppressed. This basically swaps L<Dist::Zilla::Plugin::FakeRelease> in
place of L<Dist::Zilla::Plugin::UploadToCPAN>

=head2 Tweakables

=head3 authority

The authority for this distribution - defaults to C<cpan:NIGELM>

=head3 auto_prereqs

Determine Prerequisites automatically - defaults to1 (set).

=head3 skip_prereqs

Prerequisites to skip if C<auto_prereqs> is set -- a string of module names.

=head3 is_task

Is this a Task rather than a Module. Determines whether
L<Dist::Zilla::Plugin::TaskWeaver> or L<Dist::Zilla::Plugin::PodWeaver> are
used. Defaults to 1 if the dist name starts with C<Task>, 0 otherwise.

=head3 weaver_config_plugin

This option is passed to the C<config_plugin> option of
L<Dist::Zilla::Plugin::PodWeaver>. It defaults to C<@DAGOLDEN>, which loads in
L<Pod::Weaver::PluginBundle::DAGOLDEN>.

=head2 Bug Tracker Information

=head3 bugtracker_url

The URL of the bug tracker. Defaults to the CPAN RT queue for the distribution
name.

=head3 bugtracker_email

The email address of the bug tracker. Defaults to the CPAN RT email for the
distribution name.

=head2 Tweaks - Modifying Tests Generated

=head3 disable_pod_coverage_tests

If set, disables the Pod Coverage Release Tests
L<Dist::Zilla::Plugin::PodCoverageTests>. Defaults to unset (tests enabled).

=head3 disable_pod_spelling_tests

If set, disables the Pod Spelling Release Tests
L<Dist::Zilla::Plugin::Test::PodSpelling>. Defaults to unset (tests enabled).

=head3 disable_trailing_whitespace_tests

If set, disables the Trailing Whitespace Release Tests
L<Dist::Zilla::Plugin::Test::EOL>. Defaults to unset (tests enabled).

=head3 disable_unused_vars_tests

If set, disables the Unused Variables Release Tests
L<Dist::Zilla::Plugin::Test::UnusedVars>. Defaults to unset (tests enabled).

=head3 disable_no_tabs_tests

If set, disables the Release Test that checks for hard tabs
L<Dist::Zilla::Plugin::Test::NoTabs>. Defaults to unset (tests enabled).

=head3 fake_home

If set, this sets the C<fake_home> option to.
L<Dist::Zilla::Plugin::Test::Compile>. Defaults to unset.

=head2 Repository, Source Control and Similar

=head3 homepage_url

The module homepage URL. Defaults to the URL of the module page on
C<metacpan.org>. In previous versions this defaulted to the page on
C<search.cpan.org>.

=head3 repository_at

Sets all of the following repository options based on a standard repository
type. This is one of:-

=over 4

=item * B<github> - a github repository, with a lower cased module name.

=item * B<GitHub> - a github repository, with an unmodified module name.

=item * B<gitmo> - a git repository on C<git.moose.perl.org>

=item * B<catsvn> - a svn repository on C<dev.catalyst.perl.org>

=item * B<catagits> - a git repository on C<git.shadowcat.co.uk> in the Catalyst section

=item * B<p5sagit> - a git repository on C<git.shadowcat.co.uk> in the P5s section

=item * B<dbsrgits> - a git repository on C<git.shadowcat.co.uk> in the DBIx::Class section

=back

=head3 repository

The repository URL.  Normally set from L<repository_at>.

=head3 repository_web

The repository web view URL.  Normally set from L<repository_at>.

=head3 repository_type

The repository type - either C<svn> or C<git>.  Normally set from
L<repository_at>.

=head3 github_user

The username on github. Defaults to C<nigelm> which is unlikely to be useful
for anyone else. Sorry!

=head3 tag_format / tag_message / version_regexp / git_autoversion

Overrides the L<Dist::Zilla::Plugin::Git> bundle defaults for these. By default
I use an unusual tag format of C<release/%v> for historical reasons. If
git_autoversion is true (the default) then the version number is taken from
git.

=head3 git_allow_dirty

A list of files that are allowed to be dirty by the Git plugins. Defaults to
C<dist.ini>, the Change log file, C<README> and C<README.pod>.

=head3 git_release_branch

The correct git release branch for this distribution.  Defaults to master.  If
a release is attempted from another branch the release will fail.

=head3 changelog

The Change Log file name.  Defaults to C<Changes>.

=head3 prune_directories

Directories to ignore - currently defaults to C<local> and C<vendor> (the
directories used by carton to store required modules).

=head1 BUGS

It appears this module, in particular the C<ReadmeAnyFromPod> plugin, exposes a
bug with text wrapping in L<Pod::Simple::Text> which can cause modules with
long words (especially long names) to die during packaging.

1;

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-NIGELM>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/nigelm/dist-zilla-pluginbundle-nigelm>

  git clone https://github.com/nigelm/dist-zilla-pluginbundle-nigelm.git

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
