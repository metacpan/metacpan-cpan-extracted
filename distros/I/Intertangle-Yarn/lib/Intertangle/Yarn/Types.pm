use Modern::Perl;
package Intertangle::Yarn::Types;
# ABSTRACT: Types for Yarn
$Intertangle::Yarn::Types::VERSION = '0.002';
use Type::Library 0.008 -base,
	-declare => [qw(
		Point
		Vec2
		Size
		AngleDegrees
		Rect
		Matrix
	)];
use Type::Utils -all;
use Types::Standard qw(Tuple Num);
use Types::Common::Numeric qw(PositiveOrZeroNum);

use Intertangle::Yarn::Graphene;

class_type "Point",
	{ class => 'Intertangle::Yarn::Graphene::Point' };

coerce "Point",
	from Tuple[Num, Num],
	via {
		Intertangle::Yarn::Graphene::Point->new(
			x => $_->[0],
			y => $_->[1],
		)
	};

class_type "Vec2",
	{ class => 'Intertangle::Yarn::Graphene::Vec2' };

coerce "Vec2",
	from Tuple[Num, Num],
	via {
		Intertangle::Yarn::Graphene::Vec2->new(
			x => $_->[0],
			y => $_->[1],
		)
	};

class_type "Size",
	{ class => 'Intertangle::Yarn::Graphene::Size' };

coerce "Size",
	from Tuple[PositiveOrZeroNum, PositiveOrZeroNum],
	via {
		Intertangle::Yarn::Graphene::Size->new(
			width  => $_->[0],
			height => $_->[1],
		)
	};

declare "AngleDegrees", parent => Num;

class_type "Rect",
	{ class => 'Intertangle::Yarn::Graphene::Rect' };

class_type "Matrix",
	{ class => 'Intertangle::Yarn::Graphene::Matrix' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Yarn::Types - Types for Yarn

=head1 VERSION

version 0.002

=head1 EXTENDS

=over 4

=item * L<Type::Library>

=back

=head1 TYPES

=head2 Point

A type for any reference that extends L<Intertangle::Yarn::Graphene::Point>

Coercible from a C<Tuple[Num, Num]>.

=head2 Vec2

A type for any reference that extends L<Intertangle::Yarn::Graphene::Vec2>

Coercible from a C<Tuple[Num, Num]>.

=head2 Size

A type for any reference that extends L<Intertangle::Yarn::Graphene::Size>

Coercible from a C<Tuple[PositiveOrZeroNum, PositiveOrZeroNum]>.

=head2 AngleDegrees

A type for an angle in degrees. Aliased to L<Num>.

=head2 Rect

A type for any reference that extends L<Intertangle::Yarn::Graphene::Rect>

=head2 Matrix

A type for any reference that extends L<Intertangle::Yarn::Graphene::Matrix>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
