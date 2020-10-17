use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Color::Named;
# ABSTRACT: A named colour
$Intertangle::Taffeta::Color::Named::VERSION = '0.001';
use Mu;
use Renard::Incunabula::Common::Setup;
use Intertangle::Taffeta::Types qw(ColorLibrary RGB24Value);

extends qw(Intertangle::Taffeta::Color);

has name => (
	is => 'ro',
	required => 1,
	isa => ColorLibrary,
	coerce => 1,
);

lazy value => method() {
		$self->name->value
	},
	isa => RGB24Value;

with qw(Intertangle::Taffeta::Color::Role::SVG Intertangle::Taffeta::Color::Role::RGB24Components);

# Needs to be after the role.
around _build_svg_value => fun($orig, $self) {
	if( $self->name->id =~ /^svg:/ ) {
		# if under the SVG color library
		return $self->name->name;
	} else {
		$orig->($self);
	}
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Color::Named - A named colour

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Intertangle::Taffeta::Color>

=back

=head1 CONSUMES

=over 4

=item * L<Intertangle::Taffeta::Color::Role::RGB24Components>

=item * L<Intertangle::Taffeta::Color::Role::SVG>

=back

=head1 ATTRIBUTES

=head2 name

The name for the color as a C<ColorLibrary> type.

This can be coerced from a string:

  Intertangle::Taffeta::Color::Named->new( name => 'svg:blue' );

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
