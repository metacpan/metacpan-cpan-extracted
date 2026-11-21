package Dist::Zilla::PluginBundle::Author::GETTY::Binary;
# ABSTRACT: Standalone binary subsection for @Author::GETTY
our $VERSION = '0.329';
use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use Carp ();

sub mvp_multivalue_args { qw(modules require platforms) }  # platforms: so the dist-wide error can name it

my %DIST_WIDE = ( platforms => 'binary_platforms', prepare => 'binary_prepare' );

sub configure {
  my $self = shift;

  my $payload = $self->payload;
  no warnings 'once';
  my $defaults = \%Dist::Zilla::PluginBundle::Author::GETTY::BINARY_DEFAULTS;
  use warnings 'once';

  # Binaries need the GitHub release they are attached to.
  Carp::croak("[" . $self->name . "] a binary release needs the GitHub release, but the "
    . "release plugin is not active (no_github, no_github_release or no GitHub remote)")
    if exists $defaults->{has_release} && !$defaults->{has_release};

  for my $k (sort keys %DIST_WIDE) {
    Carp::croak("[" . $self->name . "] $k is dist-wide: set $DIST_WIDE{$k} in [\@Author::GETTY], not per binary")
      if exists $payload->{$k};
  }

  my $name = $payload->{binary_name};
  unless (defined $name) {
    ($name = $self->name) =~ s{\A.*/\s*}{};
  }

  my %plugin_args = ( binary_name => $name );
  $plugin_args{script} = $payload->{script} // "bin/$name";

  for my $k (qw( modules require )) {
    my $list = $self->_normalize($payload->{$k}) // $self->_normalize($defaults->{$k});
    $plugin_args{$k} = $list if $list;
  }
  for my $k (qw( pp_args verify smoke )) {
    my $v = $payload->{$k} // $defaults->{$k};
    $plugin_args{$k} = $v if defined $v;
  }
  # Dist-wide, from the parent's binary_platforms / binary_prepare only.
  my $platforms = $self->_normalize($defaults->{platforms});
  $plugin_args{platforms} = $platforms if $platforms;
  $plugin_args{prepare} = $defaults->{prepare} if defined $defaults->{prepare};

  $self->add_plugins([ 'Author::GETTY::Binary' => $name => \%plugin_args ]);
}

sub _normalize {
  my ($self, $list) = @_;
  return undef unless defined $list;
  my @list = ref $list eq 'ARRAY' ? @$list : ($list);
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

Dist::Zilla::PluginBundle::Author::GETTY::Binary - Standalone binary subsection for @Author::GETTY

=head1 VERSION

version 0.329

=head1 SYNOPSIS

  [@Author::GETTY]
  binary = foo

  [@Author::GETTY::Binary / bar]
  script  = script/bar.pl
  modules = Some::Module

=head1 DESCRIPTION

A subsection bundle of L<@Author::GETTY|Dist::Zilla::PluginBundle::Author::GETTY>
that adds one L<Dist::Zilla::Plugin::Author::GETTY::Binary> plugin per
occurrence. C<modules>, C<require>, C<pp_args>, C<verify> and C<smoke> are
inherited from the parent's C<binary_*> keys unless set here; C<script>
defaults to F<bin/NAME>. C<platforms> and C<prepare> are dist-wide: set
C<binary_platforms> and C<binary_prepare> in the parent; a subsection that sets
them is refused. The key reference and the release workflow are in the
C<Binaries> section of L<Dist::Zilla::PluginBundle::Author::GETTY>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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
