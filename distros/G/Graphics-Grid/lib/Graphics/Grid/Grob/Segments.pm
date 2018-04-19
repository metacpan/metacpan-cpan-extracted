package Graphics::Grid::Grob::Segments;

# ABSTRACT: Line segments grob

use Graphics::Grid::Class;
use MooseX::HasDefaults::RO;

our $VERSION = '0.0001'; # VERSION

use Types::Standard qw(ArrayRef Int);

use Graphics::Grid::Unit;
use Graphics::Grid::Types qw(:all);


has [qw(x0 y0)] => (
    is      => 'ro',
    isa     => UnitLike,
    coerce  => 1,
    default => sub { Graphics::Grid::Unit->new(0) }
);

has [qw(x1 y1)] => (
    is      => 'ro',
    isa     => UnitLike,
    coerce  => 1,
    default => sub { Graphics::Grid::Unit->new(1) }
);

with qw(Graphics::Grid::Grob);


# TODO
# has arrow => ( isa => ArrayRef[$Arrow] );

method _build_elems() {
    return List::AllUtils::max( map { $self->$_->elems } qw(x0 y0 x1 y1) );
}

method draw($driver) {
    $driver->draw_segments($self);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob::Segments - Line segments grob

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Grob::Segments;
    use Graphics::Grid::GPar;
    my $lines = Graphics::Grid::Grob::Segments->new(
            x0 => 0, y0 => 0,
            x1 => 1, y1 => 1,
            gp => Graphics::Grid::GPar->new()
    );

    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $lines = segments_grob(%params);

=head1 DESCRIPTION

This class represents a "line segments" graphical object. It's a little bit
similar to L<Graphics::Grid::Grob::Polyline> in that a segments grob can
also be implemented by a ployline grob.

=head1 ATTRIBUTES

=head2 x0

A Graphics::Grid::Unit object specifying the starting x-values of the line segments.

=head2 y0

A Graphics::Grid::Unit object specifying the starting y-values of the line segments.

=head2 x1

A Graphics::Grid::Unit object specifying the stopping x-values of the line segments.

=head2 y1

A Graphics::Grid::Unit object specifying the stopping y-values of the line segments.

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
