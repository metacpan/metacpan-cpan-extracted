package Dist::Zilla::PluginBundle::DROLSKY;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.20';

use Devel::PPPort 3.42;
use Dist::Zilla 6.0;
use Path::Tiny::Rule;

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
use Dist::Zilla::Plugin::DROLSKY::BundleAuthordep;
use Dist::Zilla::Plugin::DROLSKY::Contributors;
use Dist::Zilla::Plugin::DROLSKY::DevTools;
use Dist::Zilla::Plugin::DROLSKY::License;
use Dist::Zilla::Plugin::DROLSKY::MakeMaker;
use Dist::Zilla::Plugin::DROLSKY::PerlLinterConfigFiles;
use Dist::Zilla::Plugin::DROLSKY::Precious;
use Dist::Zilla::Plugin::DROLSKY::Test::Precious;
use Dist::Zilla::Plugin::DROLSKY::WeaverConfig;
use Dist::Zilla::Plugin::EnsureChangesHasContent 0.02;
use Dist::Zilla::Plugin::GenerateFile::FromShareDir 0.013;
use Dist::Zilla::Plugin::Git::Check;
use Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts;
use Dist::Zilla::Plugin::Git::Commit;
use Dist::Zilla::Plugin::Git::Contributors;
use Dist::Zilla::Plugin::Git::GatherDir;
use Dist::Zilla::Plugin::Git::Push;
use Dist::Zilla::Plugin::Git::Tag;
use Dist::Zilla::Plugin::GitHub::Meta 0.45;
use Dist::Zilla::Plugin::GitHub::Update 0.45;
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
use Dist::Zilla::Plugin::PromptIfStale 0.056;
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
use Dist::Zilla::Plugin::Test::Version;
use Dist::Zilla::Plugin::VersionFromMainModule 0.02;

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
    default => 'DROLSKY::MakeMaker',
);

has authority => (
    is      => 'ro',
    isa     => 'Str',
    default => 'DROLSKY',
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

has has_xs => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_build_has_xs',
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

has _running_in_ci => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub {

        # AGENT_ID is Azure Pipelines.
        return $ENV{TRAVIS} || $ENV{AGENT_ID} ? 1 : 0;
    },
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

    return \%args;
};

sub configure {
    my $self = shift;
    $self->add_plugins( @{ $self->_plugins } );
    return;
}

sub _build_plugins {
    my $self = shift;

    my %make_tool_args;
    if ( $self->make_tool =~ /MakeMaker/ ) {
        $make_tool_args{has_xs} = $self->has_xs;
    }

    return [
        'DROLSKY::BundleAuthordep',
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
        $self->_code_of_conduct_plugin,
        'InstallGuide',
        'CPANFile',
        $self->_maybe_ppport_plugin,
        'DROLSKY::License',
        $self->_release_check_plugins,
        'DROLSKY::PerlLinterConfigFiles',
        $self->_precious_plugin,
        $self->_git_plugins,

        # This needs to be last so that MakeMaker::Awesome can see all the
        # prereqs that a distro has. If it comes first, it tries to check the
        # prereqs before they've been added and makes a mess of things.
        [ $self->make_tool => \%make_tool_args ],
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
    # and VersionFromMainModule.
    qw(
        ManifestSkip
        License
        ExecDir
        ShareDir
        Manifest
        CheckVersionIncrement
        TestRelease
        ConfirmRelease
        UploadToCPAN
        VersionFromMainModule
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
        CODE_OF_CONDUCT.md
        CONTRIBUTING.md
        LICENSE
        README.md
        cpanfile
    );

    push @files,
        $self->make_tool =~ /MakeMaker/ ? 'Makefile.PL' : 'Build.PL';

    if ( $self->has_xs ) {
        if ( $self->payload->{'PPPort.filename'} ) {
            push @files, $self->payload->{'PPPort.filename'};
        }
        else {
            push @files, 'ppport.h';
        }
    }

    return \@files;
}

sub _github_plugins {
    my $self = shift;

    return if $self->_running_in_ci;

    return (
        [
            'GitHub::Meta' => {
                bugs         => 1,
                homepage     => $self->use_github_homepage,
                require_auth => 1,
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
            = sprintf( 'https://metacpan.org/release/%s', $self->dist );
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

    # These are needed for use with tidyall, but they're not direct tidyall
    # prereqs.
    my @lint_tool_prereqs;
    my %shared_lint_prereqs = (
        'Perl::Critic'        => '1.138',
        'Perl::Critic::Moose' => '1.05',
        'Perl::Tidy'          => '20210111',
    );

    if ( -e 'tidyall.ini' ) {
        @lint_tool_prereqs = (
            'Prereqs' => 'Modules for use with tidyall' => {
                -phase                                        => 'develop',
                -type                                         => 'requires',
                'Code::TidyAll'                               => '0.56',
                'Code::TidyAll::Plugin::SortLines::Naturally' => '0.000003',
                'Code::TidyAll::Plugin::Test::Vars'           => '0.02',
                'Parallel::ForkManager'                       => '1.19',
                'Test::Vars'                                  => '0.009',
                %shared_lint_prereqs,
            }
        );
    }
    else {
        @lint_tool_prereqs = (
            'Prereqs' => 'Tools for use with precious' => {
                -phase         => 'develop',
                -type          => 'requires',
                'Pod::Checker' => '1.74',
                'Pod::Tidy'    => '0.10',
                %shared_lint_prereqs,
            },
        );
    }

    return (
        $test_more,
        \@lint_tool_prereqs,
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
    my $rule = Path::Tiny::Rule->new;
    my $iter
        = $rule->file->name(qr/\.(t|pm)$/)->contents_match(qr/^use Test2/m)
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
                        Dist::Zilla::Plugin::DROLSKY::BundleAuthordep
                        Dist::Zilla::Plugin::DROLSKY::Contributors
                        Dist::Zilla::Plugin::DROLSKY::Git::CheckFor::CorrectBranch
                        Dist::Zilla::Plugin::DROLSKY::License
                        Dist::Zilla::Plugin::DROLSKY::MakeMaker
                        Dist::Zilla::Plugin::DROLSKY::PerlLinterConfigFiles
                        Dist::Zilla::Plugin::DROLSKY::Precious
                        Dist::Zilla::Plugin::DROLSKY::Test::Precious
                        Dist::Zilla::Plugin::DROLSKY::WeaverConfig
                        Pod::Weaver::PluginBundle::DROLSKY
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
        open my $fh, '<:encoding(UTF-8)', $self->stopwords_file;
        while (<$fh>) {
            chomp;
            next unless length $_ && $_ !~ /^\#/;
            push @stopwords, $_;
        }
        close $fh;
    }

    return \@stopwords;
}

sub _default_stopwords {
    return qw(
        drolsky
        DROLSKY
        DROLSKY's
        PayPal
        Rolsky
        Rolsky's
    );
}

sub _extra_test_plugins {
    my $self = shift;

    my @plugins = (
        qw(
            MojibakeTests
            RunExtraTests
            Test::CleanNamespaces
            Test::CPAN::Changes
            Test::CPAN::Meta::JSON
            Test::EOL
            Test::NoTabs
            Test::Portability
            Test::Synopsis
        ),
        [ 'Test::Compile'       => { xt_mode        => 1 } ],
        [ 'Test::ReportPrereqs' => { verify_prereqs => 1 } ],
        [ 'Test::Version'       => { is_strict      => 1 } ],
    );

    push @plugins,
        -f 'tidyall.ini' ? 'Test::TidyAll' : 'DROLSKY::Test::Precious';

    return @plugins;
}

sub _contributors_plugins {
    qw(
        DROLSKY::Contributors
        Git::Contributors
    );
}

sub _pod_weaver_plugin {
    return (
        [
            SurgicalPodWeaver => {
                config_plugin => '@DROLSKY',
            },
        ],
        'DROLSKY::WeaverConfig',
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
            has_xs    => $self->has_xs,
        },
    ];
}

sub _code_of_conduct_plugin {
    my $self = shift;

    return [
        'GenerateFile::FromShareDir' => 'Generate CODE_OF_CONDUCT.md' => {
            -dist     => ( __PACKAGE__ =~ s/::/-/gr ),
            -filename => 'CODE_OF_CONDUCT.md',
            has_xs    => $self->has_xs,
        },
    ];
}

sub _maybe_ppport_plugin {
    my $self = shift;

    return unless $self->has_xs;
    return 'PPPort';
}

sub _release_check_plugins {
    return (
        [ CheckStrictVersion => { decimal_only => 1 } ],
        qw(
            CheckSelfDependency
            CheckPrereqsIndexed
            DROLSKY::Git::CheckFor::CorrectBranch
            EnsureChangesHasContent
            Git::CheckFor::MergeConflicts
        ),
    );
}

sub _precious_plugin {
    my $self = shift;

    return if -e 'tidyall.ini';

    my %precious_config;
    $precious_config{stopwords_file} = $self->stopwords_file
        if $self->_has_stopwords_file;

    return (
        'DROLSKY::DevTools',
        (
            keys %precious_config
            ? [ 'DROLSKY::Precious' => \%precious_config ]
            : 'DROLSKY::Precious'
        ),
    );
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
            precious.toml
        )
    ];
}

sub _build_has_xs {
    my $self = shift;

    my $rule = Path::Tiny::Rule->new;
    return $rule->skip_dirs(
        '.build',
        $self->dist . '-*',
    )->file->name(qr/\.xs$/)->iter('.')->() ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: DROLSKY's plugin bundle

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::DROLSKY - DROLSKY's plugin bundle

=head1 VERSION

version 1.20

=head1 SYNOPSIS

    name    = My-Module
    author  = Dave Rolsky <autarch@urth.org>
    license = Artistic_2_0
    copyright_holder = Dave Rolsky

    [@DROLSKY]
    dist = My-Module
    ; Default is DROLSKY::MakeMaker - or set it to ModuleBuild
    make_tool = DROLSKY::MakeMaker
    ; These files won't be added to tarball
    exclude_files = ...
    ; Default is DROLSKY
    authority = DROLSKY
    ; Used to do things like add the PPPort plugin - determined automatically but can be overridden
    has_xs = ...
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

=head1 DESCRIPTION

This is the L<Dist::Zilla> plugin bundle I use for my distributions. Don't use
this directly for your own distributions, but you may find it useful as a
source of ideas for building your own bundle.

This bundle uses L<Dist::Zilla::Role::PluginBundle::PluginRemover> and
L<Dist::Zilla::Role::PluginBundle::Config::Slicer> so I can remove or configure
any plugin as needed.

This is more or less equivalent to the following F<dist.ini>:

    ; updates the dist.ini to include an authordep on this bundle at its
    ; current $VERSION.
    [DROLSKY::BundleAuthordep]

    ; Picks one of these - defaults to DROLSKY::MakeMaker
    [DROLSKY::MakeMaker]
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
    [VersionFromMainModule]

    [Authority]
    ; Configured by setting authority for the bundle
    authority  = ...
    do_munging = 0

    [AutoPrereqs]
    ; Configured by setting skip_prereqs for the bundle
    skip = ...

    [CopyFilesFromBuild]
    copy = Build.PL
    copy = CODE_OF_CONDUCT.md
    copy = CONTRIBUTING.md
    copy = LICENSE
    copy = Makefile.PL
    copy = README.md
    copy = cpanfile
    copy = ppport.h

    [GitHub::Meta]
    bugs = 1
    ; Configured by setting use_github_homepage for the bundle
    homepage = 0

    [MetaResources]
    homepage = https://metacpan.org/release/My-Module
    bugtracker.web  = https://github.com/...

    [MetaProvides::Pckage]
    meta_noindex = 1

    [Meta::Contributors]
    [Meta::Config]
    [MetaJSON]
    [MetaYAML]

    [NextRelease]
    ; Width is configured by setting next_release_width for the bundle
    format = %-8v %{yyyy-MM-dd}d%{ (TRIAL RELEASE)}T

    ; Scans the test files for use of Test2 and picks either this:
    [Prereqs / Test::More with Test2]
    -phase = test
    -type  = requires
    Test::More = 1.302015

    ; or, if the distro doesn't use Test2:
    [Prereqs / Test::More with subtest]
    -phase = test
    -type  = requires
    Test::More = 0.96

    [Prereqs / Modules for use with precious]
    -phase = develop
    -type  = requires
    Perl::Critic        = 1.138
    Perl::Critic::Moose = 1.05
    Perl::Tidy          = 20210111
    Pod::Checker        = 1.74
    Pod::Tidy           = 0.10

    [Prereqs / Test::Version which fixes https://github.com/plicease/Test-Version/issues/7]
    -phase = develop
    -type  = requires
    Test::Version = 2.05

    [PromptIfStale]
    phase  = build
    module = Dist::Zilla::PluginBundle::DROLSKY

    [PromptIfStale]
    phase = release
    check_all_plugins = 1
    check_all_prereqs = 1
    check_authordeps  = 1
    skip = Dist::Zilla::Plugin::DROLSKY::BundleAuthordep
    skip = Dist::Zilla::Plugin::DROLSKY::Contributors
    skip = Dist::Zilla::Plugin::DROLSKY::Git::CheckFor::CorrectBranch
    skip = Dist::Zilla::Plugin::DROLSKY::License
    skip = Dist::Zilla::Plugin::DROLSKY::MakeMaker
    skip = Dist::Zilla::Plugin::DROLSKY::PerlLinterConfigFiles
    skip = Dist::Zilla::Plugin::DROLSKY::Precious
    skip = Dist::Zilla::Plugin::DROLSKY::Test::Precious
    skip = Dist::Zilla::Plugin::DROLSKY::WeaverConfig
    skip = Pod::Weaver::PluginBundle::DROLSKY

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

    [DROLSKY::Test::Precious]
    [MojibakeTests]
    [Test::CleanNamespaces]
    [Test::CPAN::Changes]
    [Test::CPAN::Meta::JSON]
    [Test::EOL]
    [Test::NoTabs]
    [Test::Portability]
    [Test::Synopsis]

    [Test::Compile]
    xt_mode = 1

    [Test::ReportPrereqs]
    verify_prereqs = 1

    [Test::Version]
    is_strict = 1

    ; Generates/updates a .mailmap file
    [DROLSKY::Contributors]
    [Git::Contributors]

    [SurgicalPodWeaver]
    ; See Pod::Weaver::PluginBundle::DROLSKY in this same distro for more info
    config_plugin = @DROLSKY

    ; Nasty hack so I can pass config from the dist.ini to the Pod::Weaver
    ; bundle. Currently used so I can set
    ; "DROLSKY::WeaverConfig.include_donations_pod = 0" in a dist.ini file.
    [DROLSKY::WeaverConfig]

    [ReadmeAnyFromPod / README.md in build]
    type     = markdown
    filename = README.md
    location = build
    phase    = build

    [GenerateFile::FromShareDir / Generate CONTRIBUTING.md]
    -dist     = Dist-Zilla-PluginBundle-DROLSKY
    -filename = CONTRIBUTING.md
    ; This is determined by looking through the distro for .xs files.
    has_xs    = ...

    [GenerateFile::FromShareDir / Generate CODE_OF_CONDUCT.md]
    -dist     = Dist-Zilla-PluginBundle-DROLSKY
    -filename = CODE_OF_CONDUCT.md

    [InstallGuide]
    [CPANFile]

    ; Only added if the distro has .xs files
    [PPPort]

    ; Like the default License plugin except that it defaults to Artistic 2.0.
    ; Also, if the copyright_year for the bundle is not this year, it passes
    ; something like "2014-2016" to Software::License.
    [DROLSKY::License]

    [CheckPrereqsIndexed]
    [EnsureChangesHasContent]

    ; Just like Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch except that
    ; it allows releases from any branch for TRIAL
    ; releases. https://github.com/RsrchBoy/dist-zilla-pluginbundle-git-checkfor/issues/24
    [DROLSKY::Git::CheckFor::CorrectBranch]

    [Git::CheckFor::MergeConflicts]

    ; Generates/updates perlcriticrc, and perltidyrc
    [DROLSKY::PerlLinterConfigFiles]
    ; Generates/updates precious.toml
    [DROLSKY::Precious]
    ; Generates some dev tool helper scripts when using precious.
    [DROLSKY::DevTools]

    ; The allow_dirty list is basically all of the generated or munged files
    ; in the distro, including:
    ;     Build.PL
    ;     CODE_OF_CONDUCT.md
    ;     CONTRIBUTING.md
    ;     Changes
    ;     LICENSE
    ;     Makefile.PL
    ;     README.md
    ;     cpanfile
    ;     ppport.h
    ;     precious.toml
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

Bugs may be submitted at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY/issues>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-DROLSKY can be found at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<https://www.urth.org/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Mark Fowler

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Mark Fowler <mark@twoshortplanks.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2021 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
