package Dist::Zilla::PluginBundle::MMCCLIMON;
# ABSTRACT: BeLike::MMCCLIMON when you build your dists
$Dist::Zilla::PluginBundle::MMCCLIMON::VERSION = '5.013';
use Moose;
use Dist::Zilla 2.100922; # TestRelease
with
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
    'Dist::Zilla::Role::PluginBundle::Config::Slicer';

#pod =head1 DESCRIPTION
#pod
#pod This is the plugin bundle that MMCCLIMON uses.  It is stolen directly from RJBS,
#pod with some things removed and a few others added.
#pod
#pod It is more or less equivalent to:
#pod
#pod   [Git::GatherDir]
#pod   [@Basic]
#pod   ; ...but without GatherDir and ExtraTests and MakeMaker
#pod
#pod   [MakeMaker]
#pod   default_jobs = 9
#pod
#pod   [AutoPrereqs]
#pod   [Git::NextVersion]
#pod   [PkgVersion]
#pod   die_on_existing_version = 1
#pod   die_on_line_insertion   = 1
#pod   [MetaConfig]
#pod   [MetaJSON]
#pod   [NextRelease]
#pod
#pod   [Test::ChangesHasContent]
#pod   [PodSyntaxTests]
#pod   [Test::ReportPrereqs]
#pod
#pod   [PodWeaver]
#pod   config_plugin = @MMCCLIMON
#pod
#pod   [GithubMeta]
#pod   remote = github
#pod   remote = origin
#pod
#pod   [@Git]
#pod   tag_format = %v
#pod
#pod   [Git::Contributors]
#pod
#pod   [CPANFile]
#pod
#pod   [CopyFilesFromBuild]
#pod   copy = Makefile.PL
#pod   copy = LICENSE
#pod   copy = cpanfile
#pod
#pod   [Git::GatherDir]
#pod   exclude_filename = Makefile.PL
#pod   exclude_filename = LICENSE
#pod   exclude_filename = cpanfile
#pod
#pod If the C<manual_version> argument is given, AutoVersion is omitted.
#pod
#pod If the C<github_issues> argument is given, and true, the F<META.*> files will
#pod point to GitHub issues for the dist's bugtracker.
#pod
#pod This bundle makes use of L<Dist::Zilla::Role::PluginBundle::PluginRemover> and
#pod L<Dist::Zilla::Role::PluginBundle::Config::Slicer> to allow further customization.
#pod
#pod =cut

use Dist::Zilla::PluginBundle::Basic;
use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Git;

has manual_version => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{manual_version} },
);

has major_version => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub { $_[0]->payload->{version} || 0 },
);

has github_issues => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{github_issues} // 1 },
);

has homepage => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{homepage} // '' },
);

has weaver_config => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{weaver_config} || '@MMCCLIMON' },
);

sub mvp_multivalue_args { qw(dont_compile) }

has dont_compile => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { $_[0]->payload->{dont_compile} || [] },
);

has package_name_version => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{package_name_version} // 0 },
);

sub configure {
  my ($self) = @_;

  my @filenames = qw(
    Makefile.PL
    LICENSE
    cpanfile
  );

  $self->add_plugins([ 'Git::GatherDir' => { exclude_filename => \@filenames }]);
  $self->add_plugins('CheckPrereqsIndexed');
  $self->add_plugins('CheckExtraTests');
  $self->add_plugins(
    [ PromptIfStale => 'MMCCLIMON-Outdated' => {
      phase  => 'build',
      module => 'Dist::Zilla::PluginBundle::MMCCLIMON',
    } ],
    [ PromptIfStale => 'CPAN-Outdated' => {
      phase => 'release',
      check_all_plugins => 1,
    } ],
  );
  $self->add_bundle('@Filter', {
    '-bundle' => '@Basic',
    '-remove' => [ 'GatherDir', 'ExtraTests', 'MakeMaker' ],
  });

  $self->add_plugins([ MakeMaker => { default_jobs => 9 } ]);

  $self->add_plugins('AutoPrereqs');

  $self->add_plugins('CPANFile');
  $self->add_plugins([ 'CopyFilesFromBuild' => { copy => \@filenames } ]);

  unless ($self->manual_version) {
    $self->add_plugins([
      'Git::NextVersion' => {
        version_regexp => '^([0-9]+\.[0-9]+)$',
        version_by_branch => 1,
      }
    ]);
  }

  $self->add_plugins(
    [
      PkgVersion => {
        die_on_existing_version => 1,
        die_on_line_insertion   => 1,
        ($self->package_name_version ? (use_package => 1) : ()),
      },
    ],
    qw(
      MetaConfig
      MetaJSON
      NextRelease
      Test::ChangesHasContent
      PodSyntaxTests
      Test::ReportPrereqs
    ),
  );

  $self->add_plugins(
    [ Prereqs => 'TestMoreWithSubtests' => {
      -phase => 'test',
      -type  => 'requires',
      'Test::More' => '0.96'
    } ],
  );

  $self->add_plugins([
    PodWeaver => {
      config_plugin => $self->weaver_config,
      replacer      => 'replace_with_comment',
    }
  ]);

  $self->add_plugins(
    [ GithubMeta => {
      remote => [ qw(gitbox github upstream michael) ],
      issues => $self->github_issues,
      (length $self->homepage ? (homepage => $self->homepage) : ()),
    } ],
  );

  $self->add_bundle('@Git' => {
    tag_format => '%v',
    remotes_must_exist => 0,
    push_to    => [
      'gitbox :',
      'michael :',
    ],
  });

  $self->add_plugins('Git::Contributors');
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::MMCCLIMON - BeLike::MMCCLIMON when you build your dists

=head1 VERSION

version 5.013

=head1 DESCRIPTION

This is the plugin bundle that MMCCLIMON uses.  It is stolen directly from RJBS,
with some things removed and a few others added.

It is more or less equivalent to:

  [Git::GatherDir]
  [@Basic]
  ; ...but without GatherDir and ExtraTests and MakeMaker

  [MakeMaker]
  default_jobs = 9

  [AutoPrereqs]
  [Git::NextVersion]
  [PkgVersion]
  die_on_existing_version = 1
  die_on_line_insertion   = 1
  [MetaConfig]
  [MetaJSON]
  [NextRelease]

  [Test::ChangesHasContent]
  [PodSyntaxTests]
  [Test::ReportPrereqs]

  [PodWeaver]
  config_plugin = @MMCCLIMON

  [GithubMeta]
  remote = github
  remote = origin

  [@Git]
  tag_format = %v

  [Git::Contributors]

  [CPANFile]

  [CopyFilesFromBuild]
  copy = Makefile.PL
  copy = LICENSE
  copy = cpanfile

  [Git::GatherDir]
  exclude_filename = Makefile.PL
  exclude_filename = LICENSE
  exclude_filename = cpanfile

If the C<manual_version> argument is given, AutoVersion is omitted.

If the C<github_issues> argument is given, and true, the F<META.*> files will
point to GitHub issues for the dist's bugtracker.

This bundle makes use of L<Dist::Zilla::Role::PluginBundle::PluginRemover> and
L<Dist::Zilla::Role::PluginBundle::Config::Slicer> to allow further customization.

=head1 AUTHOR

Michael McClimon <michael@mcclimon.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Ricardo SIGNES

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ricardo SIGNES <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Michael Mcclimon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
