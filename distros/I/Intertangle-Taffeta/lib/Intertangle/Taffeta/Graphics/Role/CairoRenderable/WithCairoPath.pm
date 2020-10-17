use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Role::CairoRenderable::WithCairoPath;
# ABSTRACT: A role to help draw a Cairo path with styles/transformations
$Intertangle::Taffeta::Graphics::Role::CairoRenderable::WithCairoPath::VERSION = '0.001';
use Moo::Role;
use Intertangle::Taffeta::Types qw(CairoContext);

method cairo_path( (CairoContext) $cr ) {
	...
}


method render_cairo( (CairoContext) $cr ) {
	$cr->save;

	$cr->set_matrix(
		$self->transform->cairo_matrix
	);

	if( $self->has_fill && ! $self->fill->is_fill_none ) {
		$cr->set_source_rgba(
			$self->fill->color->rgb_float_triple,
			$self->fill->opacity);

		$self->cairo_path( $cr );
		$cr->fill;
	}
	if( $self->has_stroke && ! $self->stroke->is_stroke_none ) {
		$cr->set_line_width( $self->stroke->width );
		$cr->set_source_rgba(
			$self->stroke->color->rgb_float_triple,
			$self->stroke->opacity);

		$self->cairo_path( $cr );
		$cr->stroke;
	}

	$cr->restore;
}

with qw(
	Intertangle::Taffeta::Graphics::Role::CairoRenderable
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Role::CairoRenderable::WithCairoPath - A role to help draw a Cairo path with styles/transformations

=head1 VERSION

version 0.001

=head1 CONSUMES

=over 4

=item * L<Intertangle::Taffeta::Graphics::Role::CairoRenderable>

=back

=head1 METHODS

=head2 cairo_path

  method cairo_path( (CairoContext) $cr )

Draws a path using Cairo. This needs to implemented by role consumers.

=head2 render_cairo

See L<Intertangle::Taffeta::Graphics::Role::CairoRenderable>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
