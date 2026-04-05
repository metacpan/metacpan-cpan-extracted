package Langertha::Role::ImageGeneration;
# ABSTRACT: Role for engines that support image generation
our $VERSION = '0.308';
use Moose::Role;
use Carp qw( croak );


requires 'image_request';
requires 'simple_image';

has image_model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy_build => 1,
);
sub _build_image_model {
  my ( $self ) = @_;
  croak "".(ref $self)." can't handle models!" unless $self->does('Langertha::Role::Models');
  return $self->default_image_model if $self->can('default_image_model');
  return $self->model;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ImageGeneration - Role for engines that support image generation

=head1 VERSION

version 0.308

=head1 DESCRIPTION

Engines that can generate images consume this role. It requires
C<image_request> and C<simple_image> methods, and provides an
C<image_model> attribute.

=head2 image_model

The model name to use for image generation requests. Lazily defaults to
C<default_image_model> if the engine provides it, otherwise falls back
to the general C<model> attribute from L<Langertha::Role::Models>.

=head1 SEE ALSO

=over

=item * L<Langertha::ImageGen> - Wrapper class for image generation with plugin support

=item * L<Langertha::Role::Models> - Model selection role

=item * L<Langertha::Plugin::Langfuse> - Observability plugin (hooks into image gen)

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
