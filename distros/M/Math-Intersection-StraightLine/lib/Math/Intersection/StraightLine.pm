package Math::Intersection::StraightLine;

# ABSTRACT: Calculate intersection point for two lines

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.05';

sub new{
  my ($class) = @_;
  my $self = {};
  bless $self,$class;
  return $self;
}# new

sub functions{
  my ($self,$f_one,$f_two) = @_;
  my $factor   = 3;
  my $line_one = [
                   [0,$f_one->[1]],
                   [$factor,($f_one->[0] * $factor) + $f_one->[1]],
                 ];
  my $line_two = [
                   [0,$f_two->[1]],
                   [$factor,($f_two->[0] * $factor) + $f_two->[1]],
                 ];
  return $self->points($line_one,$line_two);
}# function

sub vectors{
  my ($self,$vector_one,$vector_two) = @_;
  my @equation_one = ($vector_one->[0]->[0],$vector_one->[1]->[0],
                      $vector_two->[0]->[0],$vector_two->[1]->[0],);
  my @equation_two = ($vector_one->[0]->[1],$vector_one->[1]->[1],
                      $vector_two->[0]->[1],$vector_two->[1]->[1],);
  my $factor_one   = $vector_two->[1]->[1];
  my $factor_two   = $vector_two->[1]->[0];
    
  for(@equation_one){
    $_ *= $factor_one;
  }
  
  for(@equation_two){
    $_ *= $factor_two;
  }
  
  my @result_equation;
  for(0..3){
    push(@result_equation,$equation_one[$_] - $equation_two[$_]);
  }
  
  my $point = undef;
    
  if($result_equation[1] != 0){
    my $constant = $result_equation[2] - $result_equation[0];
    my $lambda   = $constant / $result_equation[1];
  
    $point       = [$vector_one->[0]->[0] + ($vector_one->[1]->[0] * $lambda),
                    $vector_one->[0]->[1] + ($vector_one->[1]->[1] * $lambda),];
  }
  if(_check_parallel_vectors($vector_one,$vector_two)){
    if(defined _check_point_on_vector($vector_one,$vector_two->[0])){
      $point = -1;
    }
    else{
      $point = 0;
    }
  }
  return $point;
}# vectors

sub point_limited{
  my ($self,$line_one,$line_two) = @_;
  my @coords_one = @$line_one;
  my @coords_two = @$line_two;
  my $vector_one = [$coords_one[0],[$coords_one[0]->[0] - $coords_one[1]->[0],
                                    $coords_one[0]->[1] - $coords_one[1]->[1]]];
  my $vector_two = [$coords_two[0],[$coords_two[0]->[0] - $coords_two[1]->[0],
                                    $coords_two[0]->[1] - $coords_two[1]->[1]]];
  my $result = $self->vectors($vector_one,$vector_two);
  my $return = 0;
  if(defined $result && ref($result) eq 'ARRAY' &&
     _check_point_on_line($vector_one,$result) && 
     _check_point_on_line($vector_two,$result)){
    $return = $result;
  }
  if(_check_overlapping_lines($line_one,$line_two,$vector_one,$vector_two)){
    $return = -1;
  }
  return $return;
}# point_limited


sub points{
  my ($self,$line_one,$line_two) = @_;
  my @coords_one = @$line_one;
  my @coords_two = @$line_two;
  my $vector_one = [$coords_one[0],[$coords_one[0]->[0] - $coords_one[1]->[0],
                                    $coords_one[0]->[1] - $coords_one[1]->[1]]];
  my $vector_two = [$coords_two[0],[$coords_two[0]->[0] - $coords_two[1]->[0],
                                    $coords_two[0]->[1] - $coords_two[1]->[1]]];
  my $result = $self->vectors($vector_one,$vector_two);
  my $return = 0;
  if(defined $result && ref($result) eq 'ARRAY'){
    $return = $result;
  }
  if(_check_overlapping_lines($line_one,$line_two,$vector_one,$vector_two)){
    $return = -1;
  }
  return $return;
}# points

sub _check_point_on_line{
  my ($vector,$point) = @_;
  my $return    = 1;
  
  my $check = _check_point_on_vector($vector,$point);
  if(!defined $check || $check > 0 || $check < -1){
    $return = 0;
  }

  return $return;
}# _check_point_on_line

sub _check_overlapping_lines{
  my ($line_one,$line_two,$vector_one,$vector_two) = @_;
  my $return = 0;
  if(_check_point_on_line($vector_one,$line_two->[0]) ||
        _check_point_on_line($vector_one,$line_two->[1]) ||
        _check_point_on_line($vector_two,$line_one->[0]) ||
        _check_point_on_line($vector_two,$line_one->[1])){
    $return = 1;
  }
  return $return;
}# _check_overlapping_lines

sub _check_parallel_vectors{
  my ($vector_one,$vector_two) = @_;
  my $return = 0;
  for(0,1){
    if(($vector_one->[1]->[0] == 0 && $vector_two->[1]->[0] == 0) ||
       ($vector_one->[1]->[1] == 0 && $vector_two->[1]->[1] == 0)){
      $return = 1;
    }
    else{
      unless($vector_two->[1]->[0] == 0 || $vector_two->[1]->[1] == 0){
        my $quot_one = $vector_one->[1]->[0] / $vector_two->[1]->[0];
        my $quot_two = $vector_one->[1]->[1] / $vector_two->[1]->[1];
        if($quot_one == $quot_two){
          $return = 1;
        }
      }
    }
  }
  return $return;
}# _check_parallel_vectors

sub _check_point_on_vector{
  my ($vector,$point) = @_;
  my $return          = undef;
  my $tmp_check       = undef;
  for(0,1){
    if($vector->[1]->[$_] == 0 && ($point->[$_] != $vector->[0]->[$_])){
      $return = 0;
      last;
    }
    elsif($vector->[1]->[$_] != 0){
      my $check = ($point->[$_] - $vector->[0]->[$_]) / $vector->[1]->[$_];
      unless(defined $tmp_check){
        $tmp_check = $check;
      }
      elsif(abs($tmp_check - $check) > 0.00001){
        $return = 0;
      }
    }
  }
  if(defined $return && $return == 0){
    $return = undef;
  }
  elsif(! defined $return){
    $return = $tmp_check;
  }
  return $return;
}# _check_point_on_vector

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Intersection::StraightLine - Calculate intersection point for two lines

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use Math::Intersection::StraightLine;
  use Data::Dumper;
  my $finder = Math::Intersection::StraightLine->new();

  # one intersection point
  my $vector_a = [[20,60],[-40,0]];
  my $vector_b = [[50,80],[0,50]];
  my $result = $finder->vectors($vector_a,$vector_b);
  print Dumper($result);

  # no intersection point
  my $point_a = [[20,60],[30,10]];
  my $point_b = [[50,80],[50,75]];
  $result = $finder->point_limited($point_a,$point_b);
  print Dumper($result);

=head1 DESCRIPTION

This module calculates the intersection point of two straight lines (if one
exists). It returns 0, if no intersection point exists. If the lines have an
intersection point, the coordinates of the point are the returnvalue. If the
given lines have infinite intersection points, -1 is returned.
Math::Intersection::StraightLine can handle four types of input:

=head2 functions

Often straight lines are given in functions of that sort: y = 9x + 3

=head2 vectors

the vector assignment of the line

  (10)     +     lambda(30)
  (20)                 (50)

=head2 points

The straight lines are described with two vectors to points on the line

  X1 = (10)             X2 = (40)
       (20)                  (70)

=head2 point_limited

If the module should test, if an intersection point of two parts exists

  X1 = (10)             X2 = (40)
       (20)                  (70)

The following example should clarify the difference between C<points> and
C<point_limited>:

  $line_a = [[20,60],[30,10]];
  $line_b = [[50,80],[50,75]];
  $result = $finder->points($line_a,$line_b);

  $line_a_part = [[20,60],[30,10]];
  $line_b_part = [[50,80],[50,75]];
  $result = $finder->point_limited($line_a_part,$line_b_part);

The first example returns the intersection point 50/-90, the second returns
0 because C<$line_a_part> is just a part of C<$line_a> and has no intersection
point with the part of line b.

In the first example, the lines are changed to the vectors of the lines.

=head1 EXAMPLES

  $vector_a = [[20,60],[30,10]];
  $vector_b = [[50,80],[60,30]];
  $result = $finder->point_limited($vector_a,$vector_b);
  ok($result == 0,'parallel lines(diagonal)');

  $vector_a = [[20,60],[20,10]];
  $vector_b = [[60,80],[20,10]];
  $result = $finder->vectors($vector_a,$vector_b);
  ok($result == -1,'overlapping vectors');

  $vector_a = [[20,60],[30,10]];
  $vector_b = [[50,80],[50,75]];
  $result = $finder->points($vector_a,$vector_b);
  ok($result->[0] == 50 && $result->[1] == -90,'Lines with one intersection point');

  # test y=9x+5 and y=-3x-2
  my $function_one = [9,5];
  my $function_two = [-3,-2];
  $result = $finder->functions($function_one,$function_two);

=head1 MISC

Note! The coordinates for the intersection point can be imprecise!

  # test y=9x+5 and y=-3x-2
  my $function_one = [9,5];
  my $function_two = [-3,-2];
  $result = $finder->functions($function_one,$function_two);

returns

  $VAR1 = [
          '-0.583333333333333', # this is imprecise
          '-0.25'
          ];

=head1 OTHER METHODS

=head2 new

returns a new object of C<Math::Intersection::StraightLine>

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
