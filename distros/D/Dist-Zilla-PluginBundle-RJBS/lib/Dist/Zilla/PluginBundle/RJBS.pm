package Dist::Zilla::PluginBundle::RJBS 5.021;
# ABSTRACT: BeLike::RJBS when you build your dists

use Moose;
use Dist::Zilla 2.100922; # TestRelease
with
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
    'Dist::Zilla::Role::PluginBundle::Config::Slicer';

use v5.20.0;
use experimental 'postderef'; # Not really an experiment anymore.
use utf8;

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
#pod   eumm_version = 6.78
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
#pod This bundle makes use of L<Dist::Zilla::Role::PluginBundle::PluginRemover> and
#pod L<Dist::Zilla::Role::PluginBundle::Config::Slicer> to allow further customization.
#pod
#pod =cut

use Dist::Zilla::PluginBundle::Basic;
use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Git;

package Dist::Zilla::Plugin::RJBSMisc 5.021 {
  use Moose;
  with 'Dist::Zilla::Role::BeforeBuild',
       'Dist::Zilla::Role::AfterBuild',
       'Dist::Zilla::Role::MetaProvider',
       'Dist::Zilla::Role::PrereqSource';

  has perl_window => (is => 'ro');
  has package_name_version => (is => 'ro');

  sub metadata {
    my ($self) = @_;

    return { x_rjbs_perl_window => $self->perl_window };
  }

  sub register_prereqs {
    my ($self) = @_;

    if ($self->package_name_version) {
      $self->zilla->register_prereqs(
        { phase => 'runtime', type => 'requires' },
        perl => '5.012',
      );
    }
  }

  sub before_build {
    my ($self) = @_;

    if (($self->perl_window // '') eq 'toolchain' && $self->package_name_version) {
      $self->log_fatal('This dist claims to be toolchain but uses "package NAME VERSION"');
    }

    unless (defined $self->perl_window) {
      $self->log("❗️ did not set perl-window!");
    }
  }

  sub after_build {
    my ($self) = @_;

    if (grep {; /rjbs\@cpan\.org/ } $self->zilla->authors->@*) {
      $self->log('Authors still contain rjbs@cpan.org!  Needs an update.');
    }
  }
}

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

sub mvp_aliases {
  return {
    'is-task'       => 'is_task',
    'major-version' => 'major_version',
    'perl-window'   => 'perl_window',
    'dont-compile'  => 'dont_compile',
    'weaver-config' => 'weaver_config',
    'manual-version'       => 'manual_version',
    'primary-branch'       => 'primary_branch',
    'package-name-version' => 'package_name_version',
  }
}

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
  default => sub { $_[0]->payload->{package_name_version}
                // $_[0]->payload->{'package-name-version'}
                // 1
  },
);

has perl_window => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    # XXX: Fix this better.
    # See, we have all these mvp aliases to convert foo-bar to foo_bar, but
    # those aliases aren't run on the bundle options when passed through a
    # @Filter.  So:
    #
    # [@Filter]
    # -bundle = @RJBS
    # perl-window = no-mercy
    #
    # ...didn't work, because the payload had 'perl-window' and not
    # 'perl_window'.  Probably this aliasing should happen during the @Filter
    # process, but it's kind of a hot mess in here.  This key is the most
    # important one, and this comment is here to remind me what happened if I
    # ever hear this on some other library.
    $_[0]->payload->{perl_window} // $_[0]->payload->{'perl-window'}
  },
);

has primary_branch => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    # XXX: Fix this better.  See matching comment in perl_window attr.
    return $_[0]->payload->{primary_branch}
        // $_[0]->payload->{'primary-branch'}
        // 'main'
  },
);

sub configure {
  my ($self) = @_;

  # It'd be nice to have a Logger here... -- rjbs, 2021-04-24
  die "you must not specify both weaver_config and is_task"
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
      skip  => [ 'Dist::Zilla::Plugin::RJBSMisc' ],
      # check_all_prereqs => 1, # <-- not sure yet -- rjbs, 2013-09-23
    } ],
  );
  $self->add_bundle('@Filter', {
    '-bundle' => '@Basic',
    '-remove' => [ 'GatherDir', 'ExtraTests', 'MakeMaker' ],
  });

  $self->add_plugins([
    MakeMaker => {
      default_jobs  => 9,
      eumm_version  =>  6.78, # Stop using -w when running tests.
    }
  ]);

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
          version_by_branch => 1,
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
    [
      'Git::Remote::Check' => {
        remote_name   => 'github',
        remote_branch => $self->primary_branch,
        branch        => $self->primary_branch,
        do_update     => 1,
      },
    ],
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
    our $perl_window = $self->perl_window;
    $self->add_plugins([
      PodWeaver => {
        config_plugin => $self->weaver_config,
        replacer      => 'replace_with_comment',
      }
    ]);
  }

  $self->add_plugins(
    [ RJBSMisc => {
        map {; $_ => scalar $self->$_ } qw(
          package_name_version
          perl_window
        )
    } ],
  );

  $self->add_plugins(
    [ GithubMeta => {
      remote => [ qw(github) ],
      issues => $self->github_issues,
      (length $self->homepage ? (homepage => $self->homepage) : ()),
    } ],
  );

  $self->add_bundle('@Git' => {
    tag_format => '%v',
    remotes_must_exist => 0,
    push_to    => [
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

version 5.021

=head1 DESCRIPTION

This is the plugin bundle that RJBS uses.  It is more or less equivalent to:

  [Git::GatherDir]
  [@Basic]
  ; ...but without GatherDir and ExtraTests and MakeMaker

  [MakeMaker]
  default_jobs = 9
  eumm_version = 6.78

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

This bundle makes use of L<Dist::Zilla::Role::PluginBundle::PluginRemover> and
L<Dist::Zilla::Role::PluginBundle::Config::Slicer> to allow further customization.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is no
promise that patches will be accepted to lower the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Ricardo Signes

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
