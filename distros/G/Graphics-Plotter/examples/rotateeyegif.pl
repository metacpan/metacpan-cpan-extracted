#! /usr/bin/perl
#
# gifanim.pl
# An example program from the plotutils documentation
# The following program creates a simple animated pseudo-GIF, 150 pixels wide and 100 pixels high.
#

use Graphics::Plotter;
#use strict;

my ($i, $handle);
    
# set Plotter parameters

Graphics::Plotter::parampl ("BITMAPSIZE", "150x100");
Graphics::Plotter::parampl ("BG_COLOR", "orange");
Graphics::Plotter::parampl ("TRANSPARENT_COLOR", "orange");
Graphics::Plotter::parampl ("GIF_ITERATIONS", "100");
Graphics::Plotter::parampl ("GIF_DELAY", "5");

# create a GIF Plotter with the specified parameters
$handle = Graphics::Plotter::GIF->new(STDIN, STDOUT, STDERR);

$handle->openpl();			# begin page of graphics
$handle->space (0, 0, 149, 99);	# specify user coordinate system
      
$handle->pencolorname ("red");	# objects will be drawn in red
$handle->linewidth (5);		# set the line thickness
$handle->filltype (1);		# objects will be filled
$handle->fillcolorname ("black");	# set the fill color

for ($i = 0; $i < 180 ; $i += 15)
{
    $handle->erase ();		# begin new GIF image
    $handle->ellipse (75, 50, 40, 20,$ i); # draw an ellipse
}

$handle->closepl ();			# end page of graphics
