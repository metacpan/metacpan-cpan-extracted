use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Types;
# ABSTRACT: Types for Taffeta
$Intertangle::Taffeta::Types::VERSION = '0.001';
use Type::Library 0.008 -base,
	-declare => [qw(
		CairoContext
		SVG

		ColorLibrary
		RGB24Value
		RGB24Component
		RGBFloatComponentValue
		Color

		Opacity
		Dimension
	)];
use Type::Utils -all;
use Types::Standard qw(Str);
use Types::Common::Numeric qw(PositiveOrZeroInt PositiveOrZeroNum);

use Color::Library;

class_type "CairoContext",
	{ class => 'Cairo::Context' };

class_type "SVG",
	{ class => "SVG::Element" };

class_type "ColorLibrary",
	{ class => 'Color::Library::Color' };

coerce "ColorLibrary",
	from Str, via { Color::Library->color($_) };

declare RGB24Value =>
	as PositiveOrZeroInt,
	where { $_ <= 0xFFFFFF };

declare RGB24Component =>
	as PositiveOrZeroInt,
	where { $_ <= 0xFF };

declare RGBFloatComponentValue =>
	as PositiveOrZeroNum,
	where { $_ <= 1.0 };

class_type "Color",
	{ class => 'Intertangle::Taffeta::Color' };

declare Opacity =>
	as PositiveOrZeroNum,
	where { $_ <= 1.0 };

declare Dimension =>
	as PositiveOrZeroNum;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Types - Types for Taffeta

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Type::Library>

=back

=head1 TYPES

=head2 CairoContext

A type for any reference that extends L<Cairo::Context>.

=head2 SVG

A type for any reference that extends L<SVG::Element>.

=head2 ColorLibrary

A type for any reference that extends L<Color::Library::Color>

Coercible from a C<Str> such as C<svg:blue>.

=head2 RGB24Value

A valid RGB value between C<0> and C<0xFFFFFF>.

=head2 RGB24Component

A valid component of a C<RGB24Value> between C<0> and C<0xFF>.

=head2 RGBFloatComponentValue

A type for a C<Num> that falls in the range for a RGB float component value.

=head2 Color

A type for any reference that extends L<Intertangle::Taffeta::Color>.

=head2 Opacity

A type for a C<Num> that falls in the range for an opacity value.

=head2 Dimension

A type for a C<Num> that can represent a dimension.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
