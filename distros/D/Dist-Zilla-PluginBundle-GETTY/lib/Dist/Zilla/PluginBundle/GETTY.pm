package Dist::Zilla::PluginBundle::GETTY;
BEGIN {
  $Dist::Zilla::PluginBundle::GETTY::AUTHORITY = 'cpan:GETTY';
}
{
  $Dist::Zilla::PluginBundle::GETTY::VERSION = '0.008';
}
# ABSTRACT: B<DEPRECATED> PLEASE USE L<Dist::Zilla::PluginBundle::Author::GETTY> instead

use Moose;
use Moose::Autobox;
use Dist::Zilla 2.100922; # TestRelease
with 'Dist::Zilla::Role::PluginBundle::Easy';


use Dist::Zilla::PluginBundle::Basic;
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

has weaver_config => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{weaver_config} || '@GETTY' },
);

sub configure {
  my ($self) = @_;

  $self->log_fatal("you must not specify both weaver_config and is_task")
    if $self->is_task and $self->weaver_config ne '@GETTY';

  $self->add_bundle('@Basic');

  unless ($self->manual_version) {
    if ($self->is_task) {
      my $v_format = q<{{cldr('yyyyMMdd')}}>
                   . sprintf('.%03u', ($ENV{N} || 0));

      $self->add_plugins([
        AutoVersion => {
          major     => $self->major_version,
          format    => $v_format,
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

	$self->add_plugins(qw(
		PkgVersion
		MetaConfig
		MetaJSON
		NextRelease
		PodSyntaxTests
		Repository
		GithubMeta
	));

	$self->add_plugins([
		'InstallRelease' => {
			install_command => 'cpanm .',
		}
	]);

	$self->add_plugins([
		'Authority' => {
			authority => 'cpan:GETTY',
			do_metadata => 1,
		}
	]);

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
      PodWeaver => { config_plugin => $self->weaver_config }
    ]);
  }

  $self->add_bundle('@Git' => {
    tag_format => '%v',
    push_to    => [ qw(origin) ],
  });
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::PluginBundle::GETTY - B<DEPRECATED> PLEASE USE L<Dist::Zilla::PluginBundle::Author::GETTY> instead

=head1 VERSION

version 0.008

=head1 DESCRIPTION

B<DEPRECATED> This is the plugin bundle that GETTY uses.  It is equivalent to:

  [@Basic]

  [Git::NextVersion]
  [PkgVersion]
  [MetaConfig]
  [MetaJSON]
  [NextRelease]
  [PodSyntaxTests]
  [GithubMeta]
  [InstallRelease]
  install_command = cpanm .

  [Authority]
  authority = cpan:GETTY
  do_metadata = 1

  [PodWeaver]
  config_plugin = @GETTY

  [Repository]

  [@Git]
  tag_format = %v
  push_to = origin

If the C<task> argument is given to the bundle, PodWeaver is replaced with
TaskWeaver and Git::NextVersion is replaced with AutoVersion.  If the
C<manual_version> argument is given, AutoVersion is omitted. 

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by L<Torsten Raudssus|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

