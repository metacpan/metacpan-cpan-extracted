use strict;
use warnings;

use 5.014;

package Dist::Zilla::PluginBundle::WCS;
$Dist::Zilla::PluginBundle::WCS::VERSION = '0.003';
# ABSTRACT: WCS distribution build

use Moose;
use Dist::Zilla;
with
  'Dist::Zilla::Role::PluginBundle::Easy',
  'Dist::Zilla::Role::PluginBundle::PluginRemover',
  'Dist::Zilla::Role::PluginBundle::Config::Slicer';


use Dist::Zilla::PluginBundle::Basic;
use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Git;

sub configure {
    my ($self) = @_;

    $self->add_plugins(
        'Git::NextVersion',
        'License',
        [ CopyFilesFromBuild => { copy             => 'LICENSE', } ],
        [ 'Git::GatherDir'   => { exclude_filename => 'LICENSE', } ],
        [
            PkgVersion => {
                die_on_existing_version => 1,
                die_on_line_insertion   => 1,
            }
        ],
        [
            NextRelease => {
                timezone => 'America/Chicago',
                format   => '%-9v %{yyyy-MM-dd}d',
            }
        ],
    );

    $self->add_bundle(
        '@Git' => {
            remotes_must_exist => 0,
            push_to            => [ 'origin', 'backup', ]
        }
    );

    $self->add_bundle(
        '@Filter' => {
            '-bundle' => '@Basic',
            '-remove' => [ 'License', 'GatherDir' ],
        }
    );

    $self->add_plugins(
        qw/
          InstallGuide
          Git::Contributors
          GithubMeta
          MetaConfig
          MetaJSON
          MinimumPerlFast
          PodWeaver
          /,
        [
            ReadmeAnyFromPod => {
                type     => 'markdown',
                filename => 'README.md',
                location => 'root',
            }
        ],
        qw/
          TaskWeaver
          AutoPrereqs
          /,
        [
            TravisYML => {
                build_branch => '/^release\/.*/'
            }
        ],
        qw/
          MetaTests
          TravisCI::StatusBadge
          Test::ChangeHasContent
          Test::NoTabs
          /,
        [
            'Test::EOL' => {
                trailing_whitespace => 1,
                all_reasons         => 1,
            }
        ],
        qw/
          Test::Compile
          PodSyntaxTests
          PodCoverageTests
          Test::Pod::No404s
          Test::ReportPrereqs
          Test::Perl::Critic
          Test::Kwalitee
          /,
        [
            'Git::CommitBuild' => {
                branch          => '',
                release_branch  => 'release/%b',
                release_message => 'Build release of %v (on %b)'
            }
        ],
        qw/
          TestRelease
          ConfirmRelease
          /,
    );
}


__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::WCS - WCS distribution build

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This is the plugin bundle that WCS uses.  It is equivalent to:

  [Git::NextVersion]
  [License]
  [CopyFilesFromBuild]
  copy = LICENSE

  [Git::GatherDir]
  exclude_filename = LICENSE

  [PkgVersion]
  die_on_existing_version = 1
  die_on_line_insertion = 1

  [NextRelease]
  timezone = America/Chicago
  format = %-9v %{yyyy-MM-dd}d

  [@Git]
  remotes_must_exist = 0
  push_to = 'origin'
  push_to = 'backup'

  [@Filter]
  -bundle = @Basic
  -remove = License
  -remove = GatherDir

  [InstallGuide]
  [Git::Contributors]
  [GithubMeta]
  [MetaConfig]
  [MetaYAML]
  [MetaJSON]
  [MinimumPerlFast]
  [PodWeaver]
  [ReadmeAnyFromPod
  type = markdown
  filename = README.md
  location = root

  [AutoPrereqs]
  [TravisYML]
  build_release = /^release\/.*/

  [MetaTests]
  [TravisCI::StatusBadge]
  [Test::ChangesHasContent]
  [Test::NoTabs]
  [Test::EOL]
  trailing_whitespace = 1
  all_reasons = 1

  [Test::Compile]
  [PodSyntaxTests]
  [PodCoverageTests]
  [Test::Pod::No404s]
  [Test::ReportPrereqs]
  [Test::Perl::Critic]
  [Test::Kwalitee]
  [Git::CommitBuild]
  branch =
  release_branch = release/%b
  release_message = Build release of %v (on %b)

  [TestRelease]
  [ConfirmRelease]

=for Pod::Coverage   configure

=head1 AUTHOR

William C Scherz III <wcs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by William C Scherz III.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=cut
