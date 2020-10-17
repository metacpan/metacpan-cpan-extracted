use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Role::SVGRenderable::Style;
# ABSTRACT: Role for style SVG parameters
$Intertangle::Taffeta::Graphics::Role::SVGRenderable::Style::VERSION = '0.001';
use Moo::Role;

requires 'fill';
requires 'stroke';

method svg_style_parameter() {
	my $style = {};

	if( $self->has_fill ) {
		$style = { %$style, %{ $self->fill->svg_style } };
	}

	if( $self->has_stroke ) {
		$style = { %$style, %{ $self->stroke->svg_style } };
	}

	return ( style => $style );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Role::SVGRenderable::Style - Role for style SVG parameters

=head1 VERSION

version 0.001

=head1 METHODS

=head2 svg_style_parameter

Returns style parameter for SVG based on fill and stroke style attributes.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
