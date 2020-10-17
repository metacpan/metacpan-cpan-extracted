use Renard::Incunabula::Common::Setup;
package TestHelper;
# ABSTRACT: A helper for the tests

use List::AllUtils qw(count_by);
use Intertangle::Yarn::Types qw(Point);

classmethod svg( :$render, :$width, :$height ) {
	require SVG;
	SVG->import;

	my $svg = SVG->new( width => $width, height => $height );

	$render->render_svg( $svg );

	return $svg;
}

classmethod cairo( :$render, :$width, :$height ) {
	require Cairo;
	my $surface = Cairo::ImageSurface->create('argb32', $width, $height);

	my $cr = Cairo::Context->create( $surface );

	$render->render_cairo( $cr );

	my @data = unpack 'L*', $surface->get_data; # uint32_t
	my %counts = count_by { $_ } @data;

	return {
		surface => $surface,
		counts => \%counts
	};
}

classmethod cairo_surface_contains( :$source_surface, :$sub_surface, :$origin ) {
	$origin = Point->coerce( $origin );
	my ($format, $width, $height) = (
		$sub_surface->get_format,
		$sub_surface->get_width,
		$sub_surface->get_height
	);

	# crop the original PNG out of the surface we rendered to
	my $crop_surface = Cairo::ImageSurface->create($format, $width, $height);
	my $crop_cr = Cairo::Context->create( $crop_surface );
	$crop_cr->set_source_surface( $source_surface,
		-( $origin->x ), -( $origin->y ) );
	$crop_cr->paint;

	$sub_surface->get_data eq $crop_surface->get_data;
}


1;
