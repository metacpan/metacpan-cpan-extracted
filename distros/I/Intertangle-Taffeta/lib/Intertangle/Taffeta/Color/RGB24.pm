use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Color::RGB24;
# ABSTRACT: A 24-bit RGB colour
$Intertangle::Taffeta::Color::RGB24::VERSION = '0.001';
use Mu;
use Intertangle::Taffeta::Types qw(RGB24Value RGB24Component);

extends qw(Intertangle::Taffeta::Color);

has value => (
	is => 'ro',
	isa => RGB24Value,
);

around BUILDARGS => fun( $orig, $class, %args ) {
	if( exists $args{r8} && exists $args{g8} && exists $args{b8} ) {
		RGB24Component->assert_valid($args{r8});
		RGB24Component->assert_valid($args{g8});
		RGB24Component->assert_valid($args{b8});

		$args{value} = ( (delete $args{r8}) << 16 )
			+ ( (delete $args{g8}) << 8 )
			+ ( delete $args{b8} );
	}

	return $class->$orig(%args);
};

with qw(Intertangle::Taffeta::Color::Role::SVG Intertangle::Taffeta::Color::Role::RGB24Components);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Color::RGB24 - A 24-bit RGB colour

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

=head2 value

The 24-bit RGB value.

=head1 METHODS

=head2 BUILDARGS

You can pass the values to the constructor as individual C<RGB24Component>s C<r8>, C<g8>, and C<b8>.

  Intertangle::Taffeta::Color::RGB24->new( r8 => 50, g8 => 25, b8 => 0 );

All 3 components must be specified at once.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
