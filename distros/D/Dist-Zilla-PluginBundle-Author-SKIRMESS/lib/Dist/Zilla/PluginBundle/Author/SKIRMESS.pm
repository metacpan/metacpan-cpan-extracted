package Dist::Zilla::PluginBundle::Author::SKIRMESS;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.005';

use Moose 0.99;
use namespace::autoclean 0.09;

with qw(
  Dist::Zilla::Role::PluginBundle::Easy
);

sub mvp_multivalue_args { return qw/stopwords/ }

has stopwords => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{stopwords} ? $_[0]->payload->{stopwords} : undef;
    },
);

sub configure {
    my $self = shift;

    $self->add_plugins(

        # Check at build/release time if modules are out of date
        [
            'PromptIfStale', 'stale modules, build',
            {
                phase  => 'build',
                module => [ $self->meta->name ],
            }
        ],

        'Author::SKIRMESS::Test::XT::Test::CPAN::Meta',
        'Author::SKIRMESS::Test::XT::Test::CPAN::Meta::JSON',
        'Author::SKIRMESS::Test::XT::Test::DistManifest',
        'Author::SKIRMESS::Test::XT::Test::Kwalitee',
        'Author::SKIRMESS::Test::XT::Test::MinimumVersion',
        'Author::SKIRMESS::Test::XT::Test::Mojibake',
        'Author::SKIRMESS::Test::XT::Test::NoTabs',
        'Author::SKIRMESS::Test::XT::Test::Perl::Critic',
        'Author::SKIRMESS::Test::XT::Test::Pod',
        'Author::SKIRMESS::Test::XT::Test::Pod::No404s',
        'Author::SKIRMESS::Test::XT::Test::Portability::Files',
        [ 'Author::SKIRMESS::Test::XT::Test::Spelling', { stopwords => $self->stopwords } ],
        'Author::SKIRMESS::Test::XT::Test::Version',

        # Check at build/release time if modules are out of date
        [
            'PromptIfStale', 'stale modules, release',
            {
                phase             => 'release',
                check_all_plugins => 1,
                check_all_prereqs => 1,
            }
        ],

        # Add contributor names from git to your distribution
        'Git::Contributors',

        # Gather all tracked files in a Git working directory
        [
            'Git::GatherDir',
            {
                ':version'       => '2.016',
                exclude_filename => [qw( cpanfile dist.ini INSTALL LICENSE Makefile.PL META.json META.yml README.md )],
                include_dotfiles => 1,
            }
        ],

        # Set the distribution version from your main module's $VERSION
        'VersionFromMainModule',

        # Bump and reversion $VERSION on release
        [
            'ReversionOnRelease',
            {
                prompt => 1,
            }
        ],

        # Update the next release number in your changelog
        [
            'NextRelease',
            {
                format    => '%v  %{yyyy-MM-dd HH:mm:ss VVV}d',
                time_zone => 'UTC',
            }
        ],

        # Check your git repository before releasing
        [
            'Git::Check',
            {
                allow_dirty => [qw( Changes cpanfile dist.ini Makefile.PL META.json META.yml README.md )],
            }
        ],

        # Ensure no pending commits on a remote branch before release
        [
            'Git::Remote::Check',
            {
                do_update => 0,
            }
        ],

        # Prune stuff that you probably don't mean to include
        [
            'PruneCruft',
            {
                except => [qw( \.perltidyrc )],
            }
        ],

        # Decline to build files that appear in a MANIFEST.SKIP-like file
        'ManifestSkip',

        # automatically extract prereqs from your modules
        [
            'AutoPrereqs',
            {
                skip => [qw( ^t::lib )],
            }
        ],

        # Add the $AUTHORITY variable and metadata to your distribution
        [
            'Authority',
            {
                ':version' => '1.009',
                authority  => 'cpan:SKIRMESS',
                do_munging => '0',
            }
        ],

        # Detects the minimum version of Perl required for your dist
        [
            'MinimumPerl',
            {
                ':version' => '1.006',
            }
        ],

        # Stop CPAN from indexing stuff
        [
            'MetaNoIndex',
            {
                directory => [qw( corpus examples t xt )],
            }
        ],

        # Automatically include GitHub meta information in META.yml
        [
            'GithubMeta',
            {
                issues => 1,
            }
        ],

        # Automatically convert POD to a README in any format for Dist::Zilla
        [
            'ReadmeAnyFromPod',
            {
                type     => 'markdown',
                filename => 'README.md',
                location => 'root',
            }
        ],

        # Extract namespaces/version from traditional packages for provides
        [
            'MetaProvides::Package',
            {
                meta_noindex => 1,
            }
        ],

        # Summarize Dist::Zilla configuration into distmeta
        'MetaConfig',

        # Produce a META.yml
        'MetaYAML',

        # Produce a META.json
        'MetaJSON',

        # Produce a cpanfile prereqs file
        'CPANFile',

        # Automatically convert POD to a README in any format for Dist::Zilla
        [ 'ReadmeAnyFromPod', 'ReadmeAnyFromPod/ReadmeTextInBuild' ],

        # Set copyright year from git
        'CopyrightYearFromGit',

        # Output a LICENSE file
        'License',

        # Build an INSTALL file
        [
            'InstallGuide',
            {
                ':version' => '1.200007',
            }
        ],

        # Install a directory's contents as executables
        'ExecDir',

        # Install a directory's contents as "ShareDir" content
        'ShareDir',

        # Build a Makefile.PL that uses ExtUtils::MakeMaker
        'MakeMaker',

        # Build a MANIFEST file
        'Manifest',

        # Copy (or move) specific files after building (for SCM inclusion, etc.)
        [
            'CopyFilesFromBuild',
            {
                copy => [qw( cpanfile INSTALL LICENSE Makefile.PL META.json META.yml )],
            }
        ],

        # Check that you're on the correct branch before release
        'Git::CheckFor::CorrectBranch',

        # Check your repo for merge-conflicted files
        'Git::CheckFor::MergeConflicts',

        # Ensure META includes resources
        'CheckMetaResources',

        # Prevent a release if you have prereqs not found on CPAN
        'CheckPrereqsIndexed',

        # Ensure Changes has content before releasing
        'CheckChangesHasContent',

        # Check if your distribution declares a dependency on itself
        'CheckSelfDependency',

        # BeforeRelease plugin to check for a strict version number
        [
            'CheckStrictVersion',
            {
                decimal_only => 1,
            }
        ],

        # Support running xt tests via dzil test
        'RunExtraTests',

        # Extract archive and run tests before releasing the dist
        'TestRelease',

        # Retrieve count of outstanding RT and github issues for your distribution
        'CheckIssues',

        # Prompt for confirmation before releasing
        'ConfirmRelease',

        # Upload the dist to CPAN
        'UploadToCPAN',

        # Copy files from a release (for SCM inclusion, etc.)
        [
            'CopyFilesFromRelease',
            {
                match => [qw( .pm$ )],
            }
        ],

        # Commit dirty files
        [
            'Git::Commit',
            {
                commit_msg        => '%v',
                allow_dirty       => [qw(Changes cpanfile dist.ini INSTALL LICENSE Makefile.PL META.json META.yml README.md)],
                allow_dirty_match => '\.pm$',
            }
        ],

        # Tag the new version
        [
            'Git::Tag',
            {
                tag_format  => '%v',
                tag_message => q{},
            }
        ],

        # Push current branch
        'Git::Push',

        # Compare data and files at different phases of the distribution build process
        'VerifyPhases',
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::SKIRMESS - Dist::Zilla configuration the way SKIRMESS does it

=head1 SYNOPSIS

  # in dist.ini
  [@Author::SKIRMESS]

=head1 DESCRIPTION

This is a L<Dist::Zilla|Dist::Zilla> PluginBundle.

=head1 USAGE

To use this PluginBundle, just add it to your dist.ini.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Dist-Zilla-PluginBundle-Author-SKIRMESS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Dist-Zilla-PluginBundle-Author-SKIRMESS>

  git clone https://github.com/skirmess/Dist-Zilla-PluginBundle-Author-SKIRMESS.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::ETHER|Dist::Zilla::PluginBundle::Author::ETHER>,
L<Dist::Zilla::PluginBundle::DAGOLDEN|Dist::Zilla::PluginBundle::DAGOLDEN>,
L<Dist::Zilla::PluginBundle::Milla|Dist::Zilla::PluginBundle::Milla>,
L<Dist::Milla|Dist::Milla>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
