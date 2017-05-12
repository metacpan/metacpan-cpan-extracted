package Dist::Zilla::PluginBundle::Author::CHIM;

# ABSTRACT: Dist::Zilla configuration the way CHIM does it
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY
our $VERSION = '0.052005'; # VERSION

use strict;
use warnings;
use Moose;

use Dist::Zilla;

with qw(
    Dist::Zilla::Role::PluginBundle::Easy
    Dist::Zilla::Role::PluginBundle::PluginRemover
);

has dist => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    default  => sub { $_[0]->payload->{dist} },
);

has no_git => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default  => sub { $_[0]->payload->{no_git} || 0 },
);


sub mvp_multivalue_args {
    return qw(
        MetaNoIndex.directory
        MetaNoIndex.package
        MetaNoIndex.namespace
        MetaNoIndex.file
        GatherDir.exclude_match
        GitCheck.allow_dirty
        GithubMeta.remote
        PodWeaver.config_plugin
    );
}

sub configure {
    my ($self) = @_;

    my $meta_no_index__options = {
        directory => [(
            @{ $self->payload->{'MetaNoIndex.directory'} || [] },
            qw( t xt eg examples corpus )
        )],
        package => [(
            @{ $self->payload->{'MetaNoIndex.package'} || [] },
            qw( DB )
        )],
        namespace => [(
            @{ $self->payload->{'MetaNoIndex.namespace'} || [] },
            qw( t::lib )
        )],
        ( $self->payload->{'MetaNoIndex.file'}
            ? ( file => $self->payload->{'MetaNoIndex.file'} )
            : ( )
        ),
    };

    my $gather_dir__options = {
        ( $self->payload->{'GatherDir.exclude_match'}
            ? ( 'exclude_match' => $self->payload->{'GatherDir.exclude_match'} )
            : ( )
        ),
    };

    my $github_meta__options = {
        'homepage'  => $self->payload->{'GithubMeta.homepage'} ||
                            'https://metacpan.org/release/' . $self->dist,
        'remote'    => $self->payload->{'GithubMeta.remote'} ||
                            [qw( origin github gh )],
        'issues'    => $self->payload->{'GithubMeta.issues'} || 1,
        ( $self->payload->{'github.user'} ?
            ( 'user' => $self->payload->{'github.user'} ) : ( )
        ),
        ( $self->payload->{'github.repo'} ?
            ( 'repo' => $self->payload->{'github.repo'} ) : ( )
        ),
    };

    $self->add_plugins(
        # version provider
        (
            $self->no_git
            ? ()
            : [ 'Git::NextVersion' => {
                    ':version'       => '2.023',
                    'version_regexp' => $self->payload->{'GitNextVersion.version_regexp'} ||
                                        '^([\d._]+)(-TRIAL)?$'
                }
            ]
        ),
        [ 'GatherDir' => $gather_dir__options ],
        [ 'PruneCruft' => {} ],

        # modified files
        [ 'OurPkgVersion' => {} ],

        [ 'PodWeaver' => {
                'config_plugin' => $self->payload->{'PodWeaver.config_plugin'} || '@CHIM',
            }
        ],
        [ 'NextRelease' => {
                'time_zone' => $self->payload->{'NextRelease.time_zone'} ||
                                    'UTC',
                'format'    => $self->payload->{'NextRelease.format'} ||
                                    '%-7v %{EEE MMM d HH:mm:ss yyyy ZZZ}d'
            }
        ],
        [ 'Authority' => {
                'authority'      => $self->payload->{'authority'} || 'cpan:CHIM',
                'do_metadata'    => 1,
                'locate_comment' => 1,
            }
        ],

        # generated files
        [ 'License' => {} ],

        # README
        [ 'ReadmeAnyFromPod' =>
            'ReadmeInBuild' => {
                'type'     => 'text',
                'filename' => 'README',
                'location' => 'build',
            },
        ],

        # README.md
        [ 'ReadmeAnyFromPod' =>
            'ReadmeMdInRoot' => {
                'type'     => 'markdown',
                'filename' => 'README.md',
                'location' => 'root',
            },
        ],

        [ 'TravisCI::StatusBadge' => {
                ':version'  => '0.005',
                'vector'    => 1,
            },
        ],

        [ 'MetaNoIndex' => $meta_no_index__options ],

        [ 'GithubMeta' => $github_meta__options ],

        # add 'provides' to META
        [ 'MetaProvides::Package' => { 'meta_noindex' => 1 } ],

        # META files
        [ 'MetaYAML' => {} ],
        [ 'MetaJSON' => {} ],

        # t tests
        [ 'Test::Compile' => { 'fake_home' => 1 } ],

        # xt tests
        [ 'MetaTests' => {} ],
        [ 'PodSyntaxTests' => {} ],
        [ 'PodCoverageTests' => {} ],
        [ 'Test::Version' => {} ],
        [ 'Test::Kwalitee' => {} ],
        [ 'Test::EOL' => {} ],
        [ 'Test::NoTabs' => {} ],

        # build
        [ 'MakeMaker' => {} ],
        [ 'Manifest' => {} ],

        # run tests at xt/ on dzil test
        [ 'RunExtraTests' => { default_jobs => 7 } ],

        (
            $self->no_git
            ? ()
            : [ 'Git::Check' => {
                    'allow_dirty' => $self->payload->{'GitCheck.allow_dirty'} ||
                                        [qw( dist.ini Changes )],
                    'untracked_files' => $self->payload->{'GitCheck.untracked_files'} ||
                                        'die',
                }
            ]
        ),

        # release
        [ 'ConfirmRelease' => {} ],
        [ ( $ENV{FAKE} || $self->payload->{'fake_release'} ? 'FakeRelease' : 'UploadToCPAN' ) => {} ],

        (
            $self->no_git
            ? ()
            : (
                [ 'Git::Commit' => {
                        'commit_msg' => $self->payload->{'GitCommit.commit_msg'} ||
                                            'bump Changes v%v%t [ci skip]',
                    }
                ],
                [ 'Git::Tag' => {
                        'tag_format' => $self->payload->{'GitTag.tag_format'} ||
                                            '%v%t',
                        'tag_message' => $self->payload->{'GitTag.tag_message'} ||
                                            'release v%v%t',
                    }
                ]
            )
        ),
    );
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::CHIM - Dist::Zilla configuration the way CHIM does it

=head1 VERSION

version 0.052005

=head1 DESCRIPTION

This is a L<Dist::Zilla> PluginBundle. It is roughly equivalent to the
following dist.ini:

    [Git::NextVersion]
    version_regexp = ^([\d._]+)(-TRIAL)?$

    [GatherDir]
    [PruneCruft]

    ;; modified files
    [OurPkgVersion]

    [PodWeaver]
    config_plugin = @CHIM

    [NextRelease]
    time_zone = UTC
    format    = %-7v %{EEE MMM d HH:mm:ss yyyy ZZZ}d
    [Authority]
    authority      = %{authority}
    do_metadata    = 1
    locate_comment = 1

    ;; generated files
    [License]

    [ReadmeAnyFromPod / ReadmeInBuild]
    type     = text
    filename = README
    location = build

    [ReadmeAnyFromPod / ReadmeMdInRoot]
    type     = markdown
    filename = README.md
    location = root

    [TravisCI::StatusBadge]
    vector = 1

    [MetaNoIndex]
    directory = t
    directory = xt
    directory = eg
    directory = examples
    directory = corpus
    package   = DB
    namespace = t::lib

    [GithubMeta]
    homepage = https://metacpan.org/release/%{dist}
    remote = origin
    remote = github
    remote = gh
    issues = 1

    ;; add 'provides' to META
    [MetaProvides::Package]
    meta_noindex = 1

    ;; META files
    [MetaYAML]
    [MetaJSON]

    ;; t tests
    [Test::Compile]
    fake_home = 1

    ;; xt tests
    [MetaTests]
    [PodSyntaxTests]
    [PodCoverageTests]
    [Test::Version]
    [Test::Kwalitee]
    [Test::EOL]
    [Test::NoTabs]

    ;; build
    [MakeMaker]
    [Manifest]

    ;; run tests at xt/ on dzil test
    [RunExtraTests]
    default_jobs = 7

    [Git::Check]
    allow_dirty = dist.ini
    allow_dirty = Changes
    untracked_files = die

    ;; release
    [ConfirmRelease]
    [UploadToCPAN]

    [Git::Commit]
    commit_msg = bump Changes v%v%t [ci skip]

    [Git::Tag]
    tag_format = %v%t
    tag_message = release v%v%t

=for Pod::Coverage mvp_multivalue_args

=head1 SYNOPSYS

    # in dist.ini
    [@Author::CHIM]
    dist            = My-Very-Cool-Module
    authority       = cpan:CHIM
    github.user     = Wu-Wu

=head1 OPTIONS

=head2 -remove

Removes a plugin. Might be used multiple times.

    [@Author::CHIM]
    -remove = PodCoverageTests
    -remove = Test::Kwalitee

=head2 dist

The name of the distribution. Required.

=head2 no_git

Boolean. When C<true> - all git-related plugins will be skipped. Default value is C<false>.

=head2 authority

This one is used to set name the CPAN author of the distibution. It should be something like C<cpan:PAUSEID>.
Default value is C<cpan:CHIM>.

=head2 github.user

Indicates github.com's account name. Default value is C<Wu-Wu>. Used by L<Dist::Zilla::Plugin::GithubMeta>
and L<Dist::Zilla::Plugin::TravisCI::StatusBadge>.

=head2 github.repo

Indicates github.com's repository name. Default value is set to value of the L</dist> option.
Used by L<Dist::Zilla::Plugin::GithubMeta> and L<Dist::Zilla::Plugin::TravisCI::StatusBadge>.

=head2 NextRelease.time_zone

Timezone for entries in B<Changes> file. Default value is C<UTC>.

See more at L<Dist::Zilla::Plugin::NextRelease>.

=head2 NextRelease.format

Format of entry in I<Changes> file. Default value is C<%-7v %{EEE MMM d HH:mm:ss yyyy ZZZ}d>.

See more at L<Dist::Zilla::Plugin::NextRelease>.

=head2 MetaNoIndex.directory

Exclude directories (recursively with files) from indexing by PAUSE/CPAN. Default values:
C<t>, C<xt>, C<eg>, C<examples>, C<corpus>. Allowed multiple values, e.g.

    MetaNoIndex.directory = foo/bar
    MetaNoIndex.directory = quux/bar/foo

See more at L<Dist::Zilla::Plugin::MetaNoIndex>.

=head2 MetaNoIndex.namespace

Exclude stuff under the namespace from indexing by PAUSE/CPAN. Default values: C<t::lib>. Allowed
multiple values, e.g.

    MetaNoIndex.namespace = Foo::Bar
    MetaNoIndex.namespace = Quux::Foo

See more at L<Dist::Zilla::Plugin::MetaNoIndex>.

=head2 MetaNoIndex.package

Exclude the package name from indexing by PAUSE/CPAN. Default values: C<DB>. Allowed
multiple values, e.g.

    MetaNoIndex.package = Foo::Bar

See more at L<Dist::Zilla::Plugin::MetaNoIndex>.

=head2 MetaNoIndex.file

Exclude specific filename from indexing by PAUSE/CPAN. No defaults. Allowed
multiple values, e.g.

    MetaNoIndex.file = lib/Foo/Bar.pm

See more at L<Dist::Zilla::Plugin::MetaNoIndex>.

=head2 GatherDir.exclude_match

Regular expression pattern which causes not to gather matched files. No defaults. Allowed
multiple values, e.g.

    GatherDir.exclude_match = ^foo.*
    GatherDir.exclude_match = ^ba(r|z)\/qux.*

See more at L<Dist::Zilla::Plugin::GatherDir>.

=head2 GitNextVersion.version_regexp

Regular expression that matches a tag containing a version. Default value is C<^([\d._]+)(-TRIAL)?$>.

See more at L<Dist::Zilla::Plugin::Git::NextVersion>.

=head2 GitTag.tag_format

Format of the tag to apply. Default value is C<%v%t>.

See more at L<Dist::Zilla::Plugin::Git::Tag>.

=head2 GitTag.tag_message

Format of the tag annotation. Default value is C<release v%v%t>.

See more at L<Dist::Zilla::Plugin::Git::Tag>.

=head2 GitCommit.commit_msg

The commit message to use in commit after release. Default value is C<bump Changes v%v%t [ci skip]>.

See more at L<Dist::Zilla::Plugin::Git::Commit>.

=head2 GitCheck.allow_dirty

File that is allowed to have local modifications. This option may appear multiple times. The default
list is C<dist.ini> and C<Changes>.

See more at L<Dist::Zilla::Plugin::Git::Check>.

=head2 GitCheck.untracked_files

The commit message to use in commit after release. Default value is C<die>.

See more at L<Dist::Zilla::Plugin::Git::Check>.

=head2 GithubMeta.homepage

Homepage of the distribution. Default value is C<https://metacpan.org/release/%{dist}>.

See more at L<Dist::Zilla::Plugin::GithubMeta>.

=head2 GithubMeta.remote

Remote names to inspect for github repository. Default values are C<origin>, C<github>, C<gh>. You can
provide multiple remote names

    [@Author::CHIM]
    GithubMeta.remote = foo
    GithubMeta.remote = bar

See more at L<Dist::Zilla::Plugin::GithubMeta>.

=head2 GithubMeta.issues

Inserts a bugtracker url to metadata. Default value is C<1>.

See more at L<Dist::Zilla::Plugin::GithubMeta>.

=head2 PodWeaver.config_plugin

Configuration of L<Pod::Weaver>. This option may appear multiple times. Default value is C<@CHIM>.

See more at L<Dist::Zilla::Plugin::PodWeaver> and L<Pod::Weaver::PluginBundle::CHIM>.

=head1 METHODS

=head2 configure

Bundle's configuration for role L<Dist::Zilla::Role::PluginBundle::Easy>.

=head1 FAKE RELEASE

Use option C<fake_release> in bundle configuration:

    [@Author::CHIM]
    ...
    fake_release = 1

or environment variable C<FAKE>:

    FAKE=1 dzil release

The distribution won't actually uploaded to the CPAN if option or variable will found.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla|Dist::Zilla>

=item *

L<Dist::Zilla::Role::PluginBundle::Easy|Dist::Zilla::Role::PluginBundle::Easy>

=item *

L<Dist::Zilla::Plugin::Authority|Dist::Zilla::Plugin::Authority>

=item *

L<Dist::Zilla::Plugin::MetaNoIndex|Dist::Zilla::Plugin::MetaNoIndex>

=item *

L<Dist::Zilla::Plugin::NextRelease|Dist::Zilla::Plugin::NextRelease>

=item *

L<Dist::Zilla::Plugin::GatherDir|Dist::Zilla::Plugin::GatherDir>

=item *

L<Dist::Zilla::Plugin::Git|Dist::Zilla::Plugin::Git>

=item *

L<Dist::Zilla::Plugin::TravisCI::StatusBadge|Dist::Zilla::Plugin::TravisCI::StatusBadge>

=item *

L<Dist::Zilla::Plugin::GithubMeta|Dist::Zilla::Plugin::GithubMeta>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/Wu-Wu/Dist-Zilla-PluginBundle-Author-CHIM/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
