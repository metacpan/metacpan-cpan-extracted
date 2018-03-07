#
# This file is part of Dist-Zilla-PluginBundle-RSRCHBOY
#
# This software is Copyright (c) 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::PluginBundle::RSRCHBOY;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.076-1-gc984c68
$Dist::Zilla::PluginBundle::RSRCHBOY::VERSION = '0.077';

# ABSTRACT: Zilla your distributions like RSRCHBOY!

use utf8;
use v5.18;

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use Moose::Util::TypeConstraints;

use autodie 0.20;
use autobox::Core;

use Dist::Zilla;
with
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.102' },
    'Dist::Zilla::Role::PluginBundle::Config::Slicer',
    ;

use Config::MVP::Slicer 0.302;
use Path::Class;

has github_user     => (is => 'lazy', isa => 'Str', builder => sub { 'rsrchboy' });
has set_github_user => (is => 'lazy', isa => 'Str', builder => sub { 1 }         );

# FIXME this next section is kinda... ugly

has is_app     => (is => 'lazy', isa => 'Bool');
has is_private => (is => 'lazy', isa => 'Bool');

sub _build_is_app     { $_[0]->payload->{cat_app} || $_[0]->payload->{app} }
sub _build_is_private { $_[0]->payload->{private}                          }

{
    my $_builder_for = sub { my $key = shift; sub { shift->payload->{$key} // 1 } };

    has $_ => (
        traits  => ['Bool'],
        is      => 'lazy',
        isa     => 'Bool',
        builder => $_builder_for->($_),
        handles => { "no_$_" => 'not' },
    )
    for qw{ sign tweet github install_on_release }
    ;
}

has is_task => (
    traits  => ['Bool'],
    is      => 'lazy',
    isa     => 'Bool',
    builder => sub { shift->payload->{task} },
    handles => { is_not_task => 'not' },
);

has _copy_from_build => (
    is      => 'lazy',
    isa     => 'ArrayRef[Str]',
    builder => sub {
        my ($self) = @_;

        my @copy = (qw{ LICENSE });
        push @copy, 'Makefile.PL'
            if $self->is_app;

        return [ @copy ];
    },
);


sub release_plugins {
    my $self = shift @_;

    my @allow_dirty = qw{
        .gitignore
        .travis.yml
        Changes
        README.mkdn
        dist.ini
        weaver.ini
    };
    push @allow_dirty, $self->_copy_from_build->flatten;


    my @plugins = (
        qw{
            TestRelease
            CheckChangesHasContent
            CheckPrereqsIndexed
        },
        [ 'Git::Remote::Update' => GitFetchOrigin  => {
            remote_name   => 'origin',
            do_update     => 1,
        } ],
        [ 'Git::Remote::Check' => GitCheckReleaseBranchSync  => {
            remote_name   => 'origin',
            do_update     => 0,
            branch        => 'release/cpan',
            remote_branch => 'release/cpan',
        } ],
        [ 'Git::Remote::Check' => GitCheckMasterBranchSync => {
            remote_name   => 'origin',
            do_update     => 0,
            branch        => 'master',
            remote_branch => 'master',
        } ],
        [ 'Git::Check'      => { allow_dirty => [ @allow_dirty ] } ],
        [ 'Git::Commit'     => { allow_dirty => [ @allow_dirty ] } ],

        [ 'Test::CheckDeps' => { ':version' => '0.007', fatal => 1, level => 'suggests' } ],
        'CheckSelfDependency',
        'Travis::ConfigForReleaseBranch',
        'SchwartzRatio',

        [ 'Git::Tag' => { tag_format  => '%v', signed => $self->sign } ],

        $ENV{TRAVIS} ? () : (
            [ 'Git::CommitBuild' => 'Git::CommitBuild::Build' => { } ],
            [ 'Git::CommitBuild' => 'Git::CommitBuild::Release' => {
                release_branch       => 'release/cpan',
                release_message      => 'Full build of CPAN release %v%t',
                multiple_inheritance => 1,
            }],
        ),

        [ 'Git::Push' => {
            push_to => [
                'origin',
                'origin refs/heads/release/cpan:refs/heads/release/cpan',
            ],
        }],

        $self->no_tweet ? () : [
            Twitter => {
                hash_tags => '#perl #cpan',
                # TODO: remove the next line when resolved:
                # https://github.com/dagolden/dist-zilla-plugin-twitter/issues/11
                tweet_url => 'https://metacpan.org/release/{{$AUTHOR_UC}}/{{$DIST}}-{{$VERSION}}{{$TRIAL}}/',
            },
        ],

        $self->is_private            ? () : 'UploadToCPAN',
        $self->no_sign               ? () : 'Signature',
        $self->no_install_on_release ? () : [ InstallRelease   => { install_command => 'cpanm .' } ],
        $self->no_github             ? () : [ 'GitHub::Update' => { metacpan        => 1         } ],

        [ 'Run::AfterRelease' => { run => 'mkdir -p releases ; mv %s releases/' } ],

        'ConfirmRelease',
    );

    return @plugins;
}


sub author_tests {
    my ($self) = @_;

    return (
        [ 'Test::PodSpelling' => { stopwords => [ $self->stopwords ] } ],
        qw{
            ConsistentVersionTest
            PodCoverageTests
            PodSyntaxTests
            Test::NoTabs
            Test::EOL
            HasVersionTests
            Test::Compile
            NoSmartCommentsTests
            Test::Pod::LinkCheck
            RunExtraTests
        },
        [ 'Test::MinimumVersion' => { max_target_perl => '5.020000' } ],
    );
}


sub meta_provider_plugins {
    my ($self) = @_;

    my @plugins = (
        [ Authority => { authority => 'cpan:RSRCHBOY' } ],
        qw{ MetaConfig MetaJSON MetaYAML },
        [ MetaNoIndex => { directory => [ qw{ corpus t } ] } ],
        'MetaProvides::Package',

        'MetaData::BuiltWith',
    );

    if ($self->github) {

        my $opts = { issues => 1 };

        $opts->{user} = $self->github_user
            if $self->set_github_user;

        push @plugins, [ GithubMeta => $opts ]
    }

    return @plugins;
}


sub configure {
    my $self = shift @_;

    my $autoprereq_opts = $self->config_slice({ autoprereqs_skip => 'skip' });
    my $prepender_opts  = $self->config_slice({ prepender_skip   => 'skip' });

    # if we have a weaver.ini, use that; otherwise use our bundle
    my $podweaver
        = file('weaver.ini')->stat
        ? 'PodWeaver'
        : [ PodWeaver => { config_plugin => '@RSRCHBOY' } ]
        ;

    $self->add_plugins(
        [ NextRelease => { format => '%-8V  %{yyyy-MM-dd HH:mm:ss ZZZZ}d' }],
    );

    $self->add_plugins([ 'Git::NextVersion' =>
        #;first_version = 0.001       ; this is the default
        #;version_regexp  = ^v(.+)$   ; this is the default
        { version_regexp => '^(\d.\d+(_\d\d)?)(-TRIAL|)$' },
    ]);

    $self->add_plugins(qw{
        CopyrightYearFromGit
        ContributorsFromGit
    });

    $self->add_bundle('Git::CheckFor');

    $self->add_plugins(
        [ 'Git::GatherDir' => { exclude_filename => $self->_copy_from_build } ],
        [
            PromptIfStale => {
                phase   => 'build',
                modules => [ qw{
                    Dist::Zilla
                    Dist::Zilla::PluginBundle::RSRCHBOY
                }],
            },
        ],

        # this will be added by another plugin to the build
        [ PruneCruft => { except => '\.travis\.yml' } ],

        qw{
            Git::Describe
            ExecDir
            ShareDir
            MakeMaker
            Manifest
            SurgicalPkgVersion
            MinimumPerl
            Test::ReportPrereqs
        },
        [ AutoPrereqs => $autoprereq_opts ],
        [ Prepender   => $prepender_opts  ],

        # These are requirements that will be inserted on the generated dist,
        # that indicate that for develop phase (e.g. author/release testing)
        # certain additional packages are required for full exercise of xt/
        [ Prereqs => AuthorBundleDevelopRequires => {
            -phase        => 'develop',
            -relationship => 'requires',

            # TODO: drop when this is merged and released:
            # https://github.com/marcel-maint/Dist-Zilla-Plugin-HasVersionTests/pull/2
            'Test::HasVersion'        => 0,

            # TODO: drop when this is merged and released:
            # https://github.com/doherty/Dist-Zilla-Plugin-Test-MinimumVersion/pull/7
            'Test::MinimumVersion'    => 0,

            'Test::ConsistentVersion' => 0,
        } ],

        $self->author_tests,
        $self->meta_provider_plugins,
        $self->release_plugins,

        'License',
        'CPANFile',

        [ ReadmeAnyFromPod  => ReadmeMarkdownInRoot => {
            type     => 'markdown',
            filename => 'README.mkdn',
            location => 'root',
        }],
        [ ReadmeAnyFromPod  => ReadmeTxt => {
            type     => 'text',
            filename => 'README',
        }],
        [ CopyFilesFromBuild => { copy => $self->_copy_from_build } ],

        [ 'GitHubREADME::Badge' => { badges => [ qw{ travis cpants coveralls } ] } ],

        ($self->is_task ? 'TaskWeaver' : $podweaver),
    );

    return;
}


sub stopwords {

    return qw{
        ABEND
        AFAICT
        Formattable
        Gratipay
        PayPal
        RSRCHBOY
        RSRCHBOY's
        codebase
        coderef
        formattable
        gpg
        implementers
        ini
        metaclass
        metaclasses
        parameterization
        parameterized
        subclasses
    };
}

__PACKAGE__->meta->make_immutable;
!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Bowers Neil Romanov Sergey

=head1 NAME

Dist::Zilla::PluginBundle::RSRCHBOY - Zilla your distributions like RSRCHBOY!

=head1 VERSION

This document describes version 0.077 of Dist::Zilla::PluginBundle::RSRCHBOY - released March 05, 2018 as part of Dist-Zilla-PluginBundle-RSRCHBOY.

=head1 SYNOPSIS

    # in your dist.ini...
    [@RSRCHBOY]

=head1 DESCRIPTION

This is RSRCHBOY's current L<Dist::Zilla> C<dist.ini> config for his packages.
He's still figuring this all out.  It's like vim, you never really know all
the things.

If you'd like to see what this does without digging into the guts, I recommend
you install the most excellent L<Dist::Zilla::App::Command::dumpphases>
package.  This will give you a new dzil command, allowing you to see a
sensible dump of what plugins are going to be used, etc.

=head1 METHODS

=head2 release_plugins

Plugin configuration for public release.

=head2 author_tests

=head2 meta_provider_plugins

Plugins that mess about with what goes into META.*.

=head2 configure

Preps plugin lists / config; see L<Dist::Zilla::Role::PluginBundle::Easy>.

=head2 stopwords

A list of words our POD spell checker should ignore.

=for Pod::Coverage configure

=head1 OPTIONS

=head2 sign (boolean; default: true)

On release, use your gpg key to sign the version tag created (if you're using
git) and also generate a SIGNATURE file.

See also L<Dist::Zilla::Plugin::Signature>.

=head2 tweet (boolean; default: true)

If set to a true value, we'll use L<Dist::Zilla::Plugin::Twitter> to tweet
when a release occurs.

=head2 github (boolean; default: true)

This enables various GitHub related plugins to update distribution and GitHub
metadata automatically.

=head2 install_on_release (boolean; default: true)

After a release, install the distribution locally. Our default install command
is (from inside the built release directory):

    cpanm .

You can change this by setting the C<InstallRelease.install_command> option.

=head1 BUNDLED PLUGIN OPTIONS

It's possible to pass options to our bundled plugins directly:

    ; format is Plugin::Name.option
    [@RSRCHBOY]
    GatherDir.exclude_filename = cpanfile

For information on specific plugins and their options, you should refer to the
documentation of L<Dist::Zilla::Role::PluginBundle::Config::Slicer>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::App::Command::dumpphases|Dist::Zilla::App::Command::dumpphases>

=item *

L<Dist::Zilla::Role::PluginBundle::PluginRemover|Dist::Zilla::Role::PluginBundle::PluginRemover>

=item *

L<Dist::Zilla::Role::PluginBundle::Config::Slicer|Dist::Zilla::Role::PluginBundle::Config::Slicer>

=item *

L<Config::MVP::Slicer|Config::MVP::Slicer>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/rsrchboy/dist-zilla-pluginbundle-rsrchboy/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 CONTRIBUTORS

=for stopwords Neil Bowers Sergey Romanov

=over 4

=item *

Neil Bowers <neil@bowers.com>

=item *

Sergey Romanov <complefor@rambler.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
