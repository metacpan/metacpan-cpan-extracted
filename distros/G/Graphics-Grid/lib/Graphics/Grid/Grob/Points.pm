package Graphics::Grid::Grob::Points;

# ABSTRACT: Points grob

use Graphics::Grid::Class;
use MooseX::HasDefaults::RO;

our $VERSION = '0.0001'; # VERSION

use Graphics::Grid::Unit;
use Graphics::Grid::Types qw(:all);



has pch => ( isa => PlottingCharacter, default => 1 );


has size => (
    isa     => Unit,
    coerce  => 1,
    default => sub { Graphics::Grid::Unit->new( 1, "char" ) },
);


with qw(
  Graphics::Grid::Grob
  Graphics::Grid::Positional
);

has '+x' => (
    default => sub {
        [ map { rand() } ( 0 .. 9 ) ]
    }
);
has '+y' => (
    default => sub {
        [ map { rand() } ( 0 .. 9 ) ]
    }
);

method _build_elems() {
    return $self->x->elems;
}

method validate() {
    unless (
        List::AllUtils::all { $self->$_->isa('Graphics::Grid::Unit') }
        qw(x y size)
      )
    {
        die "'x', 'y' and 'size' must be units";
    }

    my $x_size = $self->x->elems;
    my $y_size = $self->y->elems;
    unless ( $x_size == $y_size ) {
        die "'x' and 'y' must be 'unit' objects and have the same length";
    }
}

method draw($driver) {
    $driver->draw_points($self);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob::Points - Points grob

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Grob::Points;
    use Graphics::Grid::GPar;
    my $points = Graphics::Grid::Grob::Points->new(
        x => [ map { rand() } (0 .. 9) ],
        y => [ map { rand() } (0 .. 9) ],
        pch => "A",
        gp => Graphics::Grid::GPar->new());
    
    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $points = points_grob(%params);

=head1 DESCRIPTION

This class represents a "points" graphical object.

=head1 ATTRIBUTES

=head2 x

A Grahpics::Grid::Unit object specifying x-values.

Default to an array ref of 10 numbers from C<rand()>.

=head2 y

A Grahpics::Grid::Unit object specifying y-values.

Default to an array ref of 10 numbers from C<rand()>.

C<x> and C<y> combines to define the points. C<x> and C<y> shall have same
length, which is the number of points in the grob object. 

=head2 pch

Plotting character. A single value to indicate what sort of
plotting symbol to use.  See points for the interpretation of these values.

=head2

Graphics::Grid::Unit object specifying the size of the plotting symbols.  
Default to C<unit(1, "char")>.

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

For this module C<elems> returns the number of points.

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
