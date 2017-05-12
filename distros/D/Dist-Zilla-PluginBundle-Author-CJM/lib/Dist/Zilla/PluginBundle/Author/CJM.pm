#---------------------------------------------------------------------
package Dist::Zilla::PluginBundle::Author::CJM;
#
# Copyright 2011 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  19 Oct 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Build a distribution like CJM
#---------------------------------------------------------------------

our $VERSION = '4.37';
# This file is part of Dist-Zilla-PluginBundle-Author-CJM 4.37 (November 21, 2015)

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';


sub configure
{
  my $self = shift;

  my $arg = $self->payload;

  $self->add_plugins('VersionFromModule')
      unless $arg->{manual_version};

  $self->add_plugins(
    qw(
      GatherDir
      PruneCruft
      ManifestSkip
      MetaJSON
      MetaYAML
      License
      Test::PrereqsFromMeta
      PodSyntaxTests
      PodCoverageTests
    ),
    [PodLoom => {
      data => 'tools/loom.pl',
      %{ $self->config_slice({
        pod_finder   => 'finder',
        pod_template => 'template',
      }) },
    } ],
    # either MakeMaker or ModuleBuild:
    [ ($arg->{builder} || 'MakeMaker') =>
      scalar $self->config_slice(qw( eumm_version mb_version mb_class ))
    ],
    qw(
      RunExtraTests
      MetaConfig
      MatchManifest
    ),
    [ RecommendedPrereqs => scalar $self->config_slice({
        check_recommend => 'finder',
        check_recommend_tests => 'test_finder',
    }) ],
    [ CheckPrereqsIndexed => scalar $self->config_slice({
        skip_index_check => 'skips'
    }) ],
    [ GitVersionCheckCJM => scalar $self->config_slice({
        single_version => 'single_version',
        check_files => 'finder'
    }) ],
    [ TemplateCJM => {
        date_format => 'MMMM d, y',
        %{$self->config_slice(
          'changelog_re',
          { pod_finder           => 'finder',
            template_date_format => 'date_format',
            template_file        => 'file',
          })},
      } ],
    [ Repository => { git_remote => 'github' } ],
  );

  $self->add_bundle(Git => {
    allow_dirty => 'Changes',
    commit_msg  => 'Updated Changes for %{MMMM d, yyyy}d%{ trial}t release of %v',
    tag_format  => '%v%t',
    tag_message => 'Tagged %N %v%{ (trial release)}t',
    push_to     => 'github master',
  });

  $self->add_plugins(
    'TestRelease',
    'UploadToCPAN',
    [ ArchiveRelease => { directory => 'cjm_releases' } ],
  );

  if (my $remove = $arg->{remove_plugin}) {
    my $prefix  = $self->name . '/';
    my %remove = map { $prefix . $_ => 1 } @$remove;
    my $plugins = $self->plugins;
    @$plugins = grep { not $remove{$_->[0]} } @$plugins;
  }
} # end configure

sub mvp_multivalue_args { qw(check_files check_recommend check_recommend_tests
                             remove_plugin
                             pod_finder skip_index_check template_file) }

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Dist::Zilla::PluginBundle::Author::CJM - Build a distribution like CJM

=head1 VERSION

This document describes version 4.37 of
Dist::Zilla::PluginBundle::Author::CJM, released November 21, 2015.

=head1 SYNOPSIS

In dist.ini:

  [@Author::CJM / CJM]

=head1 DESCRIPTION

This is the plugin bundle that CJM uses. It is equivalent to:

  [VersionFromModule]

  [GatherDir]
  [PruneCruft]
  [ManifestSkip]
  [MetaJSON]
  [MetaYAML]
  [License]
  [Test::PrereqsFromMeta]
  [PodSyntaxTests]
  [PodCoverageTests]
  [PodLoom]
  data = tools/loom.pl
  [MakeMaker]
  [RunExtraTests]
  [MetaConfig]
  [MatchManifest]
  [RecommendedPrereqs]
  [CheckPrereqsIndexed]
  [GitVersionCheckCJM]
  [TemplateCJM]

  [Repository]
  git_remote  = github

  [@Git]
  allow_dirty = Changes
  commit_msg  = Updated Changes for %{MMMM d, yyyy}d%{ trial}t release of %v
  tag_format  = %v%t
  tag_message = Tagged %N %v%{ (trial release)}t
  push_to     = github master

  [TestRelease]
  [UploadToCPAN]
  [ArchiveRelease]
  directory = cjm_releases

=head1 ATTRIBUTES

=head2 builder

Use the specified plugin instead of MakeMaker.


=head2 changelog_re

Passed to TemplateCJM.


=head2 check_files

Passed to GitVersionCheckCJM as its C<finder>.


=head2 check_recommend

Passed to RecommendedPrereqs as its C<finder>.


=head2 check_recommend_tests

Passed to RecommendedPrereqs as its C<test_finder>.


=head2 eumm_version

Passed to MakeMaker (or its replacement C<builder>).


=head2 manual_version

If true, VersionFromModule is omitted.


=head2 mb_class

Passed to MakeMaker (or its replacement C<builder>).


=head2 mb_version

Passed to MakeMaker (or its replacement C<builder>).


=head2 pod_finder

Passed to both PodLoom and TemplateCJM as their C<finder>.


=head2 pod_template

Passed to PodLoom as its C<template>.


=head2 remove_plugin

The named plugin is removed from the bundle (may be specified multiple
times).  This exists because you can't pass multi-value parameters
through L<@Filter|Dist::Zilla::PluginBundle::Filter>.


=head2 single_version

Passed to GitVersionCheckCJM.


=head2 skip_index_check

Passed to CheckPrereqsIndexed as its C<skips>.


=head2 template_date_format

Passed to TemplateCJM as its C<date_format>.  Defaults to C<MMMM d, y>.


=head2 template_file

Passed to TemplateCJM as its C<file>.

=for Pod::Coverage
configure
mvp_multivalue_args

=head1 CONFIGURATION AND ENVIRONMENT

Dist::Zilla::PluginBundle::Author::CJM requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Dist-Zilla-PluginBundle-Author-CJM AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-PluginBundle-Author-CJM >>.

You can follow or contribute to Dist-Zilla-PluginBundle-Author-CJM's development at
L<< https://github.com/madsen/dist-zilla-pluginbundle-cjm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
