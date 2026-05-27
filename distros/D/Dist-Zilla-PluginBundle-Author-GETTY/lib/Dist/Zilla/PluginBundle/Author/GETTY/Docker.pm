package Dist::Zilla::PluginBundle::Author::GETTY::Docker;
# ABSTRACT: Docker image subsection for @Author::GETTY
our $VERSION = '0.315';
use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

sub mvp_multivalue_args { qw(tags build_arg label platform) }

sub configure {
  my $self = shift;

  my $payload = $self->payload;
  no warnings 'once';
  my $defaults = \%Dist::Zilla::PluginBundle::Author::GETTY::DOCKER_DEFAULTS;
  use warnings 'once';

  my $image = $payload->{image} // $defaults->{image};
  unless (defined $image && length $image) {
    require Carp;
    Carp::croak(
      "[" . $self->name . "] needs either `image = ...` in this subsection "
      . "or `docker_image = ...` in [\@Author::GETTY]"
    );
  }

  my $tags = $self->_normalize_tags($payload->{tags})
          // $self->_normalize_tags($defaults->{tags})
          // ['latest', '%V', '%v'];

  my $local = exists $payload->{local} ? $payload->{local}
            : exists $defaults->{local} ? $defaults->{local}
            : 0;

  my %plugin_args = (
    image        => $image,
    tag          => $tags,
    build_load   => 1,
    release_push => $local ? 0 : 1,
  );

  $plugin_args{_target}       = $payload->{target}       if defined $payload->{target};
  $plugin_args{_network_mode} = $payload->{network_mode} if defined $payload->{network_mode};

  for my $k (qw(
    dockerfile build_arg label platform release_load build_verbose
    pull no_cache rm force_rm fail_if_tag_exists skip_latest_on_trial
  )) {
    $plugin_args{$k} = $payload->{$k} if exists $payload->{$k};
  }

  $self->add_plugins([ 'Docker::API' => \%plugin_args ]);
}

sub _normalize_tags {
  my ($self, $tags) = @_;
  return undef unless defined $tags;
  my @list = ref $tags eq 'ARRAY' ? @$tags : ($tags);
  my @split = map { split /\s+/ } grep { defined && length } @list;
  return @split ? \@split : undef;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::GETTY::Docker - Docker image subsection for @Author::GETTY

=head1 VERSION

version 0.315

=head1 SYNOPSIS

  [@Author::GETTY]
  docker_image = registry/app
  docker_tags  = latest %v

  [@Author::GETTY::Docker / runtime-root]
  target = runtime-root

  [@Author::GETTY::Docker / runtime-user]
  target = runtime-user
  tags   = user
  local  = 1

=head1 DESCRIPTION

A subsection bundle of L<@Author::GETTY|Dist::Zilla::PluginBundle::Author::GETTY>
that creates a single L<Dist::Zilla::Plugin::Docker::API> plugin per occurrence.

Each subsection inherits C<image>, C<tags>, and C<local> from the parent
C<@Author::GETTY> bundle (via C<docker_image>, C<docker_tags>, C<docker_local>)
unless explicitly overridden.

=head1 ATTRIBUTES

=head2 image

Docker image repository. Inherited from the parent bundle's C<docker_image>
when omitted. Fatal if neither is set.

=head2 target

Optional multi-stage Dockerfile target.

=head2 tags

Whitespace-separated list of tags to apply to both build and release. Inherited
from the parent's C<docker_tags> when omitted. Defaults to C<latest %V %v>
(e.g. C<latest>, C<0>, C<0.402> for version C<0.402>). Setting C<tags>
explicitly B<replaces> the default list; it does not append.

=head2 local

If true, sets C<release_push = 0> on the Docker::API plugin so the image is
built and tagged locally but not pushed to the registry. Inherited from the
parent's C<docker_local> when omitted.

=head2 network_mode

Optional Docker C<--network> mode for the build.

=head2 dockerfile

Path to the Dockerfile. Passed through to C<Docker::API> unchanged.

=head2 context

Build context path. Passed through to C<Docker::API> unchanged.

=head2 build_arg

Build-time argument (C<--build-arg>). Multi-value — repeat the key to set
multiple arguments.

=head2 label

Image label. Multi-value.

=head2 platform

Target platform (C<--platform>). Multi-value.

=head2 release_load, build_verbose, pull, no_cache, rm, force_rm, fail_if_tag_exists, skip_latest_on_trial

Passed through directly to L<Dist::Zilla::Plugin::Docker::API>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
