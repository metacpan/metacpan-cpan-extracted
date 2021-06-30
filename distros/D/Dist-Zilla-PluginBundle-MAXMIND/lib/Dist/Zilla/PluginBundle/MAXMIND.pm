package Dist::Zilla::PluginBundle::MAXMIND;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.84';

use Dist::Zilla 6.0;

# For the benefit of AutoPrereqs
use Dist::Zilla::Plugin::Authority;
use Dist::Zilla::Plugin::AutoPrereqs;
use Dist::Zilla::Plugin::BumpVersionAfterRelease;
use Dist::Zilla::Plugin::CPANFile;
use Dist::Zilla::Plugin::CheckPrereqsIndexed;
use Dist::Zilla::Plugin::CheckSelfDependency;
use Dist::Zilla::Plugin::CheckStrictVersion;
use Dist::Zilla::Plugin::CheckVersionIncrement;
use Dist::Zilla::Plugin::CopyFilesFromBuild;
use Dist::Zilla::Plugin::MAXMIND::CheckChangesHasContent;
use Dist::Zilla::Plugin::MAXMIND::Contributors;
use Dist::Zilla::Plugin::MAXMIND::License;
use Dist::Zilla::Plugin::MAXMIND::TidyAll;
use Dist::Zilla::Plugin::MAXMIND::VersionProvider;
use Dist::Zilla::Plugin::MAXMIND::WeaverConfig;
use Dist::Zilla::Plugin::GenerateFile::FromShareDir 0.013;
use Dist::Zilla::Plugin::Git::Check;
use Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts;
use Dist::Zilla::Plugin::Git::Commit;
use Dist::Zilla::Plugin::Git::Contributors;
use Dist::Zilla::Plugin::Git::GatherDir;
use Dist::Zilla::Plugin::Git::Push;
use Dist::Zilla::Plugin::Git::Tag;
use Dist::Zilla::Plugin::GitHub::Meta;
use Dist::Zilla::Plugin::GitHub::Update;
use Dist::Zilla::Plugin::InstallGuide;
use Dist::Zilla::Plugin::Meta::Contributors;
use Dist::Zilla::Plugin::MetaConfig;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::MetaProvides::Package;
use Dist::Zilla::Plugin::MetaResources;
use Dist::Zilla::Plugin::MojibakeTests;
use Dist::Zilla::Plugin::NextRelease;
use Dist::Zilla::Plugin::PPPort;
use Dist::Zilla::Plugin::PodSyntaxTests;
use Dist::Zilla::Plugin::PromptIfStale 0.050;
use Dist::Zilla::Plugin::ReadmeAnyFromPod;
use Dist::Zilla::Plugin::RunExtraTests;
use Dist::Zilla::Plugin::SurgicalPodWeaver;
use Dist::Zilla::Plugin::Test::CPAN::Changes;
use Dist::Zilla::Plugin::Test::CPAN::Meta::JSON;
use Dist::Zilla::Plugin::Test::CleanNamespaces;
use Dist::Zilla::Plugin::Test::Compile;
use Dist::Zilla::Plugin::Test::EOL 0.14;
use Dist::Zilla::Plugin::Test::NoTabs;
use Dist::Zilla::Plugin::Test::Pod::Coverage::Configurable;
use Dist::Zilla::Plugin::Test::PodSpelling;
use Dist::Zilla::Plugin::Test::Portability;
use Dist::Zilla::Plugin::Test::ReportPrereqs;
use Dist::Zilla::Plugin::Test::Synopsis;
use Dist::Zilla::Plugin::Test::TidyAll 0.04;
use Dist::Zilla::Plugin::Test::Version;
use Parse::PMFile;
use Path::Iterator::Rule;
use Path::Tiny qw( path );

use Moose;

with 'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover',
    'Dist::Zilla::Role::PluginBundle::Config::Slicer';

has dist => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has make_tool => (
    is      => 'ro',
    isa     => 'Str',
    default => 'MakeMaker',
);

has authority => (
    is      => 'ro',
    isa     => 'Str',
    default => 'MAXMIND',
);

has prereqs_skip => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => {
        _has_prereqs_skip => 'count',
    },
);

has exclude_files => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has _exclude => (
    is      => 'ro',
    isa     => 'HashRef[ArrayRef]',
    lazy    => 1,
    builder => '_build_exclude',
);

has _exclude_filenames => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { $_[0]->_exclude->{filenames} },
);

has _exclude_match => (
    is      => 'ro',
    isa     => 'ArrayRef[Regexp]',
    lazy    => 1,
    default => sub { $_[0]->_exclude->{match} },
);

has _allow_dirty => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    builder => '_build_allow_dirty',
);

has _has_xs => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $rule = Path::Iterator::Rule->new;
        return scalar $rule->file->name(qr/\.xs$/)->all('.') ? 1 : 0;
    },
);

has pod_coverage_class => (
    is        => 'ro',
    isa       => 'Str',
    predicate => '_has_pod_coverage_class',
);

has pod_coverage_skip => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => {
        _has_pod_coverage_skip => 'count',
    },
);

has pod_coverage_trustme => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => {
        _has_pod_coverage_trustme => 'count',
    },
);

has pod_coverage_also_private => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => {
        _has_pod_coverage_also_private => 'count',
    },
);

has stopwords => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has stopwords_file => (
    is        => 'ro',
    isa       => 'Str',
    predicate => '_has_stopwords_file',
);

has next_release_width => (
    is      => 'ro',
    isa     => 'Int',
    default => 8,
);

has use_github_homepage => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has use_github_issues => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has _plugins => (
    is       => 'ro',
    isa      => 'ArrayRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_plugins',
);

has _files_to_copy_from_build => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_files_to_copy_from_build',
);

my @array_params = grep { !/^_/ } map { $_->name }
    grep {
           $_->has_type_constraint
        && $_->type_constraint->is_a_type_of('ArrayRef')
    } __PACKAGE__->meta->get_all_attributes;

sub mvp_multivalue_args {
    return @array_params;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = $class->$orig(@_);

    my %args = ( %{ $p->{payload} }, %{$p} );

    for my $key (@array_params) {
        if ( $args{$key} && !ref $args{$key} ) {
            $args{$key} = [ delete $args{$key} ];
        }
        $args{$key} //= [];
    }

    # Why isn't this just an additional default on the attribute? Because the
    # config parser for dzil will always pass in an empty arrayref even if no
    # value is set in the config file, meaning that a default attribute value
    # will never be used.
    $args{pod_coverage_also_private} = [
        'qr/\\A (?: BUILD(?:ARGS)? | DEMOLISH ) \\z/x',
        @{ $args{pod_coverage_also_private} || [] },
    ];

    return \%args;
};

sub configure {
    my $self = shift;
    $self->add_plugins( @{ $self->_plugins } );
    return;
}

sub _build_plugins {
    my $self = shift;

    return [
        $self->make_tool,
        $self->_gather_dir_plugin,
        $self->_basic_plugins,
        $self->_authority_plugin,
        $self->_auto_prereqs_plugin,
        $self->_copy_files_from_build_plugin,
        $self->_github_plugins,
        $self->_meta_plugins,
        $self->_next_release_plugin,
        $self->_explicit_prereq_plugins,
        $self->_prompt_if_stale_plugin,
        $self->_pod_test_plugins,
        $self->_extra_test_plugins,
        $self->_contributors_plugins,
        $self->_pod_weaver_plugin,

        # README.md generation needs to come after pod weaving
        $self->_readme_md_plugin,
        $self->_contributing_md_plugin,
        'InstallGuide',
        'CPANFile',
        $self->_maybe_ppport_plugin,
        'MAXMIND::License',
        $self->_release_check_plugins,
        'MAXMIND::TidyAll',
        $self->_upload_to_cpan_plugin,
        $self->_git_plugins,
    ];
}

sub _gather_dir_plugin {
    my $self = shift;

    my $match = $self->_exclude_match;
    [
        'Git::GatherDir' => {
            exclude_filename => $self->_exclude_filenames,
            ( @{$match} ? ( exclude_match => $match ) : () ),
        },
    ];
}

sub _build_exclude {
    my $self = shift;

    my @filenames = @{ $self->_files_to_copy_from_build };

    my @match;
    for my $exclude ( @{ $self->exclude_files } ) {
        if ( $exclude =~ m{^[\w\-\./]+$} ) {
            push @filenames, $exclude;
        }
        else {
            push @match, qr/$exclude/;
        }
    }

    return {
        filenames => \@filenames,
        match     => \@match,
    };
}

sub _basic_plugins {

    # These are a subset of the @Basic bundle except for CheckVersionIncrement
    # and MAXMIND::VersionProvider.
    qw(
        ManifestSkip
        License
        ExecDir
        ShareDir
        Manifest
        CheckVersionIncrement
        TestRelease
        ConfirmRelease
        MAXMIND::VersionProvider
    );
}

sub _authority_plugin {
    my $self = shift;

    return [
        Authority => {
            authority  => 'cpan:' . $self->authority,
            do_munging => 0,
        },
    ];
}

sub _auto_prereqs_plugin {
    my $self = shift;

    return [
        AutoPrereqs => {
            $self->_has_prereqs_skip
            ? ( skip => $self->prereqs_skip )
            : ()
        },
    ];
}

sub _copy_files_from_build_plugin {
    my $self = shift;

    return [
        CopyFilesFromBuild => {
            copy => $self->_files_to_copy_from_build,
        },
    ];
}

# These are files which are generated as part of the build process and then
# copied back into the git repo and checked in.
sub _build_files_to_copy_from_build {
    my $self = shift;

    my @files = qw(
        CONTRIBUTING.md
        LICENSE
        README.md
        cpanfile
    );

    push @files,
        $self->make_tool eq 'MakeMaker' ? 'Makefile.PL' : 'Build.PL';

    my $rule = Path::Iterator::Rule->new;
    my $dist = $self->dist;

    # We need to skip any existing build dirs
    my $iter = $rule->file->name('ppport.h')->skip(
        $rule->new->dir->name(qr{^\Q$dist\E-\d+\.\d+}),
        $rule->new->dir->name('.build')
    )->iter('.');

    if ( my $ppport = $iter->() ) {

        # If the file is in a subdir we end up with a name like
        # "./foo/ppport.h" - the initial "./" bit will confuse the gatherdir
        # exclude rules.
        $ppport =~ s{^\./}{};
        push @files, $ppport;
    }

    return \@files;
}

sub _github_plugins {
    return if $ENV{TRAVIS};

    my $self = shift;

    return (
        [
            'GitHub::Meta' => {
                bugs     => $self->use_github_issues,
                homepage => $self->use_github_homepage,
            },
        ],
        [ 'GitHub::Update' => { metacpan => 1 } ],
    );
}

sub _meta_plugins {
    my $self = shift;

    return (
        [ MetaResources           => $self->_meta_resources, ],
        [ 'MetaProvides::Package' => { meta_noindex => 1 } ],
        qw(
            Meta::Contributors
            MetaConfig
            MetaJSON
            MetaYAML
        ),
    );
}

sub _meta_resources {
    my $self = shift;

    my %resources;

    unless ( $self->use_github_homepage ) {
        $resources{homepage}
            = sprintf( 'http://metacpan.org/release/%s', $self->dist );
    }

    unless ( $self->use_github_issues ) {
        %resources = (
            %resources,
            'bugtracker.web' => sprintf(
                'http://rt.cpan.org/Public/Dist/Display.html?Name=%s',
                $self->dist
            ),
            'bugtracker.mailto' =>
                sprintf( 'bug-%s@rt.cpan.org', lc $self->dist ),
        );
    }

    return \%resources;
}

sub _next_release_plugin {
    my $self = shift;

    return [
        NextRelease => {
                  format => '%-'
                . $self->next_release_width
                . 'v %{yyyy-MM-dd}d%{ (TRIAL RELEASE)}T'
        },
    ];
}

sub _explicit_prereq_plugins {
    my $self = shift;

    my $test_more = $self->_dist_uses_test2
        ? [
        'Prereqs' => 'Test::More with Test2' => {
            -phase       => 'test',
            -type        => 'requires',
            'Test::More' => '1.302015',
        }
        ]
        : [
        'Prereqs' => 'Test::More with subtest' => {
            -phase       => 'test',
            -type        => 'requires',
            'Test::More' => '0.96',
        }
        ];

    return (
        $test_more,

        # Because Code::TidyAll does not depend on them
        [
            'Prereqs' => 'Modules for use with tidyall' => {
                -phase                              => 'develop',
                -type                               => 'requires',
                'Code::TidyAll::Plugin::Test::Vars' => '0.02',
                'Parallel::ForkManager'             => '1.19',
                'Perl::Critic'                      => '1.126',
                'Perl::Tidy'                        => '20160302',
                'Test::Vars'                        => '0.009',
            }
        ],
        [
            'Prereqs' =>
                'Test::Version which fixes https://github.com/plicease/Test-Version/issues/7'
                => {
                -phase          => 'develop',
                -type           => 'requires',
                'Test::Version' => '2.05',
                },
        ],
    );
}

sub _dist_uses_test2 {
    my $rule = Path::Iterator::Rule->new;
    my $iter
        = $rule->file->name(qr/\.(t|pm)/)->contents_match(qr/^use Test2/m)
        ->iter('t');

    while ( my $file = $iter->() ) {
        return 1;
    }

    return 0;
}

sub _prompt_if_stale_plugin {
    my $name = __PACKAGE__;
    return (
        [
            'PromptIfStale' => $name => {
                phase  => 'build',
                module => [__PACKAGE__],
            },
        ],
        [
            'PromptIfStale' => {
                phase             => 'release',
                check_all_plugins => 1,
                check_all_prereqs => 1,
                check_authordeps  => 1,
                skip              => [
                    qw(
                        Dist::Zilla::Plugin::MAXMIND::CheckChangesHasContent
                        Dist::Zilla::Plugin::MAXMIND::Contributors
                        Dist::Zilla::Plugin::MAXMIND::License
                        Dist::Zilla::Plugin::MAXMIND::TidyAll
                        Dist::Zilla::Plugin::MAXMIND::VersionProvider
                        Pod::Weaver::PluginBundle::MAXMIND
                    )
                ],
            }
        ],
    );
}

sub _pod_test_plugins {
    my $self = shift;

    return (
        [
            'Test::Pod::Coverage::Configurable' => {
                (
                    $self->_has_pod_coverage_also_private
                    ? ( also_private => $self->pod_coverage_also_private )
                    : ()
                ),
                (
                    $self->_has_pod_coverage_skip
                    ? ( skip => $self->pod_coverage_skip )
                    : ()
                ),
                (
                    $self->_has_pod_coverage_trustme
                    ? ( trustme => $self->pod_coverage_trustme )
                    : ()
                ),
                (
                    $self->_has_pod_coverage_class
                    ? ( class => $self->pod_coverage_class )
                    : ()
                ),
            },
        ],
        [
            'Test::PodSpelling' => { stopwords => $self->_all_stopwords },
        ],
        'PodSyntaxTests',
    );
}

sub _all_stopwords {
    my $self = shift;

    my @stopwords = $self->_default_stopwords;
    push @stopwords, @{ $self->stopwords };

    if ( $self->_has_stopwords_file ) {
        push @stopwords, path( $self->stopwords_file )->lines_utf8;
    }

    return \@stopwords;
}

sub _default_stopwords {
    return qw(
        MAXMIND
        MAXMIND's
        PayPal
        Alders
        Alders'
        Eilam
        Eilam's
        MaxMind
        MaxMind's
        Oschwald
        Oschwald's
        Rolsky
        Rolsky's
    );
}

sub _extra_test_plugins {
    return (
        qw(
            RunExtraTests
            MojibakeTests
            Test::CleanNamespaces
            Test::CPAN::Changes
            Test::CPAN::Meta::JSON
            Test::EOL
            Test::NoTabs
            Test::Portability
            Test::Synopsis
        ),
        [
            'Test::TidyAll' => {
                verbose => 1,
                jobs    => 4,

                # Test::Vars requires this version
                minimum_perl => '5.010',
            }
        ],
        [ 'Test::Compile'       => { xt_mode        => 1 } ],
        [ 'Test::ReportPrereqs' => { verify_prereqs => 1 } ],
        [ 'Test::Version'       => { is_strict      => 1 } ],
    );
}

sub _contributors_plugins {
    qw(
        MAXMIND::Contributors
        Git::Contributors
    );
}

sub _pod_weaver_plugin {
    return (
        [
            SurgicalPodWeaver => {
                config_plugin => '@MAXMIND',
            },
        ],
        'MAXMIND::WeaverConfig',
    );
}

sub _readme_md_plugin {
    [
        'ReadmeAnyFromPod' => 'README.md in build' => {
            type     => 'markdown',
            filename => 'README.md',
            location => 'build',
            phase    => 'build',
        },
    ];
}

sub _contributing_md_plugin {
    my $self = shift;

    return [
        'GenerateFile::FromShareDir' => 'Generate CONTRIBUTING.md' => {
            -dist     => ( __PACKAGE__ =~ s/::/-/gr ),
            -filename => 'CONTRIBUTING.md',
            has_xs    => $self->_has_xs,
        },
    ];
}

sub _maybe_ppport_plugin {
    my $self = shift;

    return unless $self->_has_xs;
    return 'PPPort';
}

sub _release_check_plugins {
    return (
        [ CheckStrictVersion => { decimal_only => 1 } ],
        qw(
            CheckSelfDependency
            CheckPrereqsIndexed
            MAXMIND::CheckChangesHasContent
            Git::CheckFor::MergeConflicts
        ),
    );
}

sub _upload_to_cpan_plugin {
    return [
        UploadToCPAN => { pause_cfg_file => '.pause-maxmind' },
    ];
}

sub _git_plugins {
    my $self = shift;

    # These are mostly from @Git, except for BumpVersionAfterRelease. That
    # one's in here because the order of all these plugins is
    # important. We want to check the release, then we ...

    return (
        # Check that the working directory does not contain any surprising uncommitted
        # changes (except for things we expect to be dirty like the README.md or
        # Changes).
        [ 'Git::Check' => { allow_dirty => $self->_allow_dirty }, ],

        # Commit all the dirty files before the release.
        [
            'Git::Commit' => 'Commit generated files' => {
                allow_dirty => $self->_allow_dirty,
            },
        ],

        # Tag the release and push both the above commit and the tag.
        qw(
            Git::Tag
            Git::Push
        ),

        # Bump all module versions.
        'BumpVersionAfterRelease',

        # Make another commit with just the version bump.
        [
            'Git::Commit' => 'Commit version bump' => {
                allow_dirty_match => ['.+'],
                commit_msg        => 'Bump version after release'
            },
        ],

        # Push the version bump commit.
        [ 'Git::Push' => 'Push version bump' ],
    );
}

sub _build_allow_dirty {
    my $self = shift;

    # Anything we auto-generate and check in could be dirty. We also allow any
    # other file which might get munged by this bundle to be dirty.
    return [
        @{ $self->_exclude_filenames },
        qw(
            Changes
            tidyall.ini
        )
    ];
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: MAXMIND's plugin bundle

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::MAXMIND - MAXMIND's plugin bundle

=head1 VERSION

version 0.84

=head1 SYNOPSIS

    name    = My-Module
    author  = Dave Rolsky <autarch@urth.org>
    license = Artistic_2_0
    copyright_holder = Dave Rolsky

    [@MAXMIND]
    dist = My-Module
    ; Fefault is MakeMaker - or set it to ModuleBuild
    make_tool = MakeMaker
    ; These files won't be added to tarball
    exclude_files = ...
    ; Default is MAXMIND
    authority = MAXMIND
    ; Passed to AutoPrereqs - can be repeated
    prereqs_skip = ...
    ; Passed to Test::Pod::Coverage::Configurable if set
    pod_coverage_also_private = ...
    ; Passed to Test::Pod::Coverage::Configurable if set - can be repeated
    pod_coverage_class = ...
    ; Passed to Test::Pod::Coverage::Configurable if set - can be repeated
    pod_coverage_skip = ...
    ; Passed to Test::Pod::Coverage::Configurable if set - can be repeated
    pod_coverage_trustme = ...
    ; For pod spelling test - can be repeated
    stopwords = ...
    ; Can also put them in a separate file
    stopwords_file = ..
    ; Defaults to false
    use_github_homepage = 0
    ; Defaults to false
    use_github_issues = 0

=head1 DESCRIPTION

This is the L<Dist::Zilla> plugin bundle I use for my distributions. Don't use
this directly for your own distributions, but you may find it useful as a
source of ideas for building your own bundle.

This bundle uses L<Dist::Zilla::Role::PluginBundle::PluginRemover> and
L<Dist::Zilla::Role::PluginBundle::Config::Slicer> so I can remove or
configure any plugin as needed.

This is more or less equivalent to the following F<dist.ini>:

    ; Picks one of these - defaults to MakeMaker
    [MakeMaker]
    [ModuleBuild]

    [Git::GatherDir]
    ; Both are configured by setting exclude_files for the bundle. Simple
    ; values like "./foo/bar.pl" are treated as filenames, others like
    ; "*\.jnk$" are treated as a regex.
    exclude_filenames = ...
    exclude_match     = ...

    [ManifestSkip]
    [License]
    [ExecDir]
    [ShareDir]
    [Manifest]
    [CheckVersionIncrement]
    [TestRelease]
    [ConfirmRelease]
    [UploadToCPAN]
    ; Opens up the main module and finds a $VERSION
    [MAXMIND::VersionProvider]

    [Authority]
    ; Configured by setting authority for the bundle
    authority  = ...
    do_munging = 0

    [AutoPrereqs]
    ; Configured by setting skip_prereqs for the bundle
    skip = ...

    [CopyFilesFromBuild]
    copy = Build.PL
    copy = CONTRIBUTING.md
    copy = LICENSE
    copy = Makefile.PL
    copy = README.md
    copy = cpanfile
    copy = ppport.h

    [GitHub::Meta]
    ; Configured by setting use_github_issues for the bundle
    bugs = 0
    ; Configured by setting use_github_homepage for the bundle
    homepage = 0

    [MetaResources]
    homepage = http://metacpan.org/release/My-Module
    ; RT bits are omitted if use_github_issue is true
    bugtracker.web  = http://rt.cpan.org/Public/Dist/Display.html?Name=My-Module
    bugtracker.mail = bug-My-Module@rt.cpan.org

    [MetaProvides::Pckage]
    meta_noindex = 1

    [Meta::Contributors]
    [Meta::Config]
    [MetaJSON]
    [MetaYAML]

    [NextRelease]
    ; Width is configured by setting next_release_width for the bundle
    format = %-8v %{yyyy-MM-dd}d%{ (TRIAL RELEASE)}T

    ; Scans the test files for use of Test2 and picks either
    [Prereqs / Test::More with Test2]
    -phase = test
    -type  = requires
    Test::More = 1.302015

    ; If the distro doesn't use Test2
    [Prereqs / Test::More with subtest]
    -phase = test
    -type  = requires
    Test::More = 0.96

    [Prereqs / Modules for use with tidyall]
    -phase = develop
    -type  = requires
    Code::TidyAll::Plugin::Test::Vars = 0.02
    Parallel::ForkManager'            = 1.19
    Perl::Critic                      = 1.126
    Perl::Tidy                        = 20160302
    Test::Vars                        = 0.009

    [Prereqs / Test::Version which fixes https://github.com/plicease/Test-Version/issues/7]
    -phase = develop
    -type  = requires
    Test::Version = 2.05

    [PromptIfStale]
    phase  = build
    module = Dist::Zilla::PluginBundle::MAXMIND

    [PromptIfStale]
    phase = release
    check_all_plugins = 1
    check_all_prereqs = 1
    check_authordeps  = 1
    skip = Dist::Zilla::Plugin::MAXMIND::CheckChangesHasContent
    skip = Dist::Zilla::Plugin::MAXMIND::Contributors
    skip = Dist::Zilla::Plugin::MAXMIND::License
    skip = Dist::Zilla::Plugin::MAXMIND::TidyAll
    skip = Dist::Zilla::Plugin::MAXMIND::VersionProvider
    skip = Pod::Weaver::PluginBundle::MAXMIND

    [Test::Pod::Coverage::Configurable]
    ; Configured by setting pod_coverage_class for the bundle
    class = ...
    ; Configured by setting pod_coverage_skip for the bundle
    skip = ...
    ; Configured by setting pod_coverage_trustme for the bundle
    trustme = ...

    [Test::PodSpelling]
    ; Configured by setting stopwords and/or stopwords_file for the bundle
    stopwods = ...

    [PodSyntaxTests]

    [RunExtraTests]
    [MojibakeTests]
    [Test::CleanNamespaces]
    [Test::CPAN::Changes]
    [Test::CPAN::Meta::JSON]
    [Test::EOL]
    [Test::NoTabs]
    [Test::Portability]
    [Test::Synopsis]

    [Test::TidyAll]
    verbose = 1
    jobs    = 4
    minimum_perl = 5.010

    [Test::Compile]
    xt_mode = 1

    [Test::ReportPrereqs]
    verify_prereqs = 1

    [Test::Version]
    is_strict = 1

    ; Generates/updates a .mailmap file
    [MAXMIND::Contributors]
    [Git::Contributors]

    [SurgicalPodWeaver]
    ; See Pod::Weaver::PluginBundle::MAXMIND in this same distro for more info
    config_plugin = @MAXMIND

    ; Nasty hack so I can pass config from the dist.ini to the Pod::Weaver
    ; bundle. Currently used so I can set
    ; "MAXMIND::WeaverConfig.include_donations_pod = 0" in a dist.ini file.
    [MAXMIND::WeaverConfig]

    [ReadmeAnyFromPod / README.md in build]
    type     = markdown
    filename = README.md
    location = build
    phase    = build

    [GenerateFile::FromShareDir / Generate CONTRIBUTING.md]
    -dist     = Dist-Zilla-PluginBundle-MAXMIND
    -filename = CONTRIBUTING.md
    ; This is determined by looking through the distro for .xs files.
    has_xs    = ...

    [InstallGuide]
    [CPANFile]

    ; Only added if the distro has .xs files
    [PPPort]

    ; Like the default License plugin except that it defaults to Artistic 2.0.
    ; Also, if the copyright_year for the bundle is not this year, it passes
    ; something like "2014-2016" to Software::License.
    [MAXMIND::License]

    [CheckPrereqsIndexed]

    ; More or less like Dist::Zilla::Plugin::CheckChangesHasContent but uses
    ; CPAN::Changes to parse the Changes file.
    [MAXMIND::CheckChangesHasContent]

    [Git::CheckFor::MergeConflicts]

    ; Generates/updates tidyall.ini, perlcriticrc, and perltidyrc
    [MAXMIND::TidyAll]

    ; The allow_dirty list is basically all of the generated or munged files
    ; in the distro, including:
    ;     Build.PL
    ;     CONTRIBUTING.md
    ;     Changes
    ;     LICENSE
    ;     Makefile.PL
    ;     README.md
    ;     cpanfile
    ;     ppport.h
    ;     tidyall.ini
    [Git::Check]
    allow_dirty = ...

    [Git::Commit / Commit generated files]
    allow_dirty = ...

    [Git::Tag]
    [Git::Push]

    [BumpVersionAfterRelease]

    [Git::Commit / Commit version bump]
    allow_dirty_match = .+
    commit_msg        = Bump version after release

    [Git::Push / Push version bump]

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Dist-Zilla-PluginBundle-MAXMIND/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Dave Rolsky Florian Ragwitz Greg Oschwald Mark Fowler Olaf Alders Patrick Cronin Will Storey

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Greg Oschwald <goschwald@maxmind.com>

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Olaf Alders <oalders@maxmind.com>

=item *

Patrick Cronin <PatrickCronin@users.noreply.github.com>

=item *

Patrick Cronin <pcronin@maxmind.com>

=item *

Will Storey <wstorey@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Dave Rolsky and MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
