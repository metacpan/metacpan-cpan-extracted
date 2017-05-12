#! /usr/bin/perl
#
# An example from libplot documentation
# It draws a spiral consisting of elliptically boxed text
#

use Graphics::Plotter(parampl);
use POSIX(pow);

$SIZE = 100.0;	# nominal size of user coordinate frame
$EXPAND = 2.2;	# expansion factor for elliptical box
$M_PI = 3.14159;
  
sub draw_boxed_string
{  
  my ($handle, $s, $size, $angle) = @_;

  my ($true_size, $width);
  
  $handle->ftextangle ($angle);		# text inclination angle (degrees)
  $true_size = $handle->ffontsize ($size);	# choose font size
  $width = $handle->flabelwidth ($s);		# compute width of text string
  $handle->fellipserel (0.0, 0.0,		# draw surrounding ellipse
	$EXPAND * 0.5 * $width, $EXPAND * 0.5 * $true_size, $angle);
  $handle->alabel ('c', 'c', $s);		# draw centered text string
}   

exit &main();

sub main
{
  my ($handle, $i);

  # set a Plotter parameter
  parampl ("PAGESIZE", "letter");

  # create a Postscript Plotter that writes to standard output
  if (($handle = Graphics::Plotter::PS->new(STDIN, STDOUT, STDERR)) < 0)
    {
      print STDERR "Couldn't create Plotter\n";
      return 1;
    }
    
  if ($handle->openpl () < 0)		# open Plotter
    {
      print STDERR "Couldn't open Plotter\n";
      return 1;
    }
  $handle->fspace (-($SIZE), -($SIZE), $SIZE, $SIZE); # specify user coor system
  $handle->pencolorname ("blue");	# pen color will be blue
  $handle->fillcolorname ("white");
  $handle->filltype (1);			# ellipses will be filled with white
  $handle->fontname ("NewCenturySchlbk-Roman");	# choose a Postscript font

  for ($i = 80; $i > 1; $i--)	# loop through angles
    {
      my ($theta, $radius);
    
      $theta = 0.5 * $i; # theta is in radians
      $radius = $SIZE / pow ($theta, 0.35);	# this yields a spiral
      $handle->fmove ($radius * cos ($theta), $radius * sin ($theta));
      draw_boxed_string ($handle, "GNU libplot!", 0.04 * $radius,
                          (180.0 * $theta / $M_PI) - 90.0);
    }

  if ($handle->closepl () < 0)		# close Plotter
    {
      print STDERR "Couldn't close Plotter\n";
      return 1;
    }
  return 0;
}  
