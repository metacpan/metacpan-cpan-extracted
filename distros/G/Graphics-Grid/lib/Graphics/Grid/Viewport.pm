package Graphics::Grid::Viewport;

# ABSTRACT: Viewport

use Graphics::Grid::Class;
use MooseX::HasDefaults::RO;

our $VERSION = '0.0001'; # VERSION

use Types::Standard qw(Num Str ArrayRef HashRef);
use namespace::autoclean;

use Graphics::Grid::Types qw(:all);
use Graphics::Grid::Unit;



my $Scale = ( ArrayRef [Num] )->where( sub { @$_ == 2 } );

has [ "xscale", "yscale" ] => (
    isa     => $Scale,
    default => sub { [ 0, 1 ] },
);


# TODO

#has clip => (
#    isa     => Clip,
#    default => 'inherit',
#);


has angle => ( isa => Num, default => 0 );

#has layout         => ();
#has layout_pos_row => ();
#has layout_pos_col => ();


has name => (
    isa     => Str,
    lazy    => 1,
    builder => '_build_name',
);

has _uid => (
    default => sub {
        state $idx = 0;
        my $name = "GRID.VP.$idx";
        $idx++;
        return $name;
    },
    init_arg => undef
);

with qw(
  Graphics::Grid::Positional
  Graphics::Grid::Dimensional
  Graphics::Grid::Justifiable
  Graphics::Grid::HasGPar
);

sub _build_name { $_[0]->_uid; }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Viewport - Viewport

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Viewport;
    use Graphics::Grid::GPar;
    
    my $vp = Graphics::Grid::Viewport->new(
            x => 0.6, y => 0.6,
            width => 1, height => 1,
            angle => 45,
            gp => Graphics::Grid::GPar->new(col => "red") );

=head1 DESCRIPTION

Viewports describe rectangular regions on a graphics device and define a
number of coordinate systems within those regions.

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

=head2 xscale

A numeric array ref of length two indicating the minimum and maximum on
the x-scale. The limits may not be identical.

Default is C<[0, 1]>.

=head2 yscale

A numeric array ref of length two indicating the minimum and maximum on
the y-scale. The limits may not be identical.

Default is C<[0, 1]>.

=head2 angle

A numeric value indicating the angle of rotation of the viewport. Positive
values indicate the amount of rotation, in degrees, anticlockwise from the
positive x-axis. Default is 0.

=head2 name

A string to uniquely identify the viewport once it has been pushed onto the
viewport tree. If not specified, it would be assigned automatically.

=head1 SEE ALSO

L<Graphics::Grid>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
