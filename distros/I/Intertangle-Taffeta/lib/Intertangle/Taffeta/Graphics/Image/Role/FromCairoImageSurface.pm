use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Image::Role::FromCairoImageSurface;
# ABSTRACT: Use a Cairo image surface to render image
$Intertangle::Taffeta::Graphics::Image::Role::FromCairoImageSurface::VERSION = '0.001';
use Moo::Role;

use Renard::Incunabula::Common::Types qw(InstanceOf);
use Intertangle::Taffeta::Types qw(CairoContext);

has cairo_image_surface => (
	is => 'lazy', # _build_cairo_image_surface
	isa => InstanceOf['Cairo::ImageSurface'],
);

method render_cairo( (CairoContext) $cr ) {
	$cr->save;

	$cr->set_matrix(
		$self->transform->cairo_matrix
		->multiply(
			$cr->get_matrix
		)
	);

	my $img_surface = $self->cairo_image_surface;
	$cr->set_source_surface($img_surface,
		$self->origin->x,
		$self->origin->y);
	$cr->paint;

	$cr->restore;
}

with qw(
	Intertangle::Taffeta::Graphics::Role::CairoRenderable
	Intertangle::Taffeta::Graphics::Role::WithTransform
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Image::Role::FromCairoImageSurface - Use a Cairo image surface to render image

=head1 VERSION

version 0.001

=head1 CONSUMES

=over 4

=item * L<Intertangle::Taffeta::Graphics::Role::CairoRenderable>

=item * L<Intertangle::Taffeta::Graphics::Role::WithTransform>

=back

=head1 METHODS

=head2 render_cairo

See L<Intertangle::Taffeta::Graphics::Role::CairoRenderable>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
