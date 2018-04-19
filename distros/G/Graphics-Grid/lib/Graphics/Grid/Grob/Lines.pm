package Graphics::Grid::Grob::Lines;

# ABSTRACT: Lines grob

use Graphics::Grid::Class;
use MooseX::HasDefaults::RO;

our $VERSION = '0.0001'; # VERSION

extends qw(Graphics::Grid::Grob::Polyline);

use Types::Standard qw(ArrayRef Int);

use Graphics::Grid::Unit;
use Graphics::Grid::Types qw(:all);


# disable "id" attr
has '+id' => ( is => 'ro', init_arg => undef );

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob::Lines - Lines grob

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Grob::Lines;
    my $lines = Graphics::Grid::Grob::Lines->new(
            x => [ 0, 0.5, 1, 0.5 ],
            y => [ 0.5, 1, 0.5, 0 ],
            gp => Graphics::Grid::GPar->new()
    );

    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $lines = lines_grob(%params);

=head1 DESCRIPTION

This class represents a "lines" graphical object. It is a subclass of
L<Graphics::Grid::Grob::Polyline>. The difference is that this class
assumes all points are for the same line. 

=head1 ATTRIBUTES

=head2 x

A Grahpics::Grid::Unit object specifying x-values.

Default to C<unit([0, 1], "npc")>.

=head2 y

A Grahpics::Grid::Unit object specifying y-values.

Default to C<unit([0, 1], "npc")>.

C<x> and C<y> combines to define the points in the lines. C<x> and C<y> shall
have same length. For example, the default values of C<x> and C<y> defines
a line from point (0, 0) to (1, 1). If they have less than two elements, it
is surely not enough to make a line and nothing would be drawn.

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

For this module C<elems> always returns 1.

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
