use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Color::RGBFloat;
# ABSTRACT: A floating point RGB colour
$Intertangle::Taffeta::Color::RGBFloat::VERSION = '0.001';
use Mu;
use Intertangle::Taffeta::Types qw(RGBFloatComponentValue);

extends qw(Intertangle::Taffeta::Color);

has r_float => ( is => 'ro', isa => RGBFloatComponentValue );

has g_float => ( is => 'ro', isa => RGBFloatComponentValue );

has b_float => ( is => 'ro', isa => RGBFloatComponentValue );

method rgb_float_triple() {
	($self->r_float, $self->g_float, $self->b_float);
}

method svg_value() {
	sprintf("rgb(%f%%, %f%%, %f%%)",
		$self->r_float * 100,
		$self->g_float * 100,
		$self->b_float * 100,
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Color::RGBFloat - A floating point RGB colour

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Intertangle::Taffeta::Color>

=back

=head1 ATTRIBUTES

=head2 r_float

Red component as C<RGBFloatComponentValue>.

=head2 g_float

Green component as C<RGBFloatComponentValue>.

=head2 b_float

Blue component as C<RGBFloatComponentValue>.

=head1 METHODS

=head2 rgb_float_triple

Returns a list of the float components C<(r_float, g_float, b_float)>.

=head2 svg_value

A C<Str> representing the floating point RGB triple as a percentage RGB

  rgb(25%,50%,75%)

is the SVG value for

  Intertangle::Taffeta::Color::RGBFloat->new(
    r_float => 0.25,
    g_float => 0.50,
    b_float => 0.75,
  );

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
