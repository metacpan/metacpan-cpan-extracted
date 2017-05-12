package Dist::Zilla::PluginBundle::RJBS;
# ABSTRACT: BeLike::RJBS when you build your dists
$Dist::Zilla::PluginBundle::RJBS::VERSION = '5.010';
use Moose;
use Dist::Zilla 2.100922; # TestRelease
with 'Dist::Zilla::Role::PluginBundle::Easy';

#pod =head1 DESCRIPTION
#pod
#pod This is the plugin bundle that RJBS uses.  It is more or less equivalent to:
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
#pod   config_plugin = @RJBS
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
#pod If the C<task> argument is given to the bundle, PodWeaver is replaced with
#pod TaskWeaver and Git::NextVersion is replaced with AutoVersion.  If the
#pod C<manual_version> argument is given, AutoVersion is omitted.
#pod
#pod If the C<github_issues> argument is given, and true, the F<META.*> files will
#pod point to GitHub issues for the dist's bugtracker.
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

has is_task => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{task} },
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
  default => sub { $_[0]->payload->{weaver_config} || '@RJBS' },
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

  $self->log_fatal("you must not specify both weaver_config and is_task")
    if $self->is_task and $self->weaver_config ne '@RJBS';

  $self->add_plugins('Git::GatherDir');
  $self->add_plugins('CheckPrereqsIndexed');
  $self->add_plugins('CheckExtraTests');
  $self->add_plugins(
    [ PromptIfStale => 'RJBS-Outdated' => {
      phase  => 'build',
      module => 'Dist::Zilla::PluginBundle::RJBS',
    } ],
    [ PromptIfStale => 'CPAN-Outdated' => {
      phase => 'release',
      check_all_plugins => 1,
      # check_all_prereqs => 1, # <-- not sure yet -- rjbs, 2013-09-23
    } ],
  );
  $self->add_bundle('@Filter', {
    '-bundle' => '@Basic',
    '-remove' => [ 'GatherDir', 'ExtraTests', 'MakeMaker' ],
  });

  $self->add_plugins([ MakeMaker => { default_jobs => 9 } ]);

  $self->add_plugins('AutoPrereqs');

  unless ($self->manual_version) {
    if ($self->is_task) {
      my $v_format = q<{{cldr('yyyyMMdd')}}>
                   . sprintf('.%03u', ($ENV{N} || 0));

      $self->add_plugins([
        AutoVersion => {
          major     => $self->major_version,
          format    => $v_format,
          time_zone => 'America/New_York',
        }
      ]);
    } else {
      $self->add_plugins([
        'Git::NextVersion' => {
          version_regexp => '^([0-9]+\.[0-9]+)$',
        }
      ]);
    }
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

  if ($self->is_task) {
    $self->add_plugins('TaskWeaver');
  } else {
    $self->add_plugins([
      PodWeaver => {
        config_plugin => $self->weaver_config,
        replacer      => 'replace_with_comment',
      }
    ]);
  }

  $self->add_plugins(
    [ GithubMeta => {
      remote => [ qw(github origin) ],
      issues => $self->github_issues,
      (length $self->homepage ? (homepage => $self->homepage) : ()),
    } ],
  );

  $self->add_bundle('@Git' => {
    tag_format => '%v',
    remotes_must_exist => 0,
    push_to    => [
      'origin :',
      'github :',
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

Dist::Zilla::PluginBundle::RJBS - BeLike::RJBS when you build your dists

=head1 VERSION

version 5.010

=head1 DESCRIPTION

This is the plugin bundle that RJBS uses.  It is more or less equivalent to:

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
  config_plugin = @RJBS

  [GithubMeta]
  remote = github
  remote = origin

  [@Git]
  tag_format = %v

  [Git::Contributors]

If the C<task> argument is given to the bundle, PodWeaver is replaced with
TaskWeaver and Git::NextVersion is replaced with AutoVersion.  If the
C<manual_version> argument is given, AutoVersion is omitted.

If the C<github_issues> argument is given, and true, the F<META.*> files will
point to GitHub issues for the dist's bugtracker.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
