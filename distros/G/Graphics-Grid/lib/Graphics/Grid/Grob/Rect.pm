package Graphics::Grid::Grob::Rect;

# ABSTRACT: Rectangular grob

use Graphics::Grid::Class;
use MooseX::HasDefaults::RO;

our $VERSION = '0.0001'; # VERSION

use List::AllUtils qw(max);


with qw(
  Graphics::Grid::Grob
  Graphics::Grid::Positional
  Graphics::Grid::Dimensional
  Graphics::Grid::Justifiable
);

method _build_elems() {
    return max( map { $self->$_->elems } qw(x y width height) );
}

method draw($driver) {
    $driver->draw_rect($self);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob::Rect - Rectangular grob

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Grob::Rect;
    use Graphics::Grid::GPar;
    my $rect = Graphics::Grid::Grob::Rect->new(
            x => 0.5, y => 0.5, width => 1, height => 1,
            just => "centre",
            gp => Graphics::Grid::GPar->new());

    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $rect = rect_grob(%params);

=head1 DESCRIPTION

This class represents a rectangular graphical object.    

=head1 ATTRIBUTES

=head2 x

A Grahpics::Grid::Unit object specifying x-location.

Default to C<unit(0.5, "npc")>.

=head2 y

A Grahpics::Grid::Unit object specifying y-location.

Default to C<unit(0.5, "npc")>.

The reference point is the left-bottom of parent viewport.

=head2 width

A Grahpics::Grid::Unit object specifying width.

Default to C<unit(1, "npc")>.

=head2 height

Similar to the C<width> attribute except that it is for height. 

=head2 just

The justification of the object, which consumes this role, relative to
its (x, y) location.

The value is an arrayref in the form of C<[$hjust, $vjust]>, where $hjust
and $vjust are two numbers for horizontal and vertical justification
respectively. Each number is usually from 0 to 1, but can also beyond 
hat range. 0 means left alignment and 1 means right alighment.

Default is C<[0.5, 0.5]>, which means the object's center is aligned to
its (x, y) position.

For example, for a rectangle which has $width and $height, and positioned
at ($x, $y), the position of its left-bottom corner can be calculated in
this way,

    $left   = $x - $hjust * $width;
    $bottom = $y - $vjust * $height;

This attribute also supports some string values. They map to numeric values
like below.

    string                          numeric
    ---------------------------     ------------
    left                            [ 0,   0.5 ]
    top                             [ 0.5, 1   ]
    right                           [ 1,   0.5 ]
    bottom                          [ 0.5, 0   ]
    center | centre                 [ 0.5, 0.5 ]
    bottom_left | left_bottom       [ 0,   0   ]
    top_left | left_top             [ 0,   1   ]
    bottom_right | right_bottom     [ 1,   0   ]
    top_right | right_top           [ 1,   1   ]

=head2 hjust

A reader accessor for the horizontal justification.

=head2 vjust

A reader accessor for vertical justification.

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

For this module C<elems> returns the number of rectangles.

=head1 SEE ALSO

L<Graphics::Grid::Functions>

L<Graphics::Grid::Grob>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
