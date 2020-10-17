use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Style::Fill;
# ABSTRACT: Fill style
$Intertangle::Taffeta::Style::Fill::VERSION = '0.001';
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

method is_fill_none() :ReturnType(Bool) {
	return ! $self->has_color && ! $self->has_opacity;
}

method svg_style() {
	my $data = {};

	if( $self->is_fill_none ) {
		$data->{fill} = 'none';
	} elsif( $self->has_color ) {
		$data->{fill} = $self->color->svg_value;
	}

	if( $self->has_opacity ) {
		$data->{'fill-opacity'} = $self->opacity;
	}

	$data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Style::Fill - Fill style

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 opacity

The C<Opacity> for the fill.

=head2 color

The C<Color> for the fill.

=head1 METHODS

=head2 has_opacity

Predicate for C<opacity> attribute.

=head2 has_color

Predicate for the C<color> attribute.

=head2 is_fill_none

Returns a C<Bool> for if the fill is empty.

=head2 svg_style

Returns a C<HashRef> that represents the SVG style for this fill.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
