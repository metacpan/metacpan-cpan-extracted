#ABSTRACT: Dist::Zilla plugins for AJGB
use strict;
use warnings;

package Dist::Zilla::PluginBundle::AJGB;
our $AUTHORITY = 'cpan:AJGB';
$Dist::Zilla::PluginBundle::AJGB::VERSION = '2.04';

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

# make AutoPrereqs happy
use Dist::Zilla::Plugin::ExecDir ();
use Dist::Zilla::Plugin::ShareDir ();
use Dist::Zilla::Plugin::GatherDir ();
use Dist::Zilla::Plugin::MetaYAML ();
use Dist::Zilla::Plugin::MetaJSON ();
use Dist::Zilla::Plugin::License ();
use Dist::Zilla::Plugin::Manifest ();
use Dist::Zilla::Plugin::Test::Compile ();
use Dist::Zilla::Plugin::PodCoverageTests ();
use Dist::Zilla::Plugin::PodSyntaxTests ();
use Dist::Zilla::Plugin::Test::EOL ();
use Dist::Zilla::Plugin::Test::NoTabs ();
use Dist::Zilla::Plugin::Test::Kwalitee ();
use Dist::Zilla::Plugin::Test::Portability ();
use Dist::Zilla::Plugin::Test::Synopsis ();
use Dist::Zilla::Plugin::PruneCruft ();
use Dist::Zilla::Plugin::ManifestSkip ();
use Dist::Zilla::Plugin::PkgVersion ();
use Dist::Zilla::Plugin::Authority ();
use Dist::Zilla::Plugin::PodWeaver ();
use Dist::Zilla::Plugin::MetaConfig ();
use Dist::Zilla::Plugin::AutoMetaResources ();
use Dist::Zilla::Plugin::AutoPrereqs ();
use Dist::Zilla::Plugin::MakeMaker ();
use Dist::Zilla::Plugin::ModuleBuild ();
use Dist::Zilla::Plugin::InstallGuide ();
use Dist::Zilla::Plugin::Git::NextVersion ();
use Dist::Zilla::Plugin::CopyFilesFromBuild ();
use Dist::Zilla::Plugin::ReadmeFromPod ();
use Dist::Zilla::Plugin::Git::Check ();
use Dist::Zilla::Plugin::CheckChangesHasContent ();
use Dist::Zilla::Plugin::CheckExtraTests ();
use Dist::Zilla::Plugin::TestRelease ();
use Dist::Zilla::Plugin::ConfirmRelease ();
use Dist::Zilla::Plugin::UploadToCPAN ();
use Dist::Zilla::Plugin::NextRelease ();
use Dist::Zilla::Plugin::Git::Commit ();
use Dist::Zilla::Plugin::Git::Tag ();
use Dist::Zilla::Plugin::Git::Push ();


sub configure {
    my $self = shift;

    my @plugins = (
    # Dirs
        qw(
          ExecDir
          ShareDir
        ),

    # FileGatherer
        [
            GatherDir =>
              { exclude_filename => [ 'README', 'dist.ini', 'weaver.ini', ], }
        ],
        qw(
          MetaYAML
          MetaJSON
          License
          Manifest
          Test::Compile
          PodCoverageTests
          PodSyntaxTests
          Test::EOL
          Test::NoTabs
          Test::Kwalitee
          Test::Portability
          Test::Synopsis
        ),

    # FilePruner
        qw(
          PruneCruft
          ManifestSkip
        ),

    # FileMunger
        qw(
          PkgVersion
        ),
        [
            Authority => {
                authority   => 'cpan:AJGB',
                do_metadata => 1,
            }
        ],
        [ PodWeaver          => { config_plugin => '@AJGB', } ],

    # MetaProvider
        qw(
          MetaConfig
        ),
        [
            AutoMetaResources => {
                'bugtracker.github' => 'user:ajgb',
                'repository.github' => 'user:ajgb',
                'homepage' => 'https://metacpan.org/release/%{dist}',
            },
        ],

    # PrereqSource
        qw(
          AutoPrereqs
          MakeMaker
          ModuleBuild
        ),

    # PrereqSource / InstallTool
        qw(
          ReadmeFromPod
          InstallGuide
        ),

    # VersionProvider
        [ 'Git::NextVersion' => { first_version => '0.01', } ],

    # AfterBuild
        [ CopyFilesFromBuild => { copy          => 'README', } ],

    # BeforeRelease
        [
            'Git::Check' =>
              {
                  allow_dirty => [ 'README', 'dist.ini', 'weaver.ini', ],
                  untracked_files => 'warn',
              }
        ],
        qw(
          CheckChangesHasContent
          CheckExtraTests
          TestRelease
          ConfirmRelease
        ),

    # Releaser
        qw(
          UploadToCPAN
        ),

    # AfterRelease
        [
            NextRelease => {
                time_zone => 'Europe/London',
                filename  => 'Changes',
                format    => '%-6v %{yyyy-MM-dd HH:mm:ss}d',
            }
        ],
        [
            'Git::Tag' => {
                filename   => 'Changes',
                tag_format => 'v%v',
            }
        ],
        [ 'Git::Commit'      => {
                time_zone     => 'Europe/London',
                allow_dirty     => [ 'README', 'Changes' ],
            }
        ],
        qw(
          Git::Push
        ),
    );

    $self->add_plugins( @plugins );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::AJGB - Dist::Zilla plugins for AJGB

=head1 VERSION

version 2.04

=head1 SYNOPSIS

    # dist.ini
    [@AJGB]

=head1 DESCRIPTION

This is the plugin bundle for AJGB. It's an equivalent to:

    [ExecDir]
    [ShareDir]

    [GatherDir]
    exclude_filename = README
    exclude_filename = dist.ini
    exclude_filename = weaver.ini
    [MetaYAML]
    [MetaJSON]
    [License]
    [Manifest]
    [Test::Compile]
    [PodCoverageTests]
    [PodSyntaxTests]
    [Test::EOL]
    [Test::NoTabs]
    [Test::Kwalitee]
    [Test::Portability]

    [PruneCruft]
    [ManifestSkip]

    [PkgVersion]
    [Authority]
    authority = cpan:AJGB
    do_metadata = 1
    [PodWeaver]
    config_plugin = @AJGB

    [MetaConfig]
    [AutoMetaResources]
    bugtracker.github = user:ajgb
    repository.github = user:ajgb
    homepage = https://metacpan.org/release/%{dist}

    [Prereqs / TestRequires]
    Test::Pod::Coverage = 0
    Test::Pod = 0
    Pod::Coverage::TrustPod = 0

    [AutoPrereqs]
    [MakeMaker]
    [ModuleBuild]

    [InstallGuide]
    [ReadmeFromPod]

    [Git::NextVersion]
    first_version = 0.01

    [CopyFilesFromBuild]
    copy = README

    [Git::Check]
    allow_dirty = Changes
    allow_dirty = dist.ini
    allow_dirty = README
    untracked_files = warn
    [CheckChangesHasContent]
    [CheckExtraTests]
    [TestRelease]
    [ConfirmRelease]

    [UploadToCPAN]

    [NextRelease]
    time_zone = Europe/London
    filename = Changes
    format = %-6v %{yyyy-MM-dd HH:mm:ss}d
    [Git::Commit]
    time_zone = Europe/London
    allow_dirty = README
    allow_dirty = Changes
    [Git::Tag]
    filename = Changes
    tag_format = v%v
    [Git::Push]

=for Pod::Coverage     configure

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
