package Math::Gradient;
use strict;
use warnings;

=head1 NAME

Math::Gradient - Perl extension for calculating gradients for colour transitions, etc.

=head1 SYNOPSIS

use Math::Gradient qw(multi_gradient);

# make a 100-point colour pallette to smothly transition between 6 RGB values

my(@hot_spots) = ([ 0, 255, 0 ], [ 255, 255, 0 ], [ 127, 127, 127 ], [ 0, 0, 255 ], [ 127, 0, 0 ], [ 255, 255, 255 ]);

my(@gradient) = multi_array_gradient(100, @hot_spots);

=head1 DESCRIPTION

Math::Gradient is used to calculate smooth transitions between numerical values (also known as a "Gradient"). I wrote this module mainly to mix colours, but it probably has several other applications. Methods are supported to handle both basic and multiple-point gradients, both with scalars and arrays.

=head1 FUNCTIONS

=over 4

=item gradient($start_value, $end_value, $steps)

This function will return an array of evenly distributed values between $start_value and $end_value. All three values supplied should be numeric. $steps should be the number of steps that should occur  between the two points; for instance, gradient(0, 10, 4) would return the array (2, 4, 6, 8); the 4 evenly-distributed steps neccessary to get from 0 to 10, whereas gradient(0, 1, 3) would return (0.25, 0.5, 0.75). This is the basest function in the Math::Gradient module and isn't very exciting, but all of the other functions below derive their work from it.

=item array_gradient($start_value, $end_value, $steps)

While gradient() takes numeric values for $start_value and $end_value, array_gradient() takes arrayrefs instead. The arrays supplied are expected to be lists of numerical values, and all of the arrays should contain the same number of elements. array_gradient() will return a list of arrayrefs signifying the gradient of all values on the lists $start_value and $end_value.

For example, calling array_gradient([ 0, 100, 2 ], [ 100, 50, 70], 3) would return: ([ 25, 87.5, 19 ], [ 50, 75, 36 ], [ 75, 62.5, 53 ]).

=item multi_gradient($steps, @values)

multi_gradient() calculates multiple gradients at once, returning one list that is an even transition between all points, with the values supplied interpolated evenly within the list. If $steps is less than the number of entries in the list @values, items are deleted from @values instead.

For example, calling multi_gradient(10, 0, 100, 50) would return: (0, 25, 50, 75, 100, 90, 80, 70, 60, 50)

=item multi_array_gradient($steps, @values)

multi_array_gradient() is the same as multi_gradient, except that it works on arrayrefs instead of scalars (like array_gradient() is to gradient()).

=back
  
=cut  

use 5.005;
use strict;
use warnings;

require Exporter;

sub gradient ($$$);
sub array_gradient ($$$);
sub multi_array_gradient ($@);
sub multi_gradient ($@);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::Gradient ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	gradient array_gradient multi_gradient multi_array_gradient
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';


# Preloaded methods go here.

# Math::Gradient

# Take sets of numbers and a specified number of steps, and return a
# gradient for going betewen those steps

# for example,

# [ 2, 4, 6 ], [ 4, 8, 12 ], [ 16, 32, 48 ] with 5 steps would result in

# [ 2, 4, 6 ], [ 3, 6, 9 ], [ 4, 8, 12 ], [ 10, 24, 30 ], [ 16, 32, 48 ]

# This involves two distinct steps;
# making a gradient between two points,
# and calculating the gradient between X points.


# To make a gradient between two points, we are given the points,
# and the number of steps to create between them.


# basic_gradient - get start and end number and # of steps to
# create in-between the two. returns an array of the intermediary steps.
sub gradient ($$$)
{
 my($low, $high, $steps) = @_;
 my $xsteps = $steps + 1; # steps incl. low
 my $xdistance = $high - $low; # distance; may be negative
 my $step_value = $xdistance/$xsteps; # how much to add to each step to create a gradient
 my $value = $low; # start off with the starting value
 
 my @values;
 foreach my $step (1 .. $steps)
 {
  $value += $step_value;
  push(@values, $value);
 }
 return(@values); # we have a gradient!
}

# takes two arrayrefs, and # of steps. arrayrefs should have same number
# of values in each.
sub array_gradient ($$$)
{
 my($low, $high, $steps) = @_;
 my(@values);
 my $g_count = scalar(@$low);
 foreach my $x (1 .. scalar(@$low))
 {
  my(@y) = (gradient($low->[$x - 1], $high->[$x - 1], $steps));
  foreach my $y (1 .. scalar(@y))
  {
   $values[$y - 1] ||= [];
   push(@{$values[$y - 1]}, $y[$y - 1]);
  }
 }
 return(@values);
}

# takes a number of steps and any number of steps already filled in (at least two)
# returns the full gradient, including supplied steps

sub multi_array_gradient ($@)
{
 my($steps, @start_steps) = @_;
 if($steps == scalar(@start_steps))
 {
  return(@start_steps); # already have the # of steps we want
 }
 my @values;
 # "steppage" is how many steps we should request on average between
 # steps we've been supplied.
 my $steppage = ($steps - scalar(@start_steps)) / (scalar(@start_steps) - 1);
 my $steps_left = $steps - scalar(@start_steps);
 my $xstep = 0;
 while(my $cstep = shift(@start_steps))
 {
  push(@values, $cstep);
  $xstep += $steppage;
  if(@start_steps && $xstep >= 1)
  {
   my $xxstep = int($xstep);
   $xstep -= $xxstep;
   $steps_left -= $xxstep;
   push(@values, array_gradient($cstep, $start_steps[0], $xxstep));
  }
  elsif(@start_steps && $xstep <= 1)
  {
   my $xxstep = int($xstep);
   $xstep -= $xxstep;
   $steps_left -= $xxstep;
   splice(@values, scalar(@values) + $xxstep, abs($xxstep));
  }
 }
 return(@values);
}

sub multi_gradient ($@)
{
 my($steps, @start_steps) = (@_);
 if($steps == scalar(@start_steps))
 {
  return(@start_steps); # already have the # of steps we want
 }
 my @values;
 # "steppage" is how many steps we should request on average between
 # steps we've been supplied.
 my $steppage = ($steps - scalar(@start_steps)) / (scalar(@start_steps) - 1);
 my $steps_left = $steps - scalar(@start_steps);
 my $xstep = 0;
 while(scalar(@start_steps))
 {
  my $cstep = shift(@start_steps);
  push(@values, $cstep);
  $xstep += $steppage;
  if(@start_steps && $xstep >= 1)
  {
   my $xxstep = int($xstep);
   $xstep -= $xxstep;
   $steps_left -= $xxstep;
   push(@values, gradient($cstep, $start_steps[0], $xxstep));
  }
  elsif(@start_steps && $xstep <= 1)
  {
   my $xxstep = int($xstep);
   $xstep -= $xxstep;
   $steps_left -= $xxstep;
   splice(@values, scalar(@values) + $xxstep, abs($xxstep));
  }
 }
 return(@values);
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!



=head1 AUTHOR

Tyler MacDonald, E<lt>japh@crackerjack.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Tyler MacDonald

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
