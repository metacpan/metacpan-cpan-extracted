package Dist::Zilla::PluginBundle::Author::SKIRMESS;

use strict;
use warnings;

our $VERSION = '0.001';

use Moose 0.99;
use namespace::autoclean 0.09;

with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::BundleDeps
);

sub configure {
    my $self = shift;

    $self->add_plugins(

        # Add contributor names from git to your distribution
        ['Git::Contributors'],

        # Gather all tracked files in a Git working directory
        [
            'Git::GatherDir',
            {
                ':version'       => '2.016',
                exclude_filename => [qw( cpanfile dist.ini LICENSE Makefile.PL META.json META.yml README.md )],
            }
        ],

        # Set the distribution version from your main module's $VERSION
        ['VersionFromMainModule'],

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

        # Decline to build files that appear in a MANIFEST.SKIP-like file
        ['ManifestSkip'],

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

        # Add Dist::Zilla authordeps to META files as develop prereqs
        ['Prereqs::AuthorDeps'],

        # Produce a META.yml
        ['MetaYAML'],

        # Produce a META.json
        ['MetaJSON'],

        # Produce a cpanfile prereqs file
        ['CPANFile'],

        # Automatically convert POD to a README in any format for Dist::Zilla
        [ 'ReadmeAnyFromPod', 'ReadmeAnyFromPod/ReadmeTextInBuild' ],

        # Set copyright year from git
        ['CopyrightYearFromGit'],

        # Output a LICENSE file
        ['License'],

        # Install a directory's contents as executables
        ['ExecDir'],

        # Install a directory's contents as "ShareDir" content
        ['ShareDir'],

        # Build a Makefile.PL that uses ExtUtils::MakeMaker
        ['MakeMaker'],

        # Build a MANIFEST file
        ['Manifest'],

        # Copy (or move) specific files after building (for SCM inclusion, etc.)
        [
            'CopyFilesFromBuild',
            {
                copy => [qw( cpanfile LICENSE Makefile.PL META.json META.yml )],
            }
        ],

        # Check that you're on the correct branch before release
        ['Git::CheckFor::CorrectBranch'],

        # Ensure META includes resources
        ['CheckMetaResources'],

        # Prevent a release if you have prereqs not found on CPAN
        ['CheckPrereqsIndexed'],

        # Ensure Changes has content before releasing
        ['CheckChangesHasContent'],

        # Support running xt tests via dzil test
        ['RunExtraTests'],

        # Extract archive and run tests before releasing the dist
        ['TestRelease'],

        # Prompt for confirmation before releasing
        ['ConfirmRelease'],

        # Upload the dist to CPAN
        [ $ENV{FAKE_RELEASE} ? 'FakeRelease' : 'UploadToCPAN' ],

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
                allow_dirty       => [qw(Changes cpanfile dist.ini LICENSE Makefile.PL META.json META.yml README.md)],
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
        ['Git::Push'],

    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

# in dist.ini
[@Author::SKIRMESS]

=head1 USAGE

To use this PluginBundle, just add it to your dist.ini.

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
