use strict;
use warnings;
use feature 'switch';
use utf8;

package Dist::Zilla::PluginBundle::Author::RTHOMPSON;
# ABSTRACT: RTHOMPSON's Dist::Zilla Configuration
$Dist::Zilla::PluginBundle::Author::RTHOMPSON::VERSION = '0.161990';
use Moose;
use Carp;
with 'Dist::Zilla::Role::PluginBundle::Easy';
with 'Dist::Zilla::Role::PluginBundle::Config::Slicer';
with 'Dist::Zilla::Role::PluginBundle::PluginRemover';

sub mvp_multivalue_args { qw( copy_file move_file allow_dirty ) }

# Returns true for strings of 'true', 'yes', or positive numbers,
# false otherwise.
sub _parse_bool {
    $_ ||= '';
    return 1 if $_[0] =~ m{^(true|yes|1)$}xsmi;
    return if $_[0] =~ m{^(false|no|0)$}xsmi;
    die "Invalid boolean value $_[0]. Valid values are true/yes/1 or false/no/0";
}

sub configure {
    my $self = shift;

    my $defaults = {
        # AutoVersion by default
        version => 'auto',
        # Assume that the module is experimental unless told
        # otherwise.
        version_major => 0,
        # Assume that synopsis is perl code and should compile
        # cleanly.
        synopsis_is_perl_code => 1,
        # Realease to CPAN for real
        release => 'real',
        # Archive releases
        archive => 1,
        archive_directory => 'releases',
        # version control system = git
        vcs => 'git',
        git_remote => 'origin',
        git_branch => 'master',
        allow_dirty => [ 'dist.ini', 'README.pod', 'Changes' ],
    };
    my %args = (%$defaults, %{$self->payload});

    # Add appropriate version plugin, if any
    if (lc($args{version}) eq 'auto') {
        $self->add_plugins(
            [ 'AutoVersion' => { major => $args{version_major} } ]
        );
    }
    elsif (grep { lc($args{version}) eq $_ } (qw(disable none false), q())) {
        delete $args{version};
    }
    else {
        $self->add_plugins(
            [ 'StaticVersion' => { version => $args{version} } ]
        );
    }

    # Copy/move files from build dir. The "copy_file" and "move_file"
    # arguments get passed to CopyFilesFromBuild as "copy" and "move"
    # respectively.
    my %cffb_opt_hash = ();
    for my $opt ("copy", "move") {
        if ($args{"${opt}_file"} and @{$args{"${opt}_file"}}) {
            $cffb_opt_hash{$opt} = $args{"${opt}_file"};
        }
    }
    if (keys %cffb_opt_hash) {
        $self->add_plugins([ 'CopyFilesFromBuild' => \%cffb_opt_hash ]);
    }

    # Decide whether to test SYNOPSIS for syntax.
    if (_parse_bool($args{synopsis_is_perl_code})) {
        $self->add_plugins('Test::Synopsis');
    }

    # Choose release plugin
    for ($args{release}) {
        if (lc eq 'real') {
            $self->add_plugins('UploadToCPAN')
        }
        elsif (lc eq 'fake') {
            $self->add_plugins('FakeRelease')
        }
        elsif (lc eq 'none') {
            # No release plugin
        }
        elsif ($_) {
            $self->add_plugins("$_")
        }
        else {
            # Empty string is the same as 'none'
        }
    }

    # Choose whether and where to archive releases
    if (_parse_bool($args{archive})) {
        $self->add_plugins(
            ['ArchiveRelease' => {
                directory => $args{archive_directory},
            } ]
        );
    }

    # All the invariant plugins
    $self->add_plugins(
        # @Basic
        'GatherDir',
        'PruneCruft',
        'ManifestSkip',
        'MetaYAML',
        'MetaJSON',
        'License',
        'ExecDir',
        'ShareDir',
        'MakeMaker',
        'Manifest',

        # Add provides section to META.yml
        'MetaProvides::Package',

        # Don't include the corpus directory, it's just for files that
        # tests will run on
        [ 'MetaNoIndex' => { dir => 'corpus' } ],

        # Mods
        'PkgVersion',
        # TODO: Only add PodWeaver if weaver.ini exists
        'PodWeaver',

        # Generated Docs
        'InstallGuide',
        ['ReadmeAnyFromPod', 'ReadmeTextInBuild'],
        # This one gets copied out of the build dir by default, and
        # does not become part of the dist.
        ['ReadmeAnyFromPod', 'ReadmePodInRoot ' => {
            phase => 'release',
        }],

        # Tests
        'Test::Perl::Critic',
        'PodCoverageTests',
        'PodSyntaxTests',
        'HasVersionTests',
        'Test::Portability',
        'Test::UnusedVars',
        ['Test::Compile' => {
            # The test files don't seem to compile in the context of
            # this test. But it's ok, because if they really have
            # problems, they'll fail to compile when they run.
            skip => 'Test$',
        }],
        'Test::Kwalitee',
        'ExtraTests',

        # Prerequisite checks
        'ReportVersions',
        'MinimumPerl',
        'AutoPrereqs',

        # Release checks
        'CheckChangesHasContent',
        'CheckPrereqsIndexed',
        'CheckVersionIncrement',

        # Release
        'NextRelease',
        'TestRelease',
    );

    # Choose version control. This must be after 'NextRelease' so that
    # the Changes file is updated before committing.
    for ($args{vcs}) {
        if (lc eq 'none') {
            # No-op
        }
        elsif (lc eq 'git') {
            $self->add_plugins(
                ['Git::Check' => {
                    allow_dirty => $args{allow_dirty},
                } ],
                [ 'Git::Commit' => {
                    allow_dirty => $args{allow_dirty},
                } ],
                'Git::Tag',
                # This can't hurt. It's a no-op if github is not involved.
                'GithubMeta',
            );
            if ($args{git_remote}) {
                if (! $args{no_check_remote} && $args{git_branch}) {
                    $self->add_plugins(
                        ['Git::Remote::Check' => {
                            remote_name => $args{git_remote},
                            branch => $args{git_branch},
                            remote_branch => $args{git_remote_branch} || $args{git_branch},
                        } ],
                    );
                }
                if (! $args{no_push}) {
                    $self->add_plugins(
                        ['Git::Push' => {
                            push_to => $args{git_remote},
                        } ],
                    );
                }
            }
        }
        else {
            croak "Unknown vcs: $_\nTry setting vcs = 'none' and setting it up yourself.";
        }
    }

    # This is added last so that the user is only asked for
    # confimation if *all* other pre-release checkpoints have been
    # passed.
    $self->add_plugins(
        'ConfirmRelease',
    );
}

1; # Magic true value required at end of module

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::Author::RTHOMPSON - RTHOMPSON's Dist::Zilla Configuration

=head1 VERSION

version 0.161990

=head1 SYNOPSIS

In dist.ini:

    [@Author::RTHOMPSON]

=head1 DESCRIPTION

This plugin bundle, in its default configuration, is equivalent to:

    [AutoVersion]
    major = 0
    [GatherDir]
    [PruneCruft]
    [ManifestSkip]
    [MetaYAML]
    [MetaJSON]
    [MetaNoIndex]
    dir = corpus
    [License]
    [ExecDir]
    [ShareDir]
    [MakeMaker]
    [Manifest]
    [MetaProvides::Package]
    [PkgVersion]
    [PodWeaver]
    [InstallGuide]
    [ReadmeAnyFromPod / ReadmeTextInBuild ]
    [ReadmeAnyFromPod / ReadmePodInRoot ]
    phase = release
    [Test::Perl::Critic]
    [PodCoverageTests]
    [PodSyntaxTests]
    [HasVersionTests]
    [Test::Portability]
    [Test::UnusedVars]
    [Test::Compile]
    skip = Test$
    [Test::Kwalitee]
    [ExtraTests]
    [ReportVersions]
    [MinimumPerl]
    [AutoPrereqs]
    [CheckChangesHasContent]
    [CheckPrereqsIndexed]
    [CheckVersionIncrement]
    [NextRelease]
    [TestRelease]
    [ConfirmRelease]
    [UploadToCPAN]
    [ArchiveRelease]
    directory = releases
    [Git::Check]
    allow_dirty = dist.ini
    allow_dirty = README.pod
    allow_dirty = Changes
    [Git::Commit]
    allow_dirty = dist.ini
    allow_dirty = README.pod
    allow_dirty = Changes
    [Git::Tag]
    [Git::Push]
    push_to = origin
    [Git::Remote::Check]
    remote_name = origin
    branch = master
    remote_branch = master
    [GithubMeta]

There are several options that can change the default configuation,
though.

=head1 OPTIONS

=head2 -remove

This option can be used to remove specific plugins from the bundle. It
can be used multiple times.

Obviously, the default is not to remove any plugins.

Example:

    ; Remove these two plugins from the bundle
    -remove = Test::Perl::Critic
    -remove = GithubMeta

=head2 version, version_major

This option is used to specify the version of the module. The default
is 'auto', which uses the AutoVersion plugin to choose a version
number. You can also set the version number manually, or choose
'disable' to prevent this bundle from supplying a version.

Examples:

    ; Use AutoVersion (default)
    version = auto
    version_major = 0
    ; Use manual versioning
    version = 1.14.04
    ; Provide no version, so that another plugin can handle it.
    version = disable

=head2 copy_file, move_file

If you want to copy or move files out of the build dir and into the
distribution dir, use these two options to specify those files. Both
of these options can be specified multiple times.

The most common reason to use this would be to put automatically
generated files under version control. For example, Github likes to
see a README file in your distribution, but if your README file is
auto-generated during the build, you need to copy each newly-generated
README file out of its build directory in order for Github to see it.

If you want to include an auto-generated file in your distribution but
you I<don't> want to include it in the build, use C<move_file> instead
of C<copy_file>.

By default, both of these options are unset.

Example:

    copy_file = README
    move_file = README.pod
    copy_file = README.txt

=head2 synopsis_is_perl_code

If this is set to true (the default), then the SynopsisTests plugin
will be enabled. This plugin checks the perl syntax of the SYNOPSIS
sections of your modules. Obviously, if your SYNOPSIS section is not
perl code (case in point: this module), you should set this to false.

Example:

    synopsis_is_perl_code = false

=head2 release

This option chooses the type of release to do. The default is 'real,'
which means "really upload the release to CPAN" (i.e. load the
C<UploadToCPAN> plugin). You can set it to 'fake,' in which case the
C<FakeRelease> plugin will be loaded, which simulates the release
process without actually doing anything. You can also set it to 'none'
if you do not want this module to load any release plugin, in which
case your F<dist.ini> file should load a release plugin directly. Any
other value for this option will be interpreted as a release plugin
name to be loaded.

Examples:

    ; Release to CPAN for real (default)
    release = real
    ; For testing, you can do fake releases
    release = fake
    ; Or you can choose no release plugin
    release = none
    ; Or you can specify a specific release plugin.
    release = OtherReleasePlugin

=head2 archive, archive_directory

If set to true, the C<archive> option copies each released version of
the module to an archive directory, using the C<ArchiveRelease>
plugin. This is the default. The name of the archive directory is
specified using C<archive_directory>, which is F<releases> by default.

Examples:

    ; archive each release to the "releases" directory
    archive = true
    archive_directory = releases
    ; Or don't archive
    archive = false

=head2 vcs

This option specifies which version control system is being used for
the distribution. Integration for that version control system is
enabled. The default is 'git', and currently the only other option is
'none', which does not load any version control plugins.

=head2 git_remote

This option specifies the primary Git remote for the repository. The
default is 'origin'. To disable all Git remote operations, set this to
an empty string.

=head2 git_branch, git_remote_branch

This option specifies the branch that is to be checked against its
remote. The default is 'master'. The second option,
C<git_remote_branch>, is only needed if the remote branch has a
different name. It will default to being the same as C<git_branch>.

=head2 no_check_remote

By default, the Git branch C<git_branch> will be checked against the
remote branch C<git_remote_branch> at the remote specified by
C<git_remote> using the C<Git::Remote::Check> plugin. If the remote
branch is ahead of the local branch, the release process will be
aborted. This option disables the check, allowing a release to happen
even if the check would fail. This option has no effect if either
C<git_remote> or C<git_branch> is set to an empty string.

=head2 no_push

By default, the Git repo will be pushed to the remote specified by
C<git_remote> after every release, to ensure that the remote
repository contains the latest release. To disable pushing after a
release, set this option. This option has no effect if git_remote is
set to an empty string.

=head2 allow_dirty

This corresponds to the option of the same name in the Git::Check and
Git::Commit plugins. Briefly, files listed in C<allow_dirty> are
allowed to have changes that are not yet committed to git, and during
the release process, they will be checked in (committed).

The default is F<dist.ini>, F<Changes>, and F<README.pod>. If you
override the default, you must include these files manually if you
want them.

This option only has an effect if C<vcs> is 'git'.

=head2 PLUGIN-SPECIFIC OPTIONS

This bundle consumes the
C<Dist::Zilla::Role::PluginBundle::Config::Slicer> role, which means
that you can specify any option to any plugin in the bundle directly
by prefixing it with the plugin's name. This allows you to configure
any options not covered by the above. For example, if you want to
select "scripts" as the directory for the ExecDir plugin, you would
specify the option as C<ExecDir.dir = "scripts">.

=for Pod::Coverage configure mvp_multivalue_args

=head1 BUGS AND LIMITATIONS

This module should be more configurable. Suggestions welcome.

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Ryan C. Thompson <rct@thompsonclan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ryan C. Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
