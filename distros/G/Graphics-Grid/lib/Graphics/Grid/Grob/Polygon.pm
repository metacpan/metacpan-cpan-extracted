package Graphics::Grid::Grob::Polygon;

# ABSTRACT: Polygon grob

use Graphics::Grid::Class;
use MooseX::HasDefaults::RO;

our $VERSION = '0.0001'; # VERSION

extends qw(Graphics::Grid::Grob::Polyline);

use Graphics::Grid::Unit;
use Graphics::Grid::Types qw(:all);


with qw(
  Graphics::Grid::Positional
);

has '+x' =>
  ( default => sub { Graphics::Grid::Unit->new( [ 0, 0.5, 1, 0.5 ] ) } );

has '+y' =>
  ( default => sub { Graphics::Grid::Unit->new( [ 0.5, 1, 0.5, 0 ] ) } );

method draw($driver) {
    $driver->draw_polygon($self);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob::Polygon - Polygon grob

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Grob::Polygon;
    use Graphics::Grid::GPar;
    my $polygon = Graphics::Grid::Grob::Polygon->new(
            x => [
                ( map { $_ / 10 } ( 0 .. 4 ) ),
                (0.5) x 5,
                ( map { $_ / 10 } reverse( 6 .. 10 ) ),
                (0.5) x 5
            ],
            y => [
                (0.5) x 5,
                ( map { $_ / 10 } reverse( 6 .. 10 ) ),
                (0.5) x 5,
                ( map { $_ / 10 } ( 0 .. 4 ) ),
            ],
            id => [ ( 1 .. 5 ) x 4 ],
            gp => Graphics::Grid::GPar->new(
                fill => [qw(black red green3 blue cyan)],
            )
    );

    # or user the function interface
    use Graphics::Grid::Functions qw(:all);
    my $polygon = polygon_grob(%params);

=head1 DESCRIPTION

This class represents a polygon graphical object. It is a sub class of
L<Graphics::Grid::Grob::Polyline>. The difference is that when a
polyline is drawn, the path is closed and C<fill> in C<gp> can take
effect.

=head1 ATTRIBUTES

=head2 x

A Grahpics::Grid::Unit object specifying x-values.

Default to C<unit([0, 0.5, 1, 0.5], "npc")>.

=head2 y

A Grahpics::Grid::Unit object specifying y-values.

Default to C<unit([0.5, 1, 0.5, 0], "npc")>.

=head2 id

An array ref used to separate locations in x and y into multiple lines. All
locations with the same id belong to the same line.

C<id> needs to have the same length as C<x> and C<y>.

If C<id> is not specified then all points would be regarded as being in one
line.  

=head2 gp

An object of Graphics::Grid::GPar. Default is an empty gpar object.

=head2 vp

A viewport object. When drawing a grob, if the grob has this attribute, the
viewport would be temporily pushed onto the global viewport stack before drawing
takes place, and be poped after drawing. If the grob does not have this attribute
set, it would be drawn on the existing current viewport in the global viewport
stack. 

=head2 elems

Get number of sub-elements in the grob.

Grob classes shall implement a C<_build_elems()> method to support this
attribute.

For this module C<elems> returns the number of polygons. 

=head1 SEE ALSO

L<Graphics::Grid::Functions>

L<Graphics::Grid::Grob>

L<Graphics::Grid::Grob::Polyline>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
