use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Rectangle;
# ABSTRACT: Graphics object for raster images
$Intertangle::Taffeta::Graphics::Rectangle::VERSION = '0.001';
use Moo;

extends qw(Intertangle::Taffeta::Graphics);

use Intertangle::Taffeta::Types qw(CairoContext SVG Dimension);

has [qw(width height)] => (
	is => 'ro',
	isa => Dimension,
	required => 1,
);

method _build_size() {
	Intertangle::Yarn::Graphene::Size->new(
		width => $self->width,
		height => $self->height,
	);
}

method cairo_path( (CairoContext) $cr ) {
	$cr->rectangle(
		$self->origin->x,
		$self->origin->y,
		$self->width,
		$self->height,
	);
}

method render_svg( (SVG) $svg ) {
	$svg->rectangle(
		x => $self->origin->x,
		y => $self->origin->y,
		width => $self->width,
		height => $self->height,
		$self->svg_style_parameter,
		$self->svg_transform_parameter,
	);
}

with qw(
	Intertangle::Taffeta::Graphics::Role::WithBounds
	Intertangle::Taffeta::Graphics::Role::WithFill
	Intertangle::Taffeta::Graphics::Role::WithTransform
	Intertangle::Taffeta::Graphics::Role::WithStroke
	Intertangle::Taffeta::Graphics::Role::CairoRenderable::WithCairoPath
	Intertangle::Taffeta::Graphics::Role::SVGRenderable
	Intertangle::Taffeta::Graphics::Role::SVGRenderable::Style
	Intertangle::Taffeta::Graphics::Role::SVGRenderable::Transform
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Rectangle - Graphics object for raster images

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Intertangle::Taffeta::Graphics>

=back

=head1 CONSUMES

=over 4

=item * L<Intertangle::Taffeta::Graphics::Role::CairoRenderable>

=item * L<Intertangle::Taffeta::Graphics::Role::CairoRenderable::WithCairoPath>

=item * L<Intertangle::Taffeta::Graphics::Role::SVGRenderable>

=item * L<Intertangle::Taffeta::Graphics::Role::SVGRenderable::Style>

=item * L<Intertangle::Taffeta::Graphics::Role::SVGRenderable::Transform>

=item * L<Intertangle::Taffeta::Graphics::Role::WithBounds>

=item * L<Intertangle::Taffeta::Graphics::Role::WithFill>

=item * L<Intertangle::Taffeta::Graphics::Role::WithStroke>

=item * L<Intertangle::Taffeta::Graphics::Role::WithTransform>

=back

=head1 ATTRIBUTES

=head2 width

The width of the rectangle.

=head2 height

The height of the rectangle.

=head1 METHODS

=head2 cairo_path

See L<Intertangle::Taffeta::Graphics::Role::CairoRenderable::WithCairoPath>.

=head2 render_svg

See L<Intertangle::Taffeta::Graphics::Role::SVGRenderable>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
