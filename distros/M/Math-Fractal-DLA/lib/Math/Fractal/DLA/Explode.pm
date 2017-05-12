package Math::Fractal::DLA::Explode;

use Math::Fractal::DLA qw(:all);
use strict;
use warnings;
use Exporter;
use GD;

our @ISA = qw(Math::Fractal::DLA Exporter);

our @EXPORT_OK = qw();
our @EXPORT = qw();

our $VERSION = 0.21;

sub new
{
  my $param = shift;
  my $class = ref($param) || $param;
  my $self = new Math::Fractal::DLA;
  $self->{TYPE} = "Explode";
  bless ($self,$class);
  return $self;
} # new

sub generate
{
  my $self = $_[0];
  
  # Set the starting point in the matrix
  # if the value is not available it'll be set to the middle of the image
  if (($self->{START}->[0]) && ($self->{START}->[1]))
  {
    $self->{MATRIX}->[$self->{START}->[0]][$self->{START}->[1]] = 1;
  }
  else
  {
	$self->{START}->[0] = int($self->{IMG_WIDTH} / 2);
	$self->{START}->[1] = int($self->{IMG_HEIGHT} / 2);
	$self->{MATRIX}->[$self->{START}->[0]][$self->{START}->[1]] = 1;
  }
  
  $self->addLogMessage("Fractal mode ".$self->{TYPE});
    
  my $setpoints = 0;
  my $points = $self->{POINTS};
  my $color_interval = int($points / $self->{COLORS});
  my $color_value = 0;
  my $newpoint = 1;
  my $width = $self->{IMG_WIDTH}; my $height = $self->{IMG_HEIGHT};
  my $x_min = 0; my $x_max = $width; my $y_min = 0; my $y_max = $height;
  if (${$self->{START}}[0] - 2 > 0) { $x_min = ${$self->{START}}[0] - 2; }
  if (${$self->{START}}[0] + 2 < $width) { $x_max = $x_max = ${$self->{START}}[0] + 2; }
  if (${$self->{START}}[1] - 2 > 0) { $y_min = $y_min = ${$self->{START}}[1] - 2; }
  if (${$self->{START}}[1] + 2 < $height) { $y_max = ${$self->{START}}[1] + 2; }
  $self->addLogMessage("Starting point: ".${$self->{START}}[0]." ".${$self->{START}}[1]);
  my $rand_width = $x_max - $x_min;
  my $rand_height = $y_max - $y_min;
  my $direction = -1;
  my $steps = 500;

  $self->addLogMessage("Starting area:");
  $self->addLogMessage("min X: ".$x_min." max X: ".$x_max);
  $self->addLogMessage("min Y: ".$y_min." max Y: ".$y_max);

  while ($setpoints < $points)
  {
    if ((($setpoints % $color_interval) == 0) && ($newpoint == 1))
    { $color_value ++; $self->addLogMessage("New color $color_value after $setpoints points"); }
    $newpoint = 0;
    $rand_width = $x_max - $x_min;
    $rand_height = $y_max - $y_min;
    my $x = 0; my $y = 0;

    $direction++;
    if ($direction == 4) { $direction = 0; }
    if ($direction == 0)
    { $x = $x_min + sprintf("%.0f",rand($rand_width)); $y = $y_min; $steps = $rand_height; }
    elsif ($direction == 1)
    { $y = $y_min + sprintf("%.0f",rand($rand_height)); $x = $x_max; $steps = $rand_width; }      
    elsif ($direction == 2)
    { $x = $x_min + sprintf("%.0f",rand($rand_width)); $y = $y_max; $steps = $rand_height; }
    elsif ($direction == 3)
    { $y = $y_min + sprintf("%.0f",rand($rand_height)); $x = $x_min; $steps = $rand_width; }
    if ($self->{MATRIX}->[$x][$y] > 0) { $setpoints ++; next; }

    for (my $i = 0; $i < $steps; $i ++)
    {
      if (($self->{MATRIX}->[$x-1][$y] > 0) || 
          ($self->{MATRIX}->[$x+1][$y] > 0) ||
	  ($self->{MATRIX}->[$x][$y-1] > 0) ||
          ($self->{MATRIX}->[$x][$y+1] > 0))
      {
	    $self->{MATRIX}->[$x][$y] = $color_value;
	    $setpoints ++;
	    $newpoint = 1;
	    last;
      }
      else
      {
	    if    (($direction == 0) && ($y_max > ($y + 1))) { $y = $y + 1; }
	    elsif ($direction == 1) { $x = $x - 1; }
	    elsif ($direction == 2) { $y = $y - 1; }
	    elsif ($direction == 3) { $x = $x + 1; }  
      }   
    }
    
    if    (($x == $x_min) && ($x_min > 0))       { $x_min = $x_min - 1; }
    elsif (($x == $x_max) && ($x_max < $width - 1))  { $x_max = $x_max + 1; }
    elsif (($y == $y_min) && ($y_min > 0))       { $y_min = $y_min - 1; }
    elsif (($y == $y_max) && ($y_max < $height - 1)) { $y_max = $y_max + 1; }
  }
  if ($self->{DEBUG}) { $self->drawRectangle(x_min => $x_min, x_max => $x_max,y_min => $y_min, y_max => $y_max); }
  $self->createImage();
 	
} # generate

# Set the start position for the fractal
# Parameter: x => x-axis, y => y => y-axis
sub setStartPosition
{
  my $self = shift;
  my %coordinate = @_;
  foreach my $coord (keys %coordinate)
  {
    if ($coordinate{$coord} !~ /^\d+$/) { $self->exitOnError("Parameter $coord not valid"); }
  }

  if ($coordinate{x} > $self->{IMG_WIDTH}) { $self->exitOnError("Parameter x is outside of image"); }
  if ($coordinate{y} > $self->{IMG_HEIGHT}) { $self->exitOnError("Parameter y is outside of image"); }
  @{$self->{START}} = ($coordinate{x},$coordinate{y});
  return 1; 
} # setStartPosition

# Draws a rectangle
# Parameter: x_min => xxx, x_max => xxx, y_min => xxx, y_max => xxx
sub drawRectangle
{
  my $self = shift;
  my %para = @_;	
  $self->addLogMessage("Area: x_min: ".$para{x_min}." x_max: ".$para{x_max}." y_min: ".$para{y_min}." y_max: ".$para{y_max});
  for (my $a = $para{x_min}; $a <= $para{x_max}; $a++)
  {
	$self->{MATRIX}->[$a][$para{y_min}] = 1;
	$self->{MATRIX}->[$a][$para{y_max}] = 1;
  }
  for (my $a = $para{y_min}; $a <= $para{y_max}; $a++)
  {
	$self->{MATRIX}->[$para{x_min}][$a] = 1;
	$self->{MATRIX}->[$para{x_max}][$a] = 1;    	  
  }	
} # drawRectangle

1;

__END__
# Below is the documentation for Math::Fractal::DLA::Explode

=head1 NAME

Math::Fractal::DLA::Explode

=head1 SYNOPSIS

  use Math::Fractal::DLA::Explode;
  $fractal = new Math::Fractal::DLA::Explode;
  
  # Set the values of Math::Fractal::DLA
  $fractal->debug( debug => 1, logfile => FILE );
  .
  .
  $fractal->setColors(5);

  # Set the target point (center of the explosion)
  $self->setStartPosition ( x => X, y => Y );
  
  # Generate the fractal
  $fractal->generate();

  # Write the generated fractal to a file
  $fractal->writeFile();
    
=head1 DESCRIPTION

Math::Fractal::DLA::Explode is the implementation of a standard Diffusion Limited Aggregation (DLA) fractal

=head1 OVERVIEW

The module Math::Fractal::DLA::Explode is the implementation of the most widely known type of DLA fractals. The fractal is created by single particles which move from an outter rectangle towards the target area. By hitting the area the particle becomes a part of the target area and the fractal grows.

=head1 METHODS

Math::Fractal::DLA::Explode extends the super class with two methods:

=over 4

=item setStartPosition ( x => X, y => Y )

Sets the position where the fractal will start to grow

=item generate ( )

Generates the fractal

=back

=head1 AUTHOR

Wolfgang Gruber, w.gruber@urldirect.at

=head1 SEE ALSO

Math::Fractal::DLA

Lincoln D. Stein's GD module 

=head1 COPYRIGHT

Copyright (c) 2002 by Wolfgang Gruber. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut



