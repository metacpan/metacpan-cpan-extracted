package Graphics::Grid::Grob::Text;

# ABSTRACT: Text grob

use Graphics::Grid::Class;
use MooseX::HasDefaults::RO;

our $VERSION = '0.0001'; # VERSION

use Types::Standard qw(Str ArrayRef Bool Num);

use Graphics::Grid::Types qw(:all);
use Graphics::Grid::Unit;


has label => (
    isa      => ( ArrayRef [Str] )->plus_coercions(ArrayRefFromValue),
    coerce   => 1,
    required => 1,
);


has rot => (
    isa => ( ArrayRef [Num] )->plus_coercions(ArrayRefFromValue),
    coerce => 1,
    default => sub { [0] },
);

#has check_overlap => ( is => 'ro', isa => Bool, default => 0 );


with qw(
  Graphics::Grid::Grob
  Graphics::Grid::Positional
  Graphics::Grid::Justifiable
);

method _build_elems() {
    return scalar( @{ $self->label } );
}

method draw($driver) {
    $driver->draw_text($self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob::Text - Text grob

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Grob::Text;
    use Graphics::Grid::GPar;
    my $text = Graphics::Grid::Grob::Text->new(
            label => "SOMETHING NICE AND BIG",
            x => 0.5, y => 0.5, rot => 45,
            gp => Graphics::Grid::GPar->new(fontsize => 20, col => "grey"));

    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $text = text_grob(%params);

=head1 DESCRIPTION

This class represents a text graphical object.

=head1 ATTRIBUTES

=head2 label

A single string or an array ref of strings. If a an array ref of strings is
specified, these multiple strings will be drawn.

=head2 x

A Grahpics::Grid::Unit object specifying x-location.

Default to C<unit(0.5, "npc")>.

=head2 y

A Grahpics::Grid::Unit object specifying y-location.

Default to C<unit(0.5, "npc")>.

The reference point is the left-bottom of parent viewport.

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

=head2 rot

The angle to rotate the text.

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

For this module C<elems> returns the number of texts in C<label>.

=head1 SEE ALSO

L<Graphics::Grid::Grob>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
