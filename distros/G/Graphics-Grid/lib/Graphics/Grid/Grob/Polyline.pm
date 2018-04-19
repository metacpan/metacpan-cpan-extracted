package Graphics::Grid::Grob::Polyline;

# ABSTRACT: Polyline grob

use Graphics::Grid::Class;
use MooseX::HasDefaults::RO;

our $VERSION = '0.0001'; # VERSION

use List::AllUtils qw(uniq);
use Types::Standard qw(ArrayRef Int);

use Graphics::Grid::Unit;
use Graphics::Grid::Types qw(:all);


has id => ( isa => ArrayRef [Int] );

# TODO
# has arrow => ( isa => ArrayRef[$Arrow] );

has _indexes_by_id => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build__indexes_by_id',
    init_arg => undef
);

has _ids => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build__ids',
    init_arg => undef,
);

with qw(
  Graphics::Grid::Grob
  Graphics::Grid::Positional
);

has [qw(+x +y)] => (
    coerce  => 1,
    default => sub { Graphics::Grid::Unit->new( [ 0, 1 ] ) }
);


method _build_elems() {
    return scalar( @{ $self->_ids } );
}

method _build__ids() {
    if ( !$self->has_id ) {
        return [0];
    }
    else {
        my @ids = uniq( @{ $self->id } );
        return \@ids;
    }
}

method _build__indexes_by_id() {
    if ( !$self->has_id ) {
        return { 0 => [ 0 .. $self->x->elems - 1 ] };
    }
    else {
        my %indexes_by_id = map { $_ => [] } @{ $self->id };
        for my $idx ( 0 .. $#{ $self->id } ) {
            my $id = $self->id->[$idx];
            push @{ $indexes_by_id{$id} }, $idx;
        }
        return \%indexes_by_id;
    }
}


method indexes_by_id($id) {
    return $self->_indexes_by_id->{$id};
}


method unique_ids() {
    return $self->_ids;
}

method get_idx_by_id($id) {
    my @indexes = map { $_ == $id } @{ $self->id };
    return \@indexes;
}

method _has_param($name) {
    my $val = $self->$name;
    return ( defined $val and @{$val} > 0 );
}

for my $name (qw(id arrow)) {
    no strict 'refs';    ## no critic
    *{ "has_" . $name } = sub { $_[0]->_has_param($name); }
}

method validate() {
    my $x_size = $self->x->elems;
    my $y_size = $self->y->elems;
    unless ( $x_size == $y_size ) {
        die "'x' and 'y' must have the same length";
    }
    if ( $self->has_id and $x_size != scalar( @{ $self->id } ) ) {
        die "'x', 'y' and 'id' must have the same length";
    }
}

method draw($driver) {
    $driver->draw_polyline($self);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob::Polyline - Polyline grob

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Grob::Polyline;
    use Graphics::Grid::GPar;
    my $polyline = Graphics::Grid::Grob::Polyline->new(
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
                col => [qw(black red green3 blue cyan)],
                lwd => 3,
            )
    );

    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $polyline = polyline_grob(%params);

=head1 DESCRIPTION

This class represents a polyline graphical object.

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

For this module C<elems> returns the number of lines (number of unique
C<id>) of a object.

=head1 METHODS

=head2 indexes_by_id($id)

Get unit indexes of attributes C<x>, C<y>, C<id>, for a given id.

Returns an array ref.

=head2 unique_ids

Return an array ref of unique ids.

=head1 CONSTRUCTOR

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
