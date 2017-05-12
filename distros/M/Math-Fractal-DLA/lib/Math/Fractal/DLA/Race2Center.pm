package Math::Fractal::DLA::Race2Center;

use Math::Fractal::DLA qw(:all);
use strict;
use warnings;
use Exporter;

our @ISA = qw(Math::Fractal::DLA Exporter);

our @EXPORT_OK = qw(generate);
our @EXPORT = qw();

our $VERSION = 0.21;

sub new
{
  my $param = shift;
  my $class = ref($param) || $param;
  my $self = new Math::Fractal::DLA;
  $self->{TYPE} = "Race2Center";
  bless ($self,$class);
  return $self;
} # new

sub generate
{
  my $self = $_[0];
  
  $self->addLogMessage("Fractal mode ".$self->{TYPE});

  my $width = $self->{IMG_WIDTH};
  my $height = $self->{IMG_HEIGHT};
  my $maxpoints = $self->{POINTS};
  my $start_x = int($self->{IMG_WIDTH} / 2);
  my $start_y = int($self->{IMG_HEIGHT} / 2);
  $self->addLogMessage("Begin: $start_x / $start_y");
  my $x = 0; my $y = 0;
  my $setpoints = 0;
  my $color_interval = int($maxpoints / $self->{COLORS});
  my $color_value = 0;
      
  while ($setpoints < $maxpoints)
  {
	if (($setpoints % $color_interval) == 0)
	{ $color_value ++; $self->addLogMessage("New color $color_value after $setpoints points"); }
	$x = $start_x;
	$y = $start_y;
	if ($self->{MATRIX}->[$start_x][$start_y] > 0)
	{ 
	  $self->addLogMessage("Finished after $setpoints points");
	  last;
	}
	my $dir = $self->getDirection();
	my $back_dir = ($dir + 2) % 4;
	my $set = 0;
	while ($set == 0)
	{
	  if ((($x > 0) && ($self->{MATRIX}->[$x-1][$y] > 0)) ||
	      (($x < $width) && ($self->{MATRIX}->[$x+1][$y] > 0)) ||
	      (($y > 0) && ($self->{MATRIX}->[$x][$y-1] > 0)) ||
	      (($y < $height) && ($self->{MATRIX}->[$x][$y+1] > 0)))
	  { 
		$set = 1; $setpoints ++;
		$self->{MATRIX}->[$x][$y] = $color_value;
	  }
	  if (($x == 0) || ($x == $width) || ($y == 0) || ($y == $height))
	  {
		$set = 1; $setpoints ++;
		$self->{MATRIX}->[$x][$y] = $color_value;
      }
	  
	  # Random to left or right
      my $side = $self->getDirection() % 2;
      my $val = $self->getDirection();

      my $x_ok = 0; my $y_ok = 0;     
      if (($x - $val > 0) && ($x + $val < $width))
      { $x_ok = 1; }
      if (($y - $val > 0) && ($y + $val < $height))
      { $y_ok = 1; }
      
	  if    (($dir == 0) && ($side == 0) && ($x_ok == 1)) { $x = $x - $val; $y --; }
	  elsif (($dir == 0) && ($side == 1) && ($x_ok == 1)) { $x = $x + $val; $y --; }	
	  elsif (($dir == 1) && ($side == 0) && ($y_ok == 1)) { $x ++; $y = $y - $val; }
	  elsif (($dir == 1) && ($side == 1) && ($y_ok == 1)) { $x ++; $y = $y + $val; }		  
	  elsif (($dir == 2) && ($side == 0) && ($x_ok == 1)) { $x = $x + $val; $y ++; }
	  elsif (($dir == 2) && ($side == 1) && ($x_ok == 1)) { $x = $x - $val; $y ++; }	
	  elsif (($dir == 3) && ($side == 0) && ($y_ok == 1)) { $x --; $y = $y + $val; }
	  elsif (($dir == 3) && ($side == 1) && ($y_ok == 1)) { $x --; $y = $y - $val; }		  
    } 
  }
  $self->createImage();

} # generate

1;

__END__
# Below is the documentation for Math::Fractal::DLA::Race2Center

=head1 NAME

Math::Fractal::DLA::Race2Center

=head1 SYNOPSIS

  use Math::Fractal::DLA::Race2Center;
  $fractal = new Math::Fractal::DLA::Race2Center;
  
  # Set the values of Math::Fractal::DLA
  $fractal->debug( debug => 1, logfile => FILE );
  .
  .
  $fractal->setColors(5);

  # Generate the fractal
  $fractal->generate();

  # Write the generated fractal to a file
  $fractal->writeFile();
    
=head1 DESCRIPTION

Math::Fractal::DLA::Race2Center is another DLA type

=head1 OVERVIEW

The module Math::Fractal::DLA::Race2Center is similiar to the module Surrounding except that it grows stronger in the middle of each side. The fractal is finished when the first part reaches the middle of the image

=head1 METHODS

=over 4

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
