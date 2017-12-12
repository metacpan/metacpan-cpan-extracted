package Math::VectorXYZ;

our $VERSION = '1.01';

use 5.006;
use strict;
use warnings;

use Carp;
use Math::Trig;

use Exporter 'import';
our @EXPORT = ('Vec');

use overload (
    '+' => 'vec_add',
    '-' => 'vec_subtract',
    '*' => 'vec_scalar_mult',
    '/' => 'vec_scalar_div',
    'x' => 'vec_cross',
    '.' => 'vec_dot',

    '=='  => 'vec_equality',
    'eq'  => 'vec_equality',
    q/""/ => 'as_string',
);

#-------------- Additional methods available beyond overloaded operators above are: -----------------
#
#   $vec->mag                Returns vector magnitude (scalar)
#   $vec->uvec               Returns a new unit vector in same direction
#   $vec->proj( $vec2 )      Returns the projection of $vec onto $vec2 (scalar)
#   $vec->angle( $vec2 )     Returns the angle between two vectors (scalar)
#
#----------------------------------------------------------------------------------------------------



#----------------------------------------- object constructors ---------------------------------------
#
# Instructions: Provide a list of three numbers (x,y,z) to the constructor
#
#----------------------------------------------------------------------------------------------------

sub new {

    my $class = shift;
    
    if ( @_ != 3 ) {
        croak '*** Error; syntax is "$vec = VectorXYZ->new(x,y,z)" ***';
    }

    return bless [ @_ ], $class;
}

sub Vec {

    if ( @_ != 3 ) {
        croak '*** Error; syntax is "$vec = Vec(x,y,z)" ***';
    }

    return bless [ @_ ], __PACKAGE__;
}


#----------------------------------------------------------------------------------------------------
#-------------------------------------- vector subs returning a vector ------------------------------
#----------------------------------------------------------------------------------------------------

sub vec_add {
    my ($a, $b) = @_;
    return bless [ $a->[0] + $b->[0],  $a->[1] + $b->[1],  $a->[2] + $b->[2] ], ref($a);
}

sub vec_subtract {
    my ($a, $b) = @_;
    return bless [ $a->[0] - $b->[0],  $a->[1] - $b->[1],  $a->[2] - $b->[2] ], ref($a);
}

sub vec_scalar_mult { # vec_a, const
    my ($a, $b, $swap) = @_; 
    
    #Note: overload ('*' => 'vec_scalar_mult') magically swaps the arguments $vec * const --or-- const * $vec
    #so that the vector object is always the first argument "$a"
    return bless [ $a->[0]*$b,  $a->[1]*$b,  $a->[2]*$b ], ref($a);
}

sub vec_scalar_div { # vec_a, const
    my ($a, $b, $swap) = @_; 
    
    #Note: overload ('/' => 'vec_scalar_div') magically swaps the arguments $vec / const --or-- const / $vec
    #so that the vector object is always the first argument "$a".
    return bless [ $a->[0] / $b,  $a->[1] / $b,  $a->[2] / $b ], ref($a);
}

sub vec_cross { # a x b per "Advanced Engineering Mathematics", Kreyszig, 7th ed.

    my ($a, $b) = @_;

    my $res = [ 
        
        $a->[1]*$b->[2] - $a->[2]*$b->[1], #i

        $a->[2]*$b->[0] - $a->[0]*$b->[2], #j

        $a->[0]*$b->[1] - $a->[1]*$b->[0], #k
        
    ];

    return bless $res; #cross product result is always 3d, so don't bless into ref($a)
}

sub uvec {
    my $self = shift;
    my $u_vec = ( $self / mag($self) );
    return bless $u_vec, ref($self);
}


#----------------------------------------------------------------------------------------------------
#-------------------------------------- vector subs returning a scalar ------------------------------
#----------------------------------------------------------------------------------------------------
sub vec_dot {
    my ($a, $b) = @_;
    return $a->[0]*$b->[0] + $a->[1]*$b->[1] + $a->[2]*$b->[2]; #scalar value
}

sub mag {
    my $self = shift;
    return sqrt($self.$self);
}

sub proj {
    my ($self, $b) = @_;

    unless ( $b->isa(__PACKAGE__) ) {
        croak "Argument is not a vector object";
    }

    my $p = ($self.$b) / mag($b);
    return $p;
}

sub angle {
    my ($self, $b) = @_;

    unless ( $b->isa(__PACKAGE__) ) {
        croak "Argument is not a vector object";
    }

    my $cos_theta = ($self.$b) / ( mag($self) * mag($b) );
    my $theta = acos($cos_theta);
    return rad2deg($theta);
}

my $tol = 1e-5; #floating point equality tolerance for testing
sub vec_equality {
    my ($a, $b) = @_;

    if (abs($a->[0] - $b->[0]) < $tol and
        abs($a->[1] - $b->[1]) < $tol and
        abs($a->[2] - $b->[2]) < $tol) 
        { return 1 }

    else
        { return 0 }
}

sub as_string {
    my $self = shift;
    return "<" . join(",", @$self) . ">"; # <x,y,z>
}

1;

__END__

=pod

=head1 NAME

Math::VectorXYZ - Basic 3d vector operations

=head1 SYNOPSIS

The following vector operations are provided:

B<Create a vector>

    use Math::VectorXYZ;

    my $v1 = Vec(1,2,3);
    my $v2 = Math::VectorXYZ->new(4,5,6);

B<Add, subtract, multiply, and divide>

    my $v_add = $v1 + $v2;
    my $v_sub = $v1 - $v2;

    my $v_mul = 7 * $v1 or $v1 * 7;
    my $v_div = $v1 / 7;

B<Dot product, cross product, printing, etc>

    my $v_dot = $v1.$v2;
    my $v_cross = $v1 x $v2;
    my $unit_vec = $v1->uvec;

    my $magnitude = $v1->mag;
    my $projection = $v1->proj( $v2 );
    my $angle = $v1->angle( $v2 );

    print $v1;

=head1 EXPORT

The C<Vec()> function is exported by default for easy vector creation.

=head1 DESCRIPTION

This module is designed for 3d vector math common to engineering
problems such as manipulating finite element data (forces and geometry),
calculating moments or perpendicular vectors using cross products, etc.

The API is intended to be minimal and intuitive using common perl
operators where possible.

Note: See L<Math::VectorXYZ::2D> if working with 2D vectors

=head2 Vector Creation

New vectors are created using either the C<Vec()> function or the object
oriented interface as:

    my $v1 = Vec(1,2,3);

    my $v2 = Math::VectorXYZ->new(4,5,6);

=head2 Vector Internals

The resulting vector object is an array reference C<$v1 = [x,y,z]>
blessed into the VectorXYZ class.  Individual components of the 
vector object may be accessed or changed directly as:

    $x = $v1->[0];
    $y = $v1->[1];
    $z = $v1->[2];

=head2 Vector Operations

=head3 Overload methods

Most of the vector math functionality is available via common perl
(overloaded) operators:

    '+' => 'vec_add',
    '-' => 'vec_subtract',
    '*' => 'vec_scalar_mult',
    '/' => 'vec_scalar_div',
    'x' => 'vec_cross',
    '.' => 'vec_dot',

Note: The perl overloading logic also provides related
operators C<+=, -=, *=, /=> from these.

=head3 Object methods

Additional methods available to be called on the object are:

=head4 Vector result

    $v1->uvec             Returns a new unit vector from $v1

=head4 Scalar result

    $v1->mag              Returns vector magnitude
    $v1->proj( $v2 )      Returns the projection of $v1 onto $v2
    $v1->angle( $v2 )     Returns the angle (deg) between vectors

    print $v1             Returns string output of vector as "<x,y,z>"

=head1 CAVEATS

The code provides minimal input validation:

=over 4

=item * Number of arguments == 3 for vector constructors

=item * Arguments to 'proj' and 'angle' methods are vector objects

=back

Note: Invalid inputs will cause the program to either die, or
throw errors or warnings according to default perl behavior for
division by zero, non-numeric data types, etc.

=head1 AUTHOR

Ryan Matthew, C<< <rmatthew at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-vectorxyz at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-VectorXYZ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::VectorXYZ


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-VectorXYZ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-VectorXYZ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-VectorXYZ>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-VectorXYZ/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ryan Matthew.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
