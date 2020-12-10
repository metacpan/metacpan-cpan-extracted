package Dist::Zilla::PluginBundle::Author::WATERKIP;
use Moose;

# ABSTRACT: An plugin bundle for all distributions by WATERKIP
# KEYWORDS: author bundle distribution tool

use Data::Dumper;
use List::Util qw(uniq any first);
use Moose::Util::TypeConstraints qw(enum subtype where);
use namespace::autoclean;

our $VERSION = '2.9';

with
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::Airplane',
    'Dist::Zilla::Role::PluginBundle::PluginRemover' =>
    { -version => '0.103' },
    'Dist::Zilla::Role::PluginBundle::Config::Slicer';

has server => (
    is       => 'ro',
    isa      => enum([qw(github bitbucket gitlab none)]),
    init_arg => undef,
    lazy     => 1,
    default  => sub { $_[0]->payload->{server} // 'gitlab' },
);

has license => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    default  => sub { $_[0]->payload->{license} // 'LICENSE' },
);

has exclude_files => (
    isa      => 'ArrayRef[Str]',
    init_arg => undef,
    lazy     => 1,
    default  => sub { $_[0]->payload->{exclude_files} // [] },
    traits   => ['Array'],
    handles => { exclude_files => 'elements' },
);

around exclude_files => sub {
    my $orig = shift;
    my $self = shift;
    sort(uniq(
            $self->$orig(@_),
            qw(Dockerfile .gitlab-ci.yml docker-compose.yml docker-compose.override.yml .dockerignore dev-bin/cpanm)
    ));
};

has copy_file_from_build => (
    isa      => 'ArrayRef[Str]',
    init_arg => undef,
    lazy     => 1,
    default  => sub { $_[0]->payload->{copy_file_from_build} // [] },
    traits   => ['Array'],
    handles => { copy_files_from_build => 'elements' },
);

around copy_files_from_build => sub {
    my $orig = shift;
    my $self = shift;
    sort(uniq(
            $self->$orig(@_),
            qw(Makefile.PL cpanfile Build.PL README README.md CONTRIBUTORS),
            $self->license
    ));
};

has copy_file_from_release => (
    isa      => 'ArrayRef[Str]',
    init_arg => undef,
    lazy     => 1,
    default  => sub { $_[0]->payload->{copy_file_from_release} // [] },
    traits   => ['Array'],
    handles => { copy_files_from_release => 'elements' },
);

sub mvp_multivalue_args { qw(copy_file_from_build copy_file_from_release exclude_files) }

around copy_files_from_release => sub {
    my $orig = shift;
    my $self = shift;
    sort(uniq(
            $self->$orig(@_),
            qw(CONTRIBUTING ppport.h INSTALL)
    ));
};

has debug => (
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    lazy     => 1,
    default =>
        sub { $ENV{DZIL_AUTHOR_DEBUG} // $_[0]->payload->{debug} // 0 },
);

has upload_to => (
    is       => 'ro',
    isa      => enum([qw(cpan pause stratopan local)]),
    init_arg => undef,
    lazy     => 1,
    default  => sub { $_[0]->payload->{upload_to} // 'cpan' },
);

has authority => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        $self->payload->{authority} // 'cpan:WATERKIP';
    },
);

has fake_release => (
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    lazy     => 1,
    default =>
        sub { $ENV{FAKE_RELEASE} // $_[0]->payload->{fake_release} // 0 },
);

has changes_version_columns => (
    is       => 'ro',
    isa      => subtype('Int', where { $_ > 0 && $_ < 20 }),
    init_arg => undef,
    lazy     => 1,
    default => sub { $_[0]->payload->{changes_version_columns} // 10 },
);

sub _warn_me {
    my $msg = shift;
    warn(sprintf("[\@Author::WATERKIP]  %s\n", $msg));
}

sub commit_files_after_release {
    my $self = shift;
    grep { -e }
        sort(uniq('README.pod', 'Changes', $self->copy_files_from_release, $self->copy_files_from_build));
}

sub build_network_plugins {
    return [qw(
        PromptIfStale
        Test::Pod::LinkCheck
        Test::Pod::No404s
        Git::Remote::Check
        CheckPrereqsIndexed
        CheckIssues
        UploadToCPAN
        UploadToStratopan
        Git::Push
    )];
};

my %removed;

sub release_option {
    my $self = shift;
    if ($self->fake_release) {
        _warn_me("Fake release has been set");
        return 'FakeRelease';
    }
    if ($self->upload_to eq 'stratopan') {
        _warn_me("Stratopan release has been set");
        my $prefix = 'stratopan';
        return [
            'UploadToStratopan' => {
                repo    => $self->payload->{"$prefix.repo"},
                stack   => $self->payload->{"$prefix.stack"},
                recurse => $self->payload->{"$prefix.recurse"},
            }
            ],
            ;
    }
    return 'UploadToCPAN';
}

sub configure {
    my $self = shift;

    if ($self->debug) {
        _warn_me(Dumper { payload => $self->payload, });
    }

    if (!-d '.git' and -f 'META.json' and !exists $removed{'Git::GatherDir'})
    {
        _warn_me(
            '.git is missing and META.json is present -- this looks like a CPAN download rather than a git repository. You should probably run '
                . (
                -f 'Build.PL'
                ? 'perl Build.PL; ./Build'
                : 'perl Makefile.PL; make'
                )
                . ' instead of using dzil commands!',
        );
    }

    my @plugins = (

        [
            'Git::GatherDir' => {
                do {
                    my @filenames = uniq(
                        grep { -e } $self->copy_files_from_release,
                        $self->copy_files_from_build,
                        $self->exclude_files,
                    );
                    @filenames ? (exclude_filename => \@filenames) : ();
                },
            },
        ],

        [
            'PromptIfStale' => 'stale modules, build' =>
                { phase => 'build', module => [$self->meta->name] }
        ],
        [
            'PromptIfStale' => 'stale modules, release' => {
                phase             => 'release',
                check_all_plugins => 1,
                check_all_prereqs => 1
            }
        ],

        qw(PruneCruft ManifestSkip MetaYAML MetaJSON),

        ['License' => { filename => $self->license }],

        ['ReadmeFromPod' => { type => 'markdown', readme => 'README.md' }],

        qw(ExecDir ShareDir MakeMaker Manifest
            TestRelease PodWeaver),

        ['Git::Contributors' => { order_by => 'commits' }],
        ['ContributorsFile'  => { filename => 'CONTRIBUTORS' }],

        ['AutoPrereqs'         => { skip       => [qw(^perl$ utf8 warnings strict overload)] }],
        ['Prereqs::AuthorDeps' => { ':version' => '0.006' }],
        [
            'MinimumPerl' => {
                ':version'       => '1.006',
                configure_finder => ':NoFiles'
            }
        ],
        ['MetaProvides::Package'],

        [
            'Encoding' => [
                encoding => 'bytes',
                match    => '\.ico$',
                match    => '\.docx?$',
                match    => '\.zip$',
                match    => '\.ztb$', # Mintlab specific, just a zip file
                match    => '\.pdf$',
                match    => '\.odt$',
                match    => '\.msg$',
            ]
        ],

        ['CPANFile'],

        [
            'CopyFilesFromBuild::Filtered' =>
                { copy => [$self->copy_files_from_build] }
        ],

        [ 'Git::Check' => 'initial check' => { allow_dirty => [ $self->airplane ? 'dist.ini' : '' ] } ],

        qw(Git::CheckFor::MergeConflicts),
        ['Git::Remote::Check' => { branch => 'master', remote_branch => 'master' } ],
        ['Git::CheckFor::CorrectBranch' =>
                { release_branch => 'master' }
        ],

        qw(CheckPrereqsIndexed),

        ['Repository'],
        ['ConfirmRelease'],

        # This plugin seems cool, but also unmaintained with downstream
        # deps which are also unmaintained. ABORT
        #[ 'PrereqsClean'],

        $self->release_option,

        [
            'CopyFilesFromRelease' =>
                { filename => [$self->copy_files_from_release] }
        ],
    );

    # Disable test::perl::critic as it messes with the version rewrite
    # that happens during a build
    # Also disable portability files as foo.conf.dist is not allowed :(
    $self->add_bundle(
        '@TestingMania' => {
            disable => [
                qw(
                    Test::Perl::Critic
                    Test::Portability::Files
                    Test::Portability
                )
            ]
        }
    );

    # plugins to do with calculating, munging, incrementing versions
    $self->add_bundle(
        '@Git::VersionManager' => {
            'RewriteVersion::Transitional.global' => 1,
            'RewriteVersion::Transitional.fallback_version_provider' =>
                'Git::NextVersion',
            'RewriteVersion::Transitional.version_regexp' =>
                '^v([\d._]+)(-TRIAL)?$',

            # for first Git::Commit
            commit_files_after_release => [$self->commit_files_after_release],

            # because of [Git::Check], only files copied from the release would
            # be added -- there is nothing else hanging around in the current
            # directory
            'release snapshot.add_files_in' => ['.'],
            'release snapshot.commit_msg'   => '%N-%v%t%n%n%c',

            'Git::Tag.tag_message' => 'v%v%t',

            'BumpVersionAfterRelease::Transitional.global' => 1,

            'NextRelease.:version'  => '5.033',
            'NextRelease.time_zone' => 'UTC',
            'NextRelease.format'    => '%-'
                . ($self->changes_version_columns - 2)
                . 'v  %{yyyy-MM-dd HH:mm:ss\'Z\'}d%{ (TRIAL RELEASE)}T',
        }
    );
    $self->add_plugins(@plugins);

}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::WATERKIP - An plugin bundle for all distributions by WATERKIP

=head1 VERSION

version 2.9

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Author::WATERKIP]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin bundle. It is somewhat equal to the
following F<dist.ini>:

    [Git::GatherDir]
    exclude_filename = .dockerignore
    exclude_filename = .gitlab-ci.yml
    exclude_filename = Dockerfile
    exclude_filename = docker-compose.override.yml
    exclude_filename = docker-compose.yml

    [PromptIfStale 'stale modules, build']
    phase = build
    module = ... ; lookup syntax

    [PruneCruft]
    [ManifestSkip]
    [MetaYAML]
    [MetaJSON]

    [License]
    filename = LICENSE

    [ReadmeFromPod]
    type = markdown
    readme = README.md

    [ExecDir]
    [ShareDir]
    [MakeMaker]
    [Manifest]
    [TestRelease]
    [PodWeaver]

    [Git::Contributors]
    order_by = commits

    [ContributesFile]
    filename = CONTRIBUTORS

    [AutoPrereqs]
    skip = ^perl$, utf8, warnings, strict, overload

    [Prereqs::AuthorDeps]
    [MinimumPerl]
    configure_finder = :NoFiles

    [MetaProvides::Package]

    [Encoding]
    encoding = bytes
    match = \.ico$
    match = \.docx?$
    match = \.zip$
    match = \.ztb$ ; Mintlab specific
    match = \.pdf$
    match = \.odt$

    [CPANFile]

    [CopyFilesFromBuild::Filtered]
    copy = cpanfile, Makefile.pl, CONTRIBUTORS, LICENSE, README.md

    [Git::Check 'initial check']
    allow_dirty = dist.ini; only if airplane mode is set

    [Git::CheckFor::MergeConflicts]
    [Git::Remote::Check]
    branch = master
    remote_branch = master

    [Git::CheckFor::CorrectBranch]
    release_branch = master

    [CheckPrereqsIndexed]

    [Repository]
    [ConfirmRelease]

    [CopyFilesFromRelease]
    filename = cpanfile, Makefile.pl, CONTRIBUTORS, LICENSE, README.md

    [@TestingMania]
    disable = Test::Perl::Critic
    disable = Test::Portability::Files
    disable = Test::Portability

    [@Git::VersionManager]
    RewriteVersion::Transitional.global = 1
    RewriteVersion::Transitional.fallback_version_provider = Git::NextVersion
    RewriteVersion::Transitional.version_regexp = ^v([\d._]+)(-TRIAL)?$

    commit_files_after_release = Changes LICENSE README.md

    release snapshot.add_files_in = .
    release snapshot.commit_msg = %N-%v%t%n%n%c

    Git::Tag.tag_message = v%v%t

    BumpVersionAfterRelease::Transitional.global = 1

    NextRelease.time_zone = UTC
    NextRelease.format = %-8v  %{yyyy-MM-dd HH:mm:ss\'Z\'}d%{ (TRIAL RELEASE)}T'

=head1 METHODS

=head2 configure

Configure the author plugin

=head2 commit_files_after_release

Commit files after a release

=head2 release_option

Define the release options. Choose between:

C<cpan> or C<stratopan>. When fake release is used, this overrides these two options

=head2 build_network_plugins

Builder for network plugins

=head1 SEE ALSO

I took inspiration from L<Dist::Zilla::PluginBundle::Author::ETHER>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Wesley Schwengle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
