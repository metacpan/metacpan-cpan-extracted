package Graphics::Grid::Grob::Circle;

# ABSTRACT: Circle grob

use Graphics::Grid::Class;

our $VERSION = '0.0001'; # VERSION

use List::AllUtils qw(max);

use Graphics::Grid::Unit;
use Graphics::Grid::Types qw(:all);


has r => (
    is      => 'ro',
    isa     => UnitLike,
    coerce  => 1,
    default => sub { Graphics::Grid::Unit->new(0.5) }
);

with qw(
  Graphics::Grid::Grob
  Graphics::Grid::Positional
);

method _build_elems() {
    return max( map { $self->$_->elems } qw(x y r) );
}

method draw($driver) {
    $driver->draw_circle($self);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob::Circle - Circle grob

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Grob::Circle;
    use Graphics::Grid::GPar;
    my $circle = Graphics::Grid::Grob::Circle->new(
            x => 0.5, y => 0.5, r => 0.5,
            gp => Graphics::Grid::GPar->new());

    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $circle = circle_grob(%params);

=head1 DESCRIPTION

This class represents a circle graphical object.

=head1 ATTRIBUTES

=head2 x

A Grahpics::Grid::Unit object specifying x-location.

Default to C<unit(0.5, "npc")>.

=head2 y

A Grahpics::Grid::Unit object specifying y-location.

Default to C<unit(0.5, "npc")>.

The reference point is the left-bottom of parent viewport.

=head2 r

Radius of the circle. Default is 0.5 npc relative to the smaller
one of viewport's width and height.

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

For this module C<elems> returns the number of circles.

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
