use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Style::Stroke;
# ABSTRACT: Stroke style
$Intertangle::Taffeta::Style::Stroke::VERSION = '0.001';
use Moo;
use Renard::Incunabula::Common::Types qw(Bool);
use Intertangle::Taffeta::Types qw(Color Opacity Dimension);

has opacity => (
	is => 'ro',
	predicate => 1,
	default => sub { 1 },
	isa => Opacity,
);

has color => (
	is => 'ro',
	predicate => 1,
	isa => Color,
);

has width => (
	is => 'ro',
	predicate => 1,
	default => sub { 1 },
	isa => Dimension,
);

method is_stroke_none() :ReturnType(Bool) {
	return ! $self->has_color && ! $self->has_opacity;
}

method svg_style() {
	my $data = {};

	if( $self->is_stroke_none ) {
		$data->{stroke} = 'none';
	} elsif( $self->has_color ) {
		$data->{stroke} = $self->color->svg_value;
	}

	if( $self->has_opacity ) {
		$data->{'stroke-opacity'} = $self->opacity;
	}

	if( $self->has_width ) {
		$data->{'stroke-width'} = $self->width;
	}

	$data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Style::Stroke - Stroke style

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 opacity

The C<Opacity> for the stroke.

=head2 color

The C<Color> for the stroke.

=head2 width

A C<Dimension> for the width of the stroke line.

=head1 METHODS

=head2 has_opacity

Predicate for C<opacity> attribute.

=head2 has_color

Predicate for the C<color> attribute.

=head2 has_width

Predicate for C<width> attribute.

=head2 is_stroke_none

Returns a C<Bool> for if the stroke is empty.

=head2 svg_style

Returns a C<HashRef> that represents the SVG style for this stroke.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
