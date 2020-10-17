use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Polygon;
# ABSTRACT: A segmented shape made up of points
$Intertangle::Taffeta::Graphics::Polygon::VERSION = '0.001';
use Moo;

extends qw(Intertangle::Taffeta::Graphics);

use Renard::Incunabula::Common::Types qw(ArrayRef);
use Intertangle::Yarn::Types qw(Point);
use Intertangle::Taffeta::Types qw(CairoContext SVG);

use List::AllUtils qw(minmax);

has points => (
	is => 'ro',
	isa => ArrayRef[Point],
	required => 1,
	coerce => 1,
);

method _build_size() {
	my ($min_x, $max_x) = minmax map { $_->x } @{ $self->points };
	my ($min_y, $max_y) = minmax map { $_->y } @{ $self->points };

	Intertangle::Yarn::Graphene::Size->new(
		width => $max_x - $min_x,
		height => $max_y - $min_y,
	);
}

method cairo_path( (CairoContext) $cr ) {
	my @pts = @{ $self->points };
	$cr->move_to( $pts[0]->x, $pts[0]->y );
	for my $pt_idx (1..@pts-1) {
		$cr->line_to(
			$pts[$pt_idx]->x,
			$pts[$pt_idx]->y,
		);
	}
}

method render_svg( (SVG) $svg ) {
	my $path = $svg->get_path(
		x => [ map { $_->x } @{ $self->points } ],
		y => [ map { $_->y } @{ $self->points } ],
		-type => 'polygon',
	);

	$svg->polygon(
		%$path,
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

Intertangle::Taffeta::Graphics::Polygon - A segmented shape made up of points

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

=head2 points

An C<ArrayRef> of points.

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
