package Dist::Zilla::PluginBundle::INGY;
{
  $Dist::Zilla::PluginBundle::INGY::VERSION = '0.0.4';
}

use Moose;
use Moose::Autobox;
use Dist::Zilla 2.100922; # TestRelease
with 'Dist::Zilla::Role::PluginBundle::Easy';
with 'Dist::Zilla::Role::PluginBundle::Config::Slicer';


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
  default => sub { $_[0]->payload->{github_issues} },
);

sub configure {
  my ($self) = @_;

  $self->add_plugins('Git::GatherDir');
  $self->add_plugins('CheckPrereqsIndexed');
  $self->add_plugins('CheckExtraTests');
  $self->add_bundle('@Filter', {
    '-bundle' => '@Basic',
    '-remove' => [ 'GatherDir', 'ExtraTests' ],
  });

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
          version_regexp => '^([0-9]+\.[0-9]+(?:\.[0-9]+)?)$',
        }
      ]);
    }
  }

  $self->add_plugins(qw(
    ReadmeFromPod
    PkgVersion
    MetaConfig
    MetaJSON
    NextRelease
  ),
  # XXX Fix for ingy style
  # Test::ChangesHasContent
  qw(
    PodSyntaxTests
    Test::Compile
    ReportVersions::Tiny
  ));

  $self->add_plugins(
    [ Prereqs => 'TestMoreWithSubtests' => {
      -phase => 'test',
      -type  => 'requires',
      'Test::More' => '0.96'
    } ],
  );

  $self->add_plugins(
    [ GithubMeta => {
      user   => 'ingydotnet',
      remote => [ qw(origin) ],
      issues => $self->github_issues,
    } ],
  );

  $self->add_bundle('@Git' => {
    tag_format => '%v',
    remotes_must_exist => 0,
    push_to    => [
      'origin :',
    ],
  });
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=encoding utf8

=head1 NAME

Dist::Zilla::PluginBundle::INGY - BeLike::INGY when you build your dists

=head1 SYNOPSIS

In your F<dist.ini>:

    [@INGY]

=head1 DESCRIPTION

This is the plugin bundle that INGY uses.  It is more or less equivalent to:

  [Git::GatherDir]
  [@Basic]
  ; ...but without GatherDir and ExtraTests

  [AutoPrereqs]
  [Git::NextVersion]
  [PkgVersion]
  [MetaConfig]
  [MetaJSON]
  [NextRelease]

  [Test::ChangesHasContent]
  [PodSyntaxTests]
  [Test::Compile]
  [ReportVersions::Tiny]

  [GithubMeta]
  user = INGY
  remote = origin

  [@Git]
  tag_format = %v

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
