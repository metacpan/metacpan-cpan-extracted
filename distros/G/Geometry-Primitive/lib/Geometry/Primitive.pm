package Geometry::Primitive;
use strict;
use warnings;

our $VERSION = '0.24';
our $AUTHORITY = 'cpan:GPHAT';

1;
__END__
=head1 NAME

Geometry::Primitive - Primitive Geometry Entities

=head1 SYNOPSIS

Geometry::Primitive is a device and library agnostic system for representing
geometric entities such as points, lines and shapes.  It provides simple
objects and many convenience methods you would expect from a simple geometry
library.

    use Geometry::Primitive::Point;

    my $foo = Geometry::Primitive::Point->new(x => 1, y => 3);
    ...

=head1 DISCLAIMER

I'm not a math guy. I hate math. I will likely learn a lot in the process
of making this library. If you are a math person you will probably look at
this and find many things missing or wrong. Patches are B<encouraged>. I will
likely find that I've done something completely wrong having taken geometry
over 10 years ago.  C'est la vie.

=head1 ENTITIES

=over 4

=item L<Arc|Geometry::Primitive::Arc>

=item L<Bezier|Geometry::Primitive::Bezier>

=item L<Circle|Geometry::Primitive::Circle>

=item L<Ellipse|Geometry::Primitive::Ellipse>

=item L<Line|Geometry::Primitive::Line>

=item L<Point|Geometry::Primitive::Point>

=item L<Polygon|Geometry::Primitive::Polygon>

=item L<Rectangle|Geometry::Primitive::Rectangle>

=back

=head1 SERIALIZATON

All of the entities in this library support serialization via
L<MooseX::Storage>.  This is primarily to support serialization in consumers
of this library, but may be useful for other purposes.  All classes are set
to JSON format and File IO.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Many of the ideas here come from my experience using the Cairo library.

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
