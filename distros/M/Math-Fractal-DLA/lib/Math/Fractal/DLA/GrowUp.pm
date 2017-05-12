package Math::Fractal::DLA::GrowUp;

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
  bless ($self,$class);
  return $self;
} # new

sub generate
{
  my $self = $_[0];
  
  $self->addLogMessage("Fractal mode Grow Up");

  my $width = $self->{IMG_WIDTH};
  my $height = $self->{IMG_HEIGHT};
  my $maxpoints = $self->{POINTS};
  my $x = 0; my $y = 0;
  my $setpoints = 0;
  my $y_line = $height - 2;
  my $color_interval = int($maxpoints / $self->{COLORS});
  my $color_value = 0;
      
  while ($setpoints < $maxpoints)
  {
    if (($setpoints % $color_interval) == 0)
    { $color_value ++; $self->addLogMessage("New color $color_value after $setpoints points"); }

    $x = sprintf("%.0f",rand($width));
    $y = $y_line;
    my $set = 0;
    while ($set == 0)
    {
      if (($y == $height) ||
          ($self->{MATRIX}->[$x][$y+1] > 0) ||
	  (($x > 0) && ($self->{MATRIX}->[$x-1][$y] > 0)) ||
	  (($x < $width) && ($self->{MATRIX}->[$x+1][$y] > 0)))
      { 
	$set = 1; $setpoints ++;
	$self->{MATRIX}->[$x][$y] = $color_value;
	if (($y == $y_line) && ($y_line > 0)) { $y_line --; }
      }
      $y ++;
	  
      # Random to left or right
      my $dir = $self->getDirection();
      if (($x > 0) && (($dir == 0) || ($dir == 1))) { $x --; }
      if (($x < $width) && (($dir == 2) || ($dir == 3))) { $x ++; }
    } 
  }
  $self->createImage();
 	
} # generate

1;

__END__
# Below is the documentation for Math::Fractal::DLA::GrowUp

=head1 NAME

Math::Fractal::DLA::GrowUp

=head1 SYNOPSIS

  use Math::Fractal::DLA::GrowUp;
  $fractal = new Math::Fractal::DLA::GrowUp;
  
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

Math::Fractal::DLA::GrowUp implements a DLA fractal which grows bottom up

=head1 OVERVIEW

Math::Fractal::DLA::GrowUp implements a DLA fractal which grows from the bottom of the image to the top. At the end the fractal looks like a very dense undersea vegetation.

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
