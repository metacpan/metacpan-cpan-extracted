# 
# This file is part of Games-RailRoad
# 
# This software is copyright (c) 2008 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
use 5.010;
use strict;
use warnings;

package Games::RailRoad::Vector;
BEGIN {
  $Games::RailRoad::Vector::VERSION = '1.101330';
}
# ABSTRACT: an opaque vector class.

use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;
use Readonly;

use overload
    '='   => \&copy,
    '+'   => \&_add,
    '-'   => \&_substract,
    'neg' => \&_invert,
    '+='  => \&_add_inplace,
    '-='  => \&_substract_inplace,
    '<=>' => \&_compare,
    '""'  => \&as_string;



# -- attributes


has posx => ( rw, isa=>'Int', default=>0 );
has posy => ( rw, isa=>'Int', default=>0 );


# -- private vars

Readonly my %coords2dir => (
    '(-1,-1)' => 'nw',
    '(-1,0)'  => 'w',
    '(-1,1)'  => 'sw',
    '(0,-1)'  => 'n',
    '(0,1)'   => 's',
    '(1,-1)'  => 'ne',
    '(1,0)'   => 'e',
    '(1,1)'   => 'se',
);
Readonly my %dir2coords => (
    'nw' => [-1,-1],
    'w'  => [-1, 0],
    'sw' => [-1, 1],
    'n'  => [ 0,-1],
    's'  => [ 0, 1],
    'ne' => [ 1,-1],
    'e'  => [ 1, 0],
    'se' => [ 1, 1],
);


# -- constructors & initializers


# provided by moose



sub new_dir {
    my ($pkg, $dir) = @_;
    my ($x, $y) = @{ $dir2coords{$dir} };
    return $pkg->new( { posx=>$x, posy=>$y } );
}



sub copy {
    my $vec = shift;
    return bless {%$vec}, ref $vec;
}


# -- PUBLIC METHODS

#- accessors

#
# my $str = $vec->as_string;
# my $str = "$vec";
#
# Return the stringified form of $vec. For instance, a vector might look
# like "(1,2)".
#
sub as_string {
    my $self = shift;
    return '(' . $self->posx . ',' . $self->posy . ')';
}


#
# my $str = $vec->as_dir;
#
# Return the cardinal direction (n, sw, etc.) of $vec if it's a unit
# vector (ok, (1,1) is not a unit vector but you see my point).
#
sub as_dir {
    my $self = shift;
    return $coords2dir{"$self"};
}


# -- PRIVATE METHODS

#- math ops

#
# my $vec = $v1->_add($v2);
# my $vec = $v1 + $v2;
#
# Return a new GRV object, which is the result of $v1 plus $v2.
#
sub _add {
    my ($v1, $v2) = @_;
    my $rv = ref($v1)->new;
    $rv->set_posx( $v1->posx + $v2->posx );
    $rv->set_posy( $v1->posy + $v2->posy );
    return $rv;
}


#
# my $vec = $v1->_substract($v2);
# my $vec = $v1 - $v2;
#
# Return a new GRV object, which is the result of $v1 minus $v2.
#
sub _substract {
    my ($v1, $v2) = @_;
    my $rv = ref($v1)->new;
    $rv->set_posx( $v1->posx - $v2->posx );
    $rv->set_posy( $v1->posy - $v2->posy );
    return $rv;
}


 
#
# my $v2 = $v1->_invert;
# my $v2 = -$v1;
#
# Subtract $v1 from the origin. Effectively, gives the inverse of the
# original vector. The new vector is the same distance from the origin,
# in the opposite direction.
#
sub _invert {
    my ($v1) = @_;
    my $rv = ref($v1)->new;
    $rv->set_posx( - $v1->posx );
    $rv->set_posy( - $v1->posy );
    return $rv;
}


#- inplace math ops

#
# $v1->_add_inplace($v2);
# $v1 += $v2;
#
#
sub _add_inplace {
    my ($v1, $v2) = @_;
    $v1->set_posx( $v1->posx + $v2->posx );
    $v1->set_posy( $v1->posy + $v2->posy );
    return $v1;
}


#
# $v1->_substract_inplace($v2);
# $v1 -= $v2;
#
# Substract $v2 to $v1, and stores the result back into $v1.
#
sub _substract_inplace {
    my ($v1, $v2) = @_;
    $v1->set_posx( $v1->posx - $v2->posx );
    $v1->set_posy( $v1->posy - $v2->posy );
    return $v1;
}


#- comparison

#
# my $bool = $v1->_compare($v2);
# my $bool = $v1 <=> $v2;
#
# Check whether the vectors both point at the same spot. Return 0 if they
# do, 1 if they don't.
#
sub _compare {
    my ($v1, $v2) = @_;
    return 1 if $v1->posx != $v2->posx;
    return 1 if $v1->posy != $v2->posy;
    return 0;
}


1;


=pod

=head1 NAME

Games::RailRoad::Vector - an opaque vector class.

=head1 VERSION

version 1.101330

=head1 SYNOPSIS

    my $v1 = Games::RailRoad::Vector->new( \%params );

=head1 DESCRIPTION

This class abstracts basic vector manipulation. It lets you pass around
one argument to your functions, do vector arithmetic and various string
representation.

=head1 ATTRIBUTES

=head2 posx

The x coordinate of the vector. Default to 0.

=head2 posy

The y coordinate of the vector. Default to 0.

=head1 METHODS

=head2 my $vec = GR::Vector->new( \%params );

Create and return a new vector. Accept a hash reference with the
attribute values.

=head2 my $vec = GR::Vector->new_dir( $dir );

Create a new vector, from a given direction. The recognized directions
are C<e>, C<n>, C<ne>, C<nw>, C<s>, C<se>, C<sw>, C<w>.

=head2 my $vec = $v->copy;

Return a new GRV object, which has the same coordinates as C<$v>.

=head1 PUBLIC METHODS

=head2 my $str = $vec->as_string;

Return the stringified form of C<$vec>. For instance, a Befunge vector
might look like C<(1,2)>.

This method is also applied to stringification, ie when one forces
string context (C<"$vec">).

=head2 my $str = $vec->as_dir;

Return the cardinal direction (n, sw, etc.) of $vec if it's a unit
vector (ok, (1,1) is not a unit vector but you see my point).

=head1 MATHEMATICAL OPERATIONS

=head2 Standard operations

One can do some maths on the vectors. Addition and substraction work as
expected:

    my $v = $v1 + $v2;
    my $v = $v1 - $v2;

Either operation return a new GRV object, which is the result of C<$v1>
plus / minus C<$v2>.

The inversion is also supported:
    my $v2 = -$v1;

will subtracts C<$v1> from the origin, and effectively, gives the
inverse of the original vector. The new vector is the same distance from
the origin, in the opposite direction.

=head2 Inplace operations

GRV objects also supports inplace mathematical operations:

    $v1 += $v2;
    $v1 -= $v2;

effectively adds / substracts C<$v2> to / from C<$v1>, and stores the
result back into C<$v1>.

=head2 Comparison

Finally, GRV objects can be tested for equality, ie whether two vectors
both point at the same spot.

    print "same"   if $v1 == $v2;
    print "differ" if $v1 != $v2;

=head1 AUTHOR

  Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


