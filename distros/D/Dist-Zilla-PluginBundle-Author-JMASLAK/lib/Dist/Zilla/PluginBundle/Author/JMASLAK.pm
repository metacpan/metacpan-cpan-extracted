#!/usr/bin/perl

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use v5.14;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Author::JMASLAK;
# ABSTRACT: JMASLAK's Plugin Bundle
$Dist::Zilla::PluginBundle::Author::JMASLAK::VERSION = '1.181841';

use Moose;
use Dist::Zilla;

with 'Dist::Zilla::Role::PluginBundle::Easy';

# For auto plugins
AUTOPLUG: {
    use Dist::Zilla::Plugin::AutoVersion;
    use Dist::Zilla::Plugin::NextRelease;
    use Dist::Zilla::Plugin::AutoPrereqs;
    use Dist::Zilla::Plugin::ContributorCovenant;
    use Dist::Zilla::Plugin::ExecDir;
    use Dist::Zilla::Plugin::ExtraTests;
    use Dist::Zilla::Plugin::GatherDir;
    use Dist::Zilla::Plugin::GenerateFile::FromShareDir;
    use Dist::Zilla::Plugin::GitHub::Meta;
    use Dist::Zilla::Plugin::License;
    use Dist::Zilla::Plugin::ManifestSkip;
    use Dist::Zilla::Plugin::MetaJSON;
    use Dist::Zilla::Plugin::MetaProvides::Package;
    use Dist::Zilla::Plugin::MetaYAML;
    use Dist::Zilla::Plugin::PkgVersion;
    use Dist::Zilla::Plugin::PodSyntaxTests;
    use Dist::Zilla::Plugin::PodWeaver;
    use Dist::Zilla::Plugin::PruneCruft;
    use Dist::Zilla::Plugin::ShareDir;
    use Dist::Zilla::Plugin::ReadmeAnyFromPod;
    use Dist::Zilla::Plugin::Test::ChangesHasContent;
    use Dist::Zilla::Plugin::Test::EOL;
    use Dist::Zilla::Plugin::Test::Kwalitee::Extra;
    use Dist::Zilla::Plugin::Test::NoTabs;
    use Dist::Zilla::Plugin::Test::ReportPrereqs;
    use Dist::Zilla::Plugin::Test::TrailingSpace;
    use Dist::Zilla::Plugin::Test::UnusedVars;
    use Dist::Zilla::Plugin::Test::UseAllModules;
    use Dist::Zilla::Plugin::Test::Version;

    use Dist::Zilla::Plugin::MakeMaker;
    use Dist::Zilla::Plugin::Manifest;

    use Dist::Zilla::Plugin::CopyFilesFromBuild;
    use Dist::Zilla::Plugin::ConfirmRelease;
    use Dist::Zilla::Plugin::TestRelease;
    use Dist::Zilla::Plugin::UploadToCPAN;

    use Dist::Zilla::Plugin::Git::Check;
    use Dist::Zilla::Plugin::Git::Commit;
    use Dist::Zilla::Plugin::Git::Push;
    use Dist::Zilla::Plugin::Git::Tag;
}

sub configure {
    my ($self) = (@_);

    $self->add_plugins( $self->_contributing_plugin() );
    $self->add_plugins( $self->_copy_files_from_build() );
    $self->add_plugins( $self->_covenant_plugin() );
    $self->add_plugins( $self->_mailmap_plugin() );
    $self->add_plugins( $self->_manifestskip_plugin() );
    $self->add_plugins( $self->_todo_plugin() );
    $self->add_plugins( $self->_travis_plugin() );

    $self->add_plugins('AutoVersion');
    $self->add_plugins('NextRelease');
    $self->add_plugins('AutoPrereqs');
    $self->add_plugins('ContributorCovenant');
    $self->add_plugins('ExecDir');
    $self->add_plugins('ExtraTests');
    $self->add_plugins('GatherDir');
    $self->add_plugins('GitHub::Meta');
    $self->add_plugins('License');
    $self->add_plugins('ManifestSkip');
    $self->add_plugins('MetaJSON');
    $self->add_plugins('MetaProvides::Package');
    $self->add_plugins('MetaYAML');
    $self->add_plugins('PkgVersion');
    $self->add_plugins('PodSyntaxTests');
    $self->add_plugins('PodWeaver');
    $self->add_plugins('PruneCruft');
    $self->add_plugins('ShareDir');
    $self->add_plugins( [ 'ReadmeAnyFromPod' => { type => 'pod', filename => 'README.pod' } ] );
    $self->add_plugins('Test::ChangesHasContent');
    $self->add_plugins('Test::EOL');
    $self->add_plugins('Test::Kwalitee::Extra');
    $self->add_plugins('Test::NoTabs');
    $self->add_plugins('Test::ReportPrereqs');
    $self->add_plugins(
        [ 'Test::TrailingSpace' => { filename_regex => '\.($?:ini|pl|pm|t|txt)\z' } ] );
    $self->add_plugins('Test::UnusedVars');
    $self->add_plugins('Test::UseAllModules');
    $self->add_plugins('Test::Version');

    $self->add_plugins('MakeMaker');
    $self->add_plugins('Manifest');

    $self->add_plugins('ConfirmRelease');
    $self->add_plugins('TestRelease');
    $self->add_plugins('UploadToCPAN');

    $self->add_plugins(
        [ 'Git::Check', => { allow_dirty => [ 'dist.ini', _changes_file(), 'README.pod' ] } ] );
    $self->add_plugins(
        [ 'Git::Commit', => { allow_dirty => [ 'dist.ini', _changes_file(), 'README.pod' ] } ] );
    $self->add_plugins('Git::Push');
    $self->add_plugins('Git::Tag');

    return;
}

sub _copy_files_from_build {
    my $self = shift;

    my (@files) = ('README.pod');

    if ( !-e 'CODE_OF_CONDUCT.md' ) {
        push @files, 'CODE_OF_CONDUCT.md';
    }

    return [
        'CopyFilesFromBuild' => {
            copy => [@files],
        }
    ];
}

sub _changes_file {
    if ( -f 'Changes' )   { return 'Changes'; }
    if ( -f 'CHANGES' )   { return 'CHANGES'; }
    if ( -f 'ChangeLog' ) { return 'ChangeLog'; }
    if ( -f 'CHANGELOG' ) { return 'CHANGELOG'; }

    return 'Changes';
}

sub _changes_plugin {
    my $self = shift;

    if ( -f _changes_file() ) { return; }

    return [
        'GenerateFile::FromShareDir' => 'Generate Changes' => {
            -dist     => ( __PACKAGE__ =~ s/::/-/gr ),
            -filename => 'Changes',
            -location => 'root',
        },
    ];
}

# Ruthlessly stolen from DROLSKY
sub _contributing_plugin {
    my $self = shift;

    if ( -f 'CONTRIBUTING' ) { return; }

    return [
        'GenerateFile::FromShareDir' => 'Generate CONTRIBUTING' => {
            -dist     => ( __PACKAGE__ =~ s/::/-/gr ),
            -filename => 'CONTRIBUTING',
            -location => 'root',
        },
    ];
}

sub _covenant_plugin {
    my $self = shift;

    if ( -f 'AUTHOR_PLEDGE' ) { return; }

    return [
        'GenerateFile::FromShareDir' => 'Generate AUTHOR_PLEDGE' => {
            -dist     => ( __PACKAGE__ =~ s/::/-/gr ),
            -filename => 'AUTHOR_PLEDGE',
            -location => 'root',
        },
    ];
}

sub _mailmap_plugin {
    my $self = shift;

    if ( -f '.mailmap' ) { return; }

    return [
        'GenerateFile::FromShareDir' => 'Generate .mailmap' => {
            -dist            => ( __PACKAGE__ =~ s/::/-/gr ),
            -filename        => '.mailmap',
            -source_filename => 'mailmap',
            -location        => 'root',
        },
    ];
}

sub _manifestskip_plugin {
    my $self = shift;

    if ( -f 'MANIFEST.SKIP' ) { return; }

    return [
        'GenerateFile::FromShareDir' => 'Generate MANIFEST.SKIP' => {
            -dist     => ( __PACKAGE__ =~ s/::/-/gr ),
            -filename => 'MANIFEST.SKIP',
            -location => 'root',
        },
    ];
}

sub _travis_plugin {
    my $self = shift;

    if ( -f '.travis.yml' ) { return; }

    return [
        'GenerateFile::FromShareDir' => 'Generate .travis.yml' => {
            -dist            => ( __PACKAGE__ =~ s/::/-/gr ),
            -filename        => '.travis.yml',
            -source_filename => 'travis.yml',
            -location        => 'root',
        },
    ];
}

sub _todo_plugin {
    my $self = shift;

    if ( -f 'TODO' ) { return; }

    return [
        'GenerateFile::FromShareDir' => 'Generate TODO' => {
            -dist            => ( __PACKAGE__ =~ s/::/-/gr ),
            -filename        => 'TODO',
            -source_filename => 'TODO',
            -location        => 'root',
        },
    ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::JMASLAK - JMASLAK's Plugin Bundle

=head1 VERSION

version 1.181841

=head1 DESCRIPTION

This is Joelle Maslak's plugin bundle, used for her modules.  If you're not
her, you probably want to create your own plugin module because I may modify
this module based on her needs, breaking third party modules that use this.

All of the following are in this module as of v1.181840.

It is somewhat equivilent to:

    [AutoVersion]
    [NextRelease]
    [AutoPrereqs]
    [ConfirmRelease]
    [ContributorCovenant]

    [CopyFilesFromBuild]
    copy = 'README.pod'

    [ExecDir]
    [ExtraTests]
    [GatherDir]
    [GitHub::Meta]
    [License]
    [Manifest]
    [ManifestSkip]
    [Makemaker]
    [MetaJSON]
    [MetaProvides::Package]
    [MetaYAML]
    [PkgVersion]
    [PodSyntaxTests]
    [PodWeaver]
    [PruneCruft]
    [ShareDir]

    [ReadmeAnyFromPod]
    type     = pod
    filename = README.pod

    [Test::ChangesHasContent]
    [Test::EOL]
    [Test::Kwalitee::Extra]
    [Test::NoTabs]
    [Test::ReportPrereqs]

    [Test::TrailingSpace]
    filename_regex = '\.($?:ini|pl|pm|t|txt)\z'

    [Test::UnusedVars]
    [Test::UseAllModules]
    [Test::Version]
    [TestRelease]
    [UploadToCPAN]

    [Git::Check]
    allow_dirty = dist.ini
    allow_dirty = Changes
    allow_dirty = README.pod

    [Git::Commit]
    allow_dirty = dist.ini
    allow_dirty = Changes
    allow_dirty = README.pod

    [Git::Push]
    [Git::Tag]

This automatically numbers releases.

This creates a C<CODE_OF_CONDUCT.md> from the awesome Contributor Covenant
project, a C<Changes> file, a C<CONTRIBUTING> file, a C<TODO> file,
a C<MANIFEST_SKIP> file, an C<AUTHOR_PLEDGE> file that indicates CPAN admins
can take ownership should the project become abandoned, and a C<.travis.yml>
file that will probably need to be edited.  If these files exist already, they
will not get overwritten.

It also generates a C<.mailmap> base file suitable for Joelle, if one does
not already exists.

=head1 USAGE

In your C<dist.ini> -

    [@Filter]
    -bundle  = @Author::JMASLAK
    -version = 0.003

The C<-version> option should specify the latest version required and tested
with a given package.

=head1 SEE ALSO

Core Dist::Zilla plugins:

Dist::Zilla roles:
L<PluginBundle|Dist::Zilla::Role::PluginBundle>,
L<PluginBundle::Easy|Dist::Zilla::Role::PluginBundle::Easy>.

=head1 AUTHOR

Joelle Maslak <jmaslak@antelope.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Joelle Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
