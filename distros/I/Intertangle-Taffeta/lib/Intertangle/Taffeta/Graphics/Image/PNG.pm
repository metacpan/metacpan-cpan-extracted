use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Image::PNG;
# ABSTRACT: Raster data stored in PNG format
$Intertangle::Taffeta::Graphics::Image::PNG::VERSION = '0.001';
use Moo;
use Renard::Incunabula::Common::Types qw(Str InstanceOf Int);
use Intertangle::Taffeta::Types qw(SVG);
use MIME::Base64;
use Image::Size;

extends qw(Intertangle::Taffeta::Graphics::Image);

has data => (
	is => 'ro',
	isa => Str,
	required => 1,
);

method _build_cairo_image_surface() :ReturnType(InstanceOf['Cairo::ImageSurface']) {
	# read the PNG data in-memory
	my $img = Cairo::ImageSurface->create_from_png_stream(
		my $cb = fun ( (Str) $callback_data, (Int) $length ) {
			state $offset = 0;
			my $data = substr $callback_data, $offset, $length;
			$offset += $length;
			$data;
		}, $self->data );

	return $img;
}

method _build_size() :ReturnType(InstanceOf['Intertangle::Yarn::Graphene::Size']) {
	my ($width, $height, $id_or_error) = Image::Size::imgsize( \($self->data) );
	die "Could not compute bounds: $id_or_error" unless $id_or_error eq 'PNG';
	Intertangle::Yarn::Graphene::Size->new(
		width => $width,
		height => $height,
	);
}

method render_svg( (SVG) $svg ) {
	$svg->image(
		x => $self->origin->x,
		y => $self->origin->y,
		'-href' => "data:image/png;base64,@{[ encode_base64( $self->data ) ]}",
		$self->svg_transform_parameter,
	);
}

with qw(
	Intertangle::Taffeta::Graphics::Image::Role::FromCairoImageSurface
	Intertangle::Taffeta::Graphics::Role::SVGRenderable
	Intertangle::Taffeta::Graphics::Role::WithBounds
	Intertangle::Taffeta::Graphics::Role::WithTransform
	Intertangle::Taffeta::Graphics::Role::SVGRenderable::Transform
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Image::PNG - Raster data stored in PNG format

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Intertangle::Taffeta::Graphics::Image>

=back

=head1 CONSUMES

=over 4

=item * L<Intertangle::Taffeta::Graphics::Image::Role::FromCairoImageSurface>

=item * L<Intertangle::Taffeta::Graphics::Role::CairoRenderable>

=item * L<Intertangle::Taffeta::Graphics::Role::SVGRenderable>

=item * L<Intertangle::Taffeta::Graphics::Role::SVGRenderable::Transform>

=item * L<Intertangle::Taffeta::Graphics::Role::WithBounds>

=item * L<Intertangle::Taffeta::Graphics::Role::WithTransform>

=back

=head1 ATTRIBUTES

=head2 data

A C<Str> that contains the PNG binary data.

=head1 METHODS

=head2 render_svg

See L<Intertangle::Taffeta::Graphics::Role::SVGRenderable>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
