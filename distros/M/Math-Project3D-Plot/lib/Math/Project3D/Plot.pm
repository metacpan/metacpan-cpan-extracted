
# See the POD documentation at the end of this
# document for detailed copyright information.
# (c) 2002-2006 Steffen Mueller, all rights reserved.

package Math::Project3D::Plot;

use 5.006;
use strict;
use warnings;

use Carp;

use Math::Project3D;
use Imager;

use vars qw/$VERSION/;
$VERSION = '1.02';


# Constructor class and object method new
# 
# Creates a new Math::Project3D::Plot instance and returns it.
# Takes a list of object attributes as arguments.

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my %args = @_;

   # check for require attributes
   my $missing = _require_attributes(\%args, 'image', 'projection');

   croak "Required attribute $missing missing."
     if $missing;
   
   # We might croak a lot.
   my $croaker = sub { croak "Attribute '$_[0]' is bad." };

   my $self = {};

   # valid image and projection?
   ref $args{image} or $croaker->('image');
   $self->{image} = $args{image};

   ref $args{projection} eq 'Math::Project3D' or $croaker->('projection');
   $self->{proj} = $args{projection};

   # defaults
   $self = {
     %$self,
     scale    => 10,
     origin_x => $self->{image}->getwidth() / 2,
     origin_y => $self->{image}->getheight() / 2,
   };

   my @valid_args = qw(
     origin_x origin_y
     scale
   );

   # Take all valid args from the user input and
   # put them into our object.
   foreach my $arg (@valid_args) {
      $self->{$arg} = $args{$arg} if exists $args{$arg};
   }

   bless $self => $class;

   # get min/max logical x/y coordinates
   ( $self->{min_x}, $self->{min_y} ) = $self->_g_l(0, 0);
   ( $self->{max_x}, $self->{max_y} ) = $self->_g_l(
                                          $self->{image}->getwidth(),
                                          $self->{image}->getheight(),
                                        );

   return $self;
}


# Method plot
# Takes argument pairs: color => Imager color
# and params => array ref of params
# projects the point associated with the parameters.
# Plots the point.
# Returns the graphical coordinates of the point that
# was plotted.

sub plot {
   my $self   = shift;
   my %args   = @_;

   ref $args{params} eq 'ARRAY' or
     croak "Invalid parameters passed to plot().";

   my ($coeff1, $coeff2, $distance) = $self->{proj}->project(@{$args{params}});
   my ($g_x, $g_y) = $self->_l_g($coeff1, $coeff2);

   $self->{image}->setpixel(color=>$args{color}, x=>$g_x, y=>$g_y);

   return $g_x, $g_y;
}


# Method plot_list
# Takes argument pairs: color => Imager color,
# params => array ref of array ref of params
# and type => 'line' or 'points'
# Projects the points associated with the parameters.
# Plots the either points or the line connecting them.
# Returns 1.

sub plot_list {
   my $self   = shift;
   my %args   = @_;

   ref $args{params} eq 'ARRAY' or
     croak "Invalid parameters passed to plot_list().";

   # Get type, default to points
   my $type = $args{type};
   $type ||= 'points';

   # Do some calulation on the points.
   my $matrix = $self->{proj}->project_list( @{ $args{params} } );

   # Cache
   my ($prev_g_x, $prev_g_y);

   # For every point...
   for ( my $row = 1; $row <= @{$args{params}}; $row++ ) {

      # Get its coordinates
      my ($g_x, $g_y) = $self->_l_g(
                            $matrix->element($row,1),
                            $matrix->element($row,2)
                          );

      # Plot line or points?
      if ( $type eq 'line' ) {

         $self->{image}->line(
           color => $args{color},
           x1 => $prev_g_x, y1 => $prev_g_y,
           x2 => $g_x,      y2 => $g_y,
         ) if defined $prev_g_x;

         ($prev_g_x, $prev_g_y) = ($g_x, $g_y);

      } else {
         $self->{image}->setpixel(color=>$args{color}, x=>$g_x, y=>$g_y);
      }
   }

   return 1;
}


# Method plot_range
# Takes argument pairs: color => Imager color,
# params => array ref of array ref of ranges
# and type => 'line' or 'points'
# Projects the points associated with the parameter ranges.
# Plots the either points or the line connecting them.
# Returns 1.

sub plot_range {
   my $self   = shift;
   my %args   = @_;

   ref $args{params} eq 'ARRAY' or
     croak "Invalid parameters passed to plot_range().";

   # Get type, default to points
   my $type = $args{type};
   $type ||= 'points';

   # Cache
   my ($prev_g_x, $prev_g_y);

   # This will hold the callback routine
   my $callback;

   # Use different callbacks for different drawing types
   if ($type eq 'line') {
      $callback = sub {
         # Get its coordinates
         my ($g_x, $g_y) = $self->_l_g( @_[0,1] );

         # Draw the line
         $self->{image}->line(
           color => $args{color},
           x1 => $prev_g_x, y1 => $prev_g_y,
           x2 => $g_x,      y2 => $g_y,
         ) if defined $prev_g_x;

         # cache
         ($prev_g_x, $prev_g_y) = ($g_x, $g_y);
      };
   } elsif ($type eq 'multiline') {
      $callback = sub {
         my $newline = $_[3]; # Did we start a new line?

         # Get its coordinates
         my ($g_x, $g_y) = $self->_l_g( @_[0,1] );

         # Draw the line if not a new line:
         $self->{image}->line(
           color => $args{color},
           x1 => $prev_g_x, y1 => $prev_g_y,
           x2 => $g_x,      y2 => $g_y,
         ) if defined $prev_g_x;

         # cache
         ($prev_g_x, $prev_g_y) = ($g_x, $g_y);
         ($prev_g_x, $prev_g_y) = (undef, undef) if $newline;
      };
   } else {
      $callback = sub {
         # Get its coordinates
         my ($g_x, $g_y) = $self->_l_g( @_[0,1] );

         # draw the point
         $self->{image}->setpixel(color=>$args{color}, x=>$g_x, y=>$g_y);
      };
   }

   # Start the projection
   $self->{proj}->project_range_callback(
     $callback,
     @{ $args{params} },
   );

   return 1;
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


# Private method _l_g (logical to graphical)
# Takes an x/y pair of logical coordinates as
# argument and returns the corresponding graphical
# coordinates.

sub _l_g {
   my $self = shift;
   my $x    = shift;
   my $y    = shift;

   # A logical unit is a graphical one displaced by the origin
   # and multiplied with the appropriate scaling factor.

   $x = $self->{origin_x} + $x * $self->{scale};

   $y = $self->{origin_y} - $y * $self->{scale};

   return $x, $y;
}


# Private method _g_l (graphical to logical)
# Takes an x/y pair of graphical coordinates as
# argument and returns the corresponding
# logical coordinates.

sub _g_l {
   my $self = shift;
   my $x = shift;
   my $y = shift;

   # A graphical unit is a logical one displaced by the origin
   # and divided by the appropriate scaling factor.

   $x = ( $x - $self->{origin_x} ) / $self->{scale};

   $y = ( $y - $self->{origin_y} ) / $self->{scale};

   return $x, $y;
}


# Method plot_axis
#
# The plot_axis method draws an axis into the image. "Axis" used
# as in "a line that goes through the origin". Required arguments:
#  color  => Imager color to use (see Imager::Color manpage)
#  vector => Array ref containing three vector components.
#            (only the direction matters as the vector will
#            be normalized by plot_axis.)
#  length => Desired axis length.

sub plot_axis {
   my $self = shift;
   my %args = @_;

   ref $args{vector} eq 'ARRAY' or
     croak "Invalid vector passed to plot_axis().";

   # Save original function
   my $old_function = $self->{proj}->get_function();

   # Directional vector of the axis
   my @vector = @{ $args{vector} };

   # Create new function along the axis' directional vector
   # using only one parameter t that will be determined
   # below
   $self->{proj}->new_function(
      't', "$vector[0]*\$t", "$vector[1]*\$t", "$vector[2]*\$t",
   );

   # Calculate the length of the unit vector
   my $vector_length = sqrt( $vector[0]**2 + $vector[1]**2 + $vector[2]**2 );

   # Calculate $t, the number of units needed to get
   # a line of the correct length.
   my $t = $args{length} / ( 2 * $vector_length );

   # Use the plot_list method to display the axis.
   $self->plot_list(
     color  => $args{color},
     type   => 'line',
     params => [
                 [-$t], # We calculated for $t for length/2, hence
                 [$t],  # we may now draw from -$t to +$t
               ],
   );

   # Restore original function
   $self->{proj}->set_function($old_function);

   return 1;
}


1;

__END__

=pod

=head1 NAME

Math::Project3D::Plot - Perl extension for plotting projections of 3D functions

=head1 SYNOPSIS

  use Math::Project3D::Plot;

  # Create new image or open an existing one
  my $img = Imager->new(...);

  # Create new projection
  my $projection = Math::Project3D->new(
    # see Math::Project3D manpage!
  );

  my $plotter = Math::Project3D::Plot->new(
    image      => $img,
    projection => $projection,

    # 1 logical unit => 10 pixels
    scale      => 10,

    # x/y coordinates of the origin in pixels
    origin_x   => $img->getwidth()  / 2,
    origin_y   => $img->getheight() / 2,
  );

  $plotter->plot_axis(
    color  => $color,    # see Imager manpage about colors
    vector => [1, 0, 0], # That's the x-axis
    length => 100,
  );

  $plotter->plot(
    params   => [@parameters],
    color    => $color, # see Imager manpage about colors
  );

  $plotter->plot_list(
    params => [
                [@parameter_set1],
                [@parameter_set2],
                # ...
              ],
    color  => $color, # see Imager manpage about colors
    type   => 'line', # connect points with lines
                      # other option: 'points'
  );

  $plotter->plot_range(
    params => [
                [$lower_boundary1, $upper_boundary1, $increment1],
                [$lower_boundary2, $upper_boundary2, $increment2],
                # ...
              ],
    color  => $color,   # see Imager manpage about colors
    type   => 'points', # draw the points only 
                        # other options: 'line' and 'multiline'
  );

  # Use Imager methods on $img to save the image to a file

=head1 DESCRIPTION

This module may be used to plot the results of a projection
from a three dimensional vectorial function onto a plane into
an image. What a horrible sentence.

=head2 Methods

=over 4

=item new

new is the constructor for Math::Project3D::Plot objects.
Using the specified arguments, it creates a new instance
of Math::Project3D::Plot. Parameters are passed as a list
of key value pairs. Valid parameters are:

  required:
  image      => Imager object to draw into
  projection => Math::Project3D object to get projected
                points from

  optional:
  scale      => how many pixels per logical unit
                (defaults to 10)
  origin_x   => graphical x coordinate of the origin
  origin_y   => graphical y coordinate of the origin
                (default to half the width/height of the
                image)  

=item plot

The plot method plots the projected point associated
with the function parameters passed to the method.
Takes its arguments as key/value pairs. The following
parameters are valid (and required):

=over 2

=item color

Imager color to use (see Imager::Color manpage)

=item params

Array reference containing a list of function parameters

=back

In addition to plotting the point, the method returns the
graphical coordinates of the point.

=item plot_list

The plot_list method plots all projected points associated
with the sets of function parameters passed to the method.
Takes its arguments as key/value pairs. The following
parameters are valid:

=over 2

=item color

Imager color to use (see Imager::Color manpage)

=item params

Array reference containing any number of array
references containing sets of function parameters

=item type

May be either 'line' or 'points' (connect points or not)
(defaults to 'points').

=back

=item plot_range

The plot_range method plots all projected points associated
with the function parameter ranges passed to the method.
Takes its arguments as key/value pairs. The following
parameters are valid:

=over 2

=item color

Imager color to use (see Imager::Color manpage)

=item params

Array reference containing an array reference
for every function parameter. These inner array
references are to contain one or three items:
one: static parameter
three: lower boundary, upper boundary, increment

=item type

May be either 'line' or 'points'
(connect points or not) (defaults to 'points').

I<New in v1.010:> type 'multiline' that works similar
to 'line', but does not connect points whenever
a parameter other than the innermost one is
incremented. This is usually the desired method
whenever you are plotting functions of multiple
parameters and are experiencing odd lines connecting
different parts of the function. 'multiline' is only
a valid type for 'plot_range', not for the other plotting methods.

=back

=item plot_axis

The plot_axis method draws an axis into the image. "Axis" used
as in "a line that goes through the origin". Required arguments:

  color  => Imager color to use (see Imager::Color manpage)
  vector => Array ref containing three vector components.
            (only the direction matters as the vector will
            be normalized by plot_axis.)
  length => Desired axis length.

=back

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2006 Steffen Mueller. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Imager>, L<Math::Project3D>, L<Math::Project3D::Function>,
L<Math::MatrixReal>

=cut
