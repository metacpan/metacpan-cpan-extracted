
# See the POD documentation at the end of this
# document for detailed copyright information.
# (c) 2002-2006 Steffen Mueller, all rights reserved.

package Math::Project3D;

use strict;
use warnings;

use 5.006;

use vars qw/$VERSION/;

$VERSION = 1.02;

use Carp;

use Math::MatrixReal;
use Math::Project3D::Function;

    sub _max {
        my $max = 0;
        for (@_) {
            $max = $_ if $_ > $max;
        }
        $max
    }
    sub _new_from_rows {
        my $class = 'Math::MatrixReal';
        my $rows = shift;
        my @rows;
        foreach (@$rows) {
            push @rows,
              (ref($_) eq 'Math::MatrixReal' ? [@{$_->[0][0]}] : [@{$_}]);
        }
        return bless [
            \@rows,
            scalar(@rows),
            _max(
                map {
                    ref($_) eq 'Math::MatrixReal' ? $_->[2] : scalar(@$_)
                }
                @rows
            ),
            undef,
            undef,
            undef
        ] => $class;
    }

    sub _new_from_cols {
        my $class = 'Math::MatrixReal';
        my $cols = shift;
        my $num_rows = _max(
            map {
                ref($_) eq 'Math::MatrixReal' ? $_->[1] : scalar(@$_)
            }
            @$cols
        );
        my $num_cols = @$cols;
        
        my @rows;
        my $cn = 0;
        foreach (@$cols) {
            my $col = $_;
            if (ref($col) eq 'Math::MatrixReal') {
                $col = $col->[0];
                $rows[$_][$cn] = $col->[$_][0] for 0..$num_rows-1;
            }
            else {
                $rows[$_][$cn] = $col->[$_] for 0..$num_rows-1;
            }
            $cn++;
        }
        return bless [
            \@rows,
            $num_rows,
            $num_cols,
            undef,
            undef,
            undef
        ] => $class;
    }


# class and object method new_function
# 
# Wrapper around Math::Project3D->new()
# Returns compiled function (anon sub)
# As a class method, it does not have side effects.
# As an object method, it assigns the returned function to
# the object's function attribute.

sub new_function {
   @_ > 1 or croak "No arguments supplied to 'new_function' method.";

   my $self = shift;

   my @components = @_;

   my $function = Math::Project3D::Function->new(@components);

   if (ref $self eq __PACKAGE__) {
      $self->{function} = $function;
   }

   return $function;
}


# Class and object method/constructor new
# 
# Arguments are used in the object's anon hash.
# Creates new object.
# Returns MP3D instance.

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   # !!!FIXME!!! Insert argument checking here
   my $self  = {
     function => undef,
     @_
   };

   bless $self => $class;

   # Some attributes are required.
   my $missing_attribute = $self->_require_attributes(qw(
                                   plane_basis_vector
                                   plane_direction1
                                   plane_direction2
                           ));
   croak "Required attribute '$missing_attribute' missing."
     if defined $missing_attribute;

   # Transform the vector/matrix specifications ((nested) array refs)
   # into Math::MatrixReal's.
   foreach ( qw(
        plane_basis_vector
        plane_direction1
        plane_direction2
      ) ) {

      # Argument checking, we either want an array ref or a MMR object.
      croak "Invalid argument '$_' passed to new. Should be an array reference."
        if not exists $self->{$_};
      
      next if ref $self->{$_} eq 'Math::MatrixReal';
      croak "Invalid argument '$_' passed to new. Should be an array reference."
        if ref $self->{$_} ne 'ARRAY';

      # Transform into an MMR object.
      $self->{$_} = $self->_make_matrix($self->{$_});
   }

   # Projection vector defaults to the normal vector of the plane,
   # but may also be specified explicitly as array ref or MMR object.
   if ( defined $self->{projection_vector} and
        ref $self->{projection_vector} eq 'ARRAY' ) {

      $self->{projection_vector} = $self->_make_matrix( $self->{projection_vector} );

   } elsif ( not defined $self->{projection_vector} or
             ref $self->{projection_vector} ne 'Math::MatrixReal' ) {

      # Defaults to the normal of the plane.
      $self->{projection_vector} = $self->{plane_direction1}->vector_product(
                                     $self->{plane_direction2}
                                   );
   }

   # Now generate the linear equation system that has to be solved by
   # MMR in order to do project a point onto the plane.
   # 
   # MMR does all the dirty work. (Thanks!) So we just create a matrix.
   # (d, e be the directional vectors, n the vector we project along,
   #  p the basis point. Let i be the solution)
   # 
   # x(t) + n1*i1 = d1*i2 + e1*i3 + p1
   # y(t) + n2*i1 = d2*i2 + e2*i3 + p2
   # z(t) + n3*i1 = d3*i2 + e3*i3 + p3
   # 
   # This is the intersection of the plane and the corresponding orthogonal
   # line through s(t). Another form:
   # 
   # n1*i1 + d1*i2 + e1*i3 = p1 + x(t)
   # n2*i1 + d2*i2 + e2*i3 = p2 + y(t)
   # n3*i1 + d3*i2 + e3*i3 = p3 + z(t)
   # 
   # linear_eq_system will be the matrix of n,d,e.
   # result_vector will be p+s(t) (later)

   my $linear_eq_system = _new_from_cols(
                         [
                           $self->{projection_vector},
                           $self->{plane_direction1},
                           $self->{plane_direction2},
                         ]
   );

   # Now we do the first step towards solving the equation system.
   # This does not have to be repeated for every projection.
   $self->{lr_matrix} = $linear_eq_system->decompose_LR();

   return $self;
}


# Method project
# 
# Does the projection calculations for a single set of function
# parameters.
# Takes the function parameters as argument.
# Returns undef on failure (plane and P + lambda*projection_vector do
# not intersect!). On success:
# Returns the coefficients of the point on the plane, 
# the distance of the source point from the plane in lengths
# of the projection vector.

sub project {
   my $self  = shift;

   croak "You need to assign a function before projecting it."
     if not defined $self->get_function();

   # Apply function
   my $point = _new_from_cols(
                 [
                   [ $self->{function}->(@_) ],
                 ]
   );

   # Generate result_vector
   my $result_vector = _new_from_cols(
                         [
                           $self->{plane_basis_vector} + $point
                         ]
   );

   # Solve the l_e_s.
   my ($dimension, $p_vector, undef) = $self->{lr_matrix}->solve_LR($result_vector);
   
   # Did we find a solution?
   return undef if not defined $dimension;

   # $dimension == 0 => one solution
   # $dimension == 1 => straight line
   # $dimension == 2 => plane (impossible :) )
   # ...
   # $dimension == 1 is possible (point and projection_vector part
   # of the plane). Hence: !!!FIXME!!!

   return $p_vector->element(2,1), # coefficient 1
          $p_vector->element(3,1), # coefficient 2
          $p_vector->element(1,1); # distance in lengths of the projection vector
}


# Method project_range_callback
# 
# Does the projection calculations for ranges of function parameters.
# Takes an code reference and a number array refs of ranges as argument.
# Ranges are specified using three values:
# [lower_bound, upper_bound, increment].
# Alternatively, one may specify only one element in any of the array
# references. This will then be a static parameter.
# The number of ranges (array references) corresponds to the number of
# parameters to the vectorial function.
# The callback is called for every set of result values with an array
# reference of parameters and the list of the three result values.

sub project_range_callback {
   my  $self     = shift;

   croak "You need to assign a function before projecting it."
     if not defined $self->get_function();

   # Argument checking
   my  $callback = shift;
   ref $callback eq 'CODE' or
     croak "Invalid code reference passed to project_range_callback.";

   my @ranges    = @_;

   croak "Invalid range parameters passed to project_range_callback"
     if grep { ref $_ ne 'ARRAY' } @ranges;


   my $function = $self->get_function();

   # Replace all ranges that consist of a single number with ranges
   # that iterate from that number to itself.
   foreach (@ranges) {
      $_ = [$_->[0], $_->[0], 1] if @$_ == 1;
   }

   # Calculate every range's length and store it in @lengths.
   my @lengths   = map {
                         #      upper  - lower    / increment
                         int( ($_->[1] - $_->[0]) / $_->[2] ),
                       } @ranges;

   # Prepare counters for every range.
   my @counters  = (0) x scalar(@ranges);

   # Calculate the number if iterations needed.
   # It is $_+1 and not $_ because the lengths are the lengths we
   # need for the comparisons inside the long for loop. We save one
   # op in there that way.
   my $iterations = 1;
   $iterations *= ( $_ + 1 ) for @lengths;
   
   # For all possible combinations of parameters...
   for (my $i = 1; $i <= $iterations; $i++) {
      
      # Get current function parameters
      my @params;

      # Get one parameter for every range
      for (my $range_no = 0; $range_no < @ranges; $range_no++) {
         # lower + increment * current_count
         push @params, $ranges[$range_no][0] +
                       $ranges[$range_no][2] * $counters[$range_no];
      }
      
      # Increment outermost range by one. If it got out of bounds,
      # make it 0 and increment the next range, etc.
      my $j = 0;
      while (defined $ranges[$j] and ++$counters[$j] > $lengths[$j]) {
         $counters[$j] = 0;
         $j++;
      }

      # Apply function
      my $point = _new_from_cols(
                    [
                      [ $function->(@params) ],
                    ]
      );

      # Generate result_vector
      my $result_vector = _new_from_cols(
                            [
                              $self->{plane_basis_vector} + $point
                            ]
      );

      # Solve the l_e_s.
      my ($dimension, $p_vector, undef) = $self->{lr_matrix}->solve_LR($result_vector);
   
      # Did we find a solution?
      croak "Could not project $result_vector."
        if not defined $dimension;

      # $dimension == 0 => one solution
      # $dimension == 1 => straight line
      # $dimension == 2 => plane (impossible :) )
      # ...
      # $dimension == 1 is possible (point and projection_vector part
      # of the plane). Hence: !!!FIXME!!!
      
      $callback->(
             $p_vector->element(2,1), # coefficient 1
             $p_vector->element(3,1), # coefficient 2
             $p_vector->element(1,1), # distance in lengths of the projection vector
             $j,                      # how many ranges did we increment?
      );
   }
   
   return();
}


# Method project_list
# 
# Wrapper around project(), therefore slow.
# Takes a list of array refs as argument. The array refs
# are to contain sets of function parameters.
# Calculates every set of parameters' projection and stores the
# three associated values (coefficients and distance coefficient)
# in an n*3 matrix (MMR obj) wheren is the number of points
# projected.
# Currently croaks if any of the points cannot be projected onto
# the plane using the given projection vector. (In R3 -> R2, try
# using the plane's normal vector which is guaranteed not to be
# parallel to the plane.)
# Returns that MMR object.

sub project_list {
   my $self = shift;
   croak "No arguments passed to project_list()."
     if @_ == 0;

   croak "You need to assign a function before projecting it."
     if not defined $self->get_function();

   # Create result matrix to hold individual results.
   my $result_matrix = Math::MatrixReal->new(scalar(@_), 3);

   # Keep track of the matrix row
   my $result_no = 1;

   foreach my $array_ref (@_) {
      my ($coeff1, $coeff2, $dist) = $self->project(@$array_ref);

      croak "Vector $result_no cannot be projected."
        if not defined $coeff1;

      # Assign results
      $result_matrix->assign($result_no, 1, $coeff1);
      $result_matrix->assign($result_no, 2, $coeff2);
      $result_matrix->assign($result_no, 3, $dist);
      $result_no++;
   }

   return $result_matrix;
}


# Accessor get_function
# 
# No parameters.
# Returns the current function code ref.

sub get_function {
   my $self = shift;
   return $self->{function};
}


# Accessor set_function
# 
# Takes a code ref as argument.
# Sets the object's function to that code ref.
# Returns the code ref.

sub set_function {
   my $self     = shift;
   my $function = shift;

   ref $function eq 'CODE' or croak "Argument to set_function must be code reference.";

   $self->{function} = $function;

   return $self->{function};
}


# Private method _require_attributes
# 
# Arguments must be a list of attribute names (strings).
# Tests for the existance of those attributes.
# Returns the missing attribute on failure, undef on success.

sub _require_attributes {
   my $self = shift;
   exists $self->{$_} or return $_ foreach @_;
   return undef;
}


# Private method _make_matrix
# 
# Takes a list of array refs as arguments.
# Creates a Math::MatrixReal object from the arrays.
# Returns the Math::MatrixReal object.

sub _make_matrix {
   my $self = shift;
   @_ or croak "No arguments passed to _make_matrix.";

   my $matrix = Math::MatrixReal->new_from_cols( [ @_ ] );

   return $matrix;
}


# Evil method rotate
# 
# Takes a vector as argument. (Either an MMR object or an array ref
# of an array containing three components.)
# The method will replace the function with a wrapper around the original
# function that rotates the result of the original function by the same
# angles that the z-axis (e3) needs to be turned to become the passed vector.
# Example: Passed [1,0,0] means that e3 will be rotated to become e1.
# Hence all points will be rotated by 90 degrees and orthogonally to e2.
# Returns the wrapper function and the old function as code references.
# 
# Important note: You can apply this function multiple times. That means
# if you rotated the function once, you may do so again and the original
# rotated function will be wrapped again so that you effectively rotate
# it twice. Note, however, that you will sacrifice performance on the
# altar of recursion that way.
# 
# !!!FIXME!!! This is slow. Sloooooow. Conceptually slow, but the
# implementation sucks badly, too. It is especially unnerving to me that
# the whole lexical scope of a myriad of intermediate result matrices and
# vectors is kept because we use closures. Closures are great, but not
# in bloated lexical scopes. How fix that without introducing either
#  - an ugly additional method
#  - ugly additional blocks to keep the scope clean. (Yuck!)

sub rotate {
   my $self = shift;

   croak "You need to assign a function before rotating it."
     if not defined $self->get_function();

   # We want to rotate everything the same way we would
   # have to rotate e3 (z unit vector) to become the unit
   # vector parallel to $e3_.
   my $e3_ = shift;

   # Make sure we work with a MMR vector
   if (ref $e3_ ne 'Math::MatrixReal') {
      croak "Invalid vector passed to rotate()."
        if ref $e3_ ne 'ARRAY';

      $e3_ = _new_from_cols([$e3_]);
   }

   $e3_ *= 1 / $e3_->length();

   my $e3 = _new_from_cols([[0,0,1]]);

   # The axis we want to rotate around
   my $axis = $e3->vector_product($e3_);

   # The angle we want to rotate by.
   my $angle = acos($e3->scalar_product($e3_));

   # Rotationsmatrix um Achse (Vektor) a = (a,b,c):
   #                           [a*a a*b a*c]
   # M(rot) = (1-cos(alpha)) * [a*b b*b b*c]  +
   #                           [a*c b*c c*c]
   #                           [1   0   0  ]
   #          cos(alpha)     * [0   1   0  ]  +
   #                           [0   0   1  ]
   #                           [0   -c  b  ]
   #          sin(alpha)     * [c   0   -a ]
   #                           [-b  a   0  ]
   # (from: Merziger, Wirth: "Repetitorium der Hoeheren Mathematik"
   #        Binomi Verlag. ISBN 3-923923-33-3)

   my ($a, $b, $c) = ($axis->element(1,1), $axis->element(2,1), $axis->element(3,1));

   my $matrix1 = _new_from_cols(
      [
        [$a*$a, $a*$b, $a*$c],
        [$b*$a, $b*$b, $b*$c],
        [$c*$a, $c*$b, $c*$c],
      ],
   );

   my $matrix2 = Math::MatrixReal->new_diag([1,1,1]);

   my $matrix3 = _new_from_cols(
      [
        [0,   -$c, $b ],
        [$c,  0,   -$a],
        [-$b, $a,  0  ],
      ],
   );

   # What a painful birth, but here we are:
   my $rot_matrix = (1-cos($angle)) * $matrix1 + cos($angle) * $matrix2 +
                    sin($angle)     * $matrix3;

   # For (Rotated vector r=(r1,r2,r3), source vector x=(x1,x2,x3)):
   # (eq1) r = $rot_matrix * x
   # Hence:
   # (eq2) x = transposed($rot_matrix) * r
   # 
   # x and $rot_matrix (and therefore also transposed($rot_matrix)
   # are know. Hance, (eq2) can be solved as a linear equation system
   # of the form: ($rot_matrix be all elements a(ij))
   # 
   # a11*r1 + a12*r2 + a13*r3 = x1
   # a21*r1 + a22*r2 + a23*r3 = x2
   # a31*r1 + a32*r2 + a33*r3 = x3

   # Transpose the rotation matrix and then decompose_LR
   $rot_matrix->transpose($rot_matrix);
   $rot_matrix = $rot_matrix->decompose_LR();

   # Save old function
   my $old_function = $self->get_function;

   my $rotator = sub {

      # If the first argument is 'restore', we restore the old
      # function from the lexical $old_function and return.
      # This is needed for the unrotate() method.
      $self->{function} = $old_function, return if $_[0] eq 'restore';

      # We apply the old function as usual.
      my $source_vec = _new_from_cols(
         [ [ $old_function->(@_) ] ],
      );

      # But then we rotate the results.
      my ($dimension, $result_vector, undef) = $rot_matrix->solve_LR($source_vec);

      # There should be a solution to the equation system.
      croak "Dimension of rotation result is '$dimension' but should be 0."
        if $dimension;

      # return the rotated vector
      return (
        $result_vector->element(1,1),
        $result_vector->element(2,1),
        $result_vector->element(3,1),
      );
   };
   
   # Set the new function wrapper to become the actual function
   # that will be used for projection calculations.
   $self->set_function($rotator);

   # The level of nested rotation has been increased.
   $self->{rotated}++;

   return ($rotator, $old_function);
}


# method unrotate
# 
# Removes the evil hack of rotation using an evil hack.
# Takes an optional integer as argument. Removes
# [integer] levels of rotation. 'Level of rotation'
# means: one rotation wrapper of the original function
# as wrapped using rotate().
# If no integer was passed, defaults to the total number
# of rotations that were made, effectively removing
# any rotation.
# Returns the number of wrappers (rotations) removed.

sub unrotate {
   my $self = shift;

   croak "You need to assign a function before rotating it."
     if not defined $self->get_function();

   # How many levels of rotation to we want to remove?
   my $level = shift;

   # Boundary checking for the level. Default to the number
   # of rotation wrappers.
   if (not defined $level or $level <= 0 or $level > $self->{rotated}) {
      $level = $self->{rotated};
   }

   $level = int $level; # I don't trust users.

   # If we're rotated at all.
   if ($self->{rotated}) {

      # Count the number of wrappers removed.
      my $no_unrotated = 0;

      # While we still want to unrotate and while we still can
      while ($level != 0 and $self->{rotated} != 0) {

         # Let the function restore its parent.
         $self->{function}->('restore');

         $self->{rotated}--;
         $level--;
         $no_unrotated++;
      }

      return $no_unrotated;

   } else {
      # We aren't even rotated.
      return 0;

   }
}


# Function acos (arc cosine)
# Not a method.
sub acos { atan2( sqrt( 1 - $_[0] * $_[0] ), $_[0] ) }

1;

__END__

=pod

=head1 NAME

Math::Project3D - Project functions of multiple parameters
from R^3 onto an arbitrary plane

=head1 SYNOPSIS

  use Math::Project3D;
  
  my $projection = Math::Project3D->new(
    plane_basis_vector => [0,  0, 0],
    plane_direction1   => [.4, 1, 0],
    plane_direction2   => [.4, 0, 1],
    projection_vector  => [1,  1, 1], # defaults to normal of the plane
  );

  $projection->new_function(
    'u,v', 'sin($u)', 'cos($v)', '$u' 
  );

  # Rotate the points before projecting them.
  # Rotate every point the same way we need to rotate the
  # z-axis to get the x-axis.
  $projection->rotate([1,0,0]);

  # Nah, changed my mind
  $projection->unrotate();

  ($plane_coeff1, $plane_coeff2, $distance_coeff) =
     $projection->project( $u, $v );

=head1 BACKGROUND

I'll start explaining what this module does with some background. Feel
free to skip to L<DESCRIPTION> if you don't feel like vector geometry.

Given a function of three components and of an arbitrary number of
parameters, plus a few vectors, this module creates a projection of
individual points on this vectorial function onto an arbitrary plane
in three dimensions.

The module does this by creating lines from the result of the vectorial
function s(a) = x,y,z and a specified projection vector (which defaults
to the normal vector of the projection plane. The normal vector is defined
as being orthogonal to both directional vectors of the plane or as the
vector product of the two.). Then, using the linear equation solver of
Math::MatrixReal, it calculates the intersection of the line and the plane.

This point of intersection can be expressed as

  basis point of the plane + i2 * d + i3 * e

where i2/i3 are the coefficients that are the solution we got from
solving the linear equation system and d1/d2 are the directional
vectors of the plane. Basically, the equation system looks like this:

   n1*i1 + d1*i2 + e1*i3 = p1 + x(t)
   n2*i1 + d2*i2 + e2*i3 = p2 + y(t)
   n3*i1 + d3*i2 + e3*i3 = p3 + z(t)

where n1/2/3 are the normal vector components. p1/2/3 the basis point
components, t is a vector of function parameters. i the solution.

Now, on the plane, you can express the projected point in terms of
the directional vectors and the calculated coefficients.

=head1 DESCRIPTION

=head2 Methods

=over 4

=item new

C<new> may be used as a class or object method. In the current
implementation both have the same effect.

C<new> returns a new Math::Project3D object. You need to pass a
number of arguments as a list of key/value pairs:

  plane_basis_vector => [0,  0, 0],
  plane_directional1 => [.4, 1, 0],
  plane_directional2 => [.4, 0, 1],
  projection_vector  => [1,  1, 1], # defaults to normal of the plane
  
plane_basis vector denotes the position of the basis point of the plane
you want to project onto. Vectors are generally passed as array references
that contain the components. Another way to pass vectors would be to pass
Math::MatrixReal objects instead of the array references.
plane_directional1 and plane_directional2 are the vectors that span the
plane. Hence, the projection plane has the form:

  s = plane_basis_vector + coeff1 * plane_dir1 + coeff2 * plane_dir2

The last vector you need to specify at creation time is the vector along
which you want to project the function points onto the plane. You may,
however, omit its specification because it defaults to teh cross-product
of the plane's directional vectors. Hence, all points are orthogonally
projected onto the plane.

=item new_function

This method may be used as a class or object method. It does not have
side effects as a clas method, but as an object method, its results
are applied to the projection object.

new_function returns an anonymous subroutine compiled from component
functions which you need to specify.

For a quick synopsis, you may look at L<Math::Project3D::Function>.

You may pass a list of component functions that are included in the
compiled vectorial functions in the order they were passed. There are
two possible ways to specify a component function. Either you pass
an subroutine reference which is called with the list of parameters,
or you pass a string containing a valid Perl expression which is then
evaluated. You may mix the two syntaxes at will.

If any one of the component functions is specified as a string,
the first argument to new_function I<must> be a string of parameter
names separated by commas. These parameter names will then be made
availlable to the string component functions as the respective
scalar variables. (eg. 't,u' will mean that the parameters availlable
to the string expressions are $t and $u.)

Due to some black magic in Math::Project3D::Function, the string
expression syntax may actually be I<slightly> faster at run-time
because it saves sub routine calls which are slow in Perl.
Generally speaking, you should just choose whichever syntax you
like because benchmarks show that the difference is very small.
(Which is a mystery to me, really.) Arguably, the closure syntax
is more powerful because closures, have access to variables
I<outside> the scope of the resulting vectorial function. For
a simple-minded example, you may have a look at the synopsis in
L<Math::Project3D::Function>. Picture a dynamic radius, etc.

=item get_function

get_function returns the object's current vectorial function.

=item set_function

set_function is the counterpart of get_function.

=item project

The project method can be used to do the projection calculations for
one point of the vectorial function. It expects a list of function
parameters as argument.

On failure (eg. the projection vector is parallel to the plane.),
the method returns undef.

On success, the method returns the coefficients of the projected
point on the plane as well as the distance of the source point from
the plane in lengths of the projection vector. (May be negative for
points "behind" the plane.)

=item project_list

project_list is a wrapper around project and therefore rather slow
because it is doing a lot of extra work.

project_list takes a list of array references as arguments. The
referenced arrays are to contain sets of function parameters.
The method the calculates every set of parameters' projection and
stores the three results (coefficients on the plane and distance
coefficient) in an n*3 matrix (as an MMR object, n is the number of
points projected). The matrix is returned.

Currently, the method croaks if any of the points cannot be
projected onto the plane using the given projection vector.
The normal vector of the plane used as the projection vector should
guarantee valid results for any points.

=item project_range_callback

For projection of a large number of points, this method will probably
be the best bet. Its first argument has to be a callback function that
will be called with the calculated coefficients for every projected point.
The callback's arguments will be the following: The two coefficients for
the unit vectors on the projection plane, the coefficient for the
projection vector (a measure for the point's distance from the plane),
and (new in v1.010) an integer that will be different from 0 whenever
a parameter other than the one corresponding to the innermost range
(the first one) is incremented.

All arguments thereafter have to be array references. Every one of
these referenced arrays represents the range of one parameter.
These arrays may either contain one number, which is then treated as a
static parameter, or three numbers of the form:

  [ lower boundary, upper boundary, increment ]

For example, [-1, 1, 0.8] would yield the parameter values
-1, -0.2, 0.6. You may also reverse upper and lower boundary,
given you increment by a negative value: [1, -1, -0.8] yields the
same parameter values but in reversed order. Example:

  $projection->project_range_callback(
    sub {...}, # Do some work with the results
    [ 1, 2,  .5],
    [ 2, 1,  .5],
    [ 0, 10, 4 ],
  );

Will result in the coefficients for the following parameter
sets being calculated:

1,2,0 1.5,2,0 2,2,0 1,1.5,0 1.5,1.5,0 2,1.5,0 1,1,0 1.5,1,0 2,1,0
1,2,4 etc.

croaks if a point cannot be projected. (projection vector parallel
to the plane but not I<in> the plane.)

=item rotate

Takes a vector as argument. (Either an MMR object or an array ref
of an array containing three components.)

The method will replace the function with a wrapper around the original
function that rotates the result of the original function by the same
angles that the z-axis (e3) needs to be turned to become the passed vector.
Example: Passed [1,0,0] means that e3 will be rotated to become e1.
Hence all points will be rotated by 90 degrees and orthogonally to e2.
Returns the wrapper function and the old function as code references.

You can apply this function multiple times. That means
if you rotated the function once, you may do so again and the original
rotated function will be wrapped again so that you effectively rotate
it twice. Note, however, that you will sacrifice performance on the
altar of recursion that way.

=item unrotate

Removes the evil hack of rotation using an evil hack.
Takes an optional integer as argument. Removes
[integer] levels of rotation. 'Level of rotation'
means: one rotation wrapper of the original function
as wrapped using rotate().

If no integer was passed, defaults to the total number
of rotations that were made, effectively removing
any rotation.

Returns the number of wrappers (rotations) removed.

=item acos

For convenience, there is an I<acos> arc cosine function (not method).
Don't use it outside of the module. Use L<Math::Trig> instead.

=back

=head1 CAVEAT

Math::Project3D is pretty slow. Why? Because Perl is. This kind of algebra
should be done in C, but I'm not going to rewrite all of this
(and Math::MatrixReal) in C.

As of version 1.02, I'm using a semi-clever hack that breaks the encapsulation
of Math::MatrixReal in a way. I'm doing that because the new_from_*
constructors of Math::MatrixReal are written in a way that would accept
bananas and make matrices out of them. In plain english, that means they
jump through a lot of hoops to accept the weirdest input. By skipping these
steps, we get a 2-fold speed-up. Right. Math::Project3D spent way more than
50% of its cycles in the Math::MatrixReal constructors.

Now, the caveat really is that a future version of Math::MatrixReal B<might>
break this. I'll release a new version of Math::Project3D in case that happens.

=head1 AUTHOR

Steffen Mueller, mail at steffen-mueller dot net

=head1 COPYRIGHT

Copyright (c) 2002-2006 Steffen Mueller. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Math::MatrixReal>

L<Math::Project3D::Function>

=cut
