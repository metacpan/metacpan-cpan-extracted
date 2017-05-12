#! /usr/bin/perl
#
# It draws a circle and writes there a word
# Piotr Klaban <makler@man.torun.pl>
# This is an examples file from Plotter perl module
# Date: Mar 15 1999
#

use Graphics::Plotter;
use POSIX(pow);

@WORD = ("L","L","2","I","O","2","B","T","X","P","V"); # LIBPLOT V 22X

$M_PI = 3.14159;
$DispType = "X";  # "ps"
$LINECOLOR = "red";

$fontsize = 0.1;
  
sub draw_boxed_string
{  
  my ($s, $size, $angle) = @_;

  my ($true_size, $width);
  
  pl_ftextangle ($angle);		# text inclination angle (degrees)
  $true_size = pl_ffontsize ($size);	# choose font size
  $width = pl_flabelwidth ($s);		# compute width of text string
  pl_fellipserel (0.0, 0.0,		# draw surrounding ellipse
	$EXPAND * 0.5 * $width, $EXPAND * 0.5 * $true_size, $angle);
  pl_alabel ('c', 'c', $s);		# draw centered text string
}   

exit &main();

sub X { my($radius,$angle)=@_; return(cos($angle)*($radius)) }
sub Y { my($radius,$angle)=@_; return(sin($angle)*($radius)) }

sub RAD { my($angle)=shift; return((($angle)/180.)*$M_PI) }

sub XY { my($radius,$angle)=@_; return(X(($radius),RAD($angle))),(Y(($radius),RAD($angle))) }

sub main
{
  my ($handle, $i);

  # set a Plotter parameter
	Graphics::Plotter::parampl ("PAGESIZE", "A4");
	Graphics::Plotter::parampl ("BITMAPSIZE", "300x300");
	Graphics::Plotter::parampl ("BG_COLOR", "blue"); # background color for window

  # create a Postscript Plotter that writes to standard output
  if (($handle = Graphics::Plotter::X->new(STDIN, STDOUT, STDERR)) < 0)
    {
      print STDERR "Couldn't create Plotter\n";
      return 1;
    }
    
  if ($handle->openpl () < 0)		# open Plotter
    {
      print STDERR "Couldn't open Plotter\n";
      return 1;
    }
#  $handle->fspace (-($SIZE), -($SIZE), $SIZE, $SIZE); # specify user coor system
  $handle->fspace (-1, -1, 1, 1); # specify user coor system
  $handle->pencolorname ("black");	# pen color will be blue
#  $handle->fontname ("NewCenturySchlbk-Roman");	# choose a Postscript font
  $handle->fontname("Helvetica");
  $handle->ffontsize ($fontsize);

  $n_slices = 11;

  $r = $radius = 0.9;# * $SIZE;
  $angle = 360./$n_slices;

  $handle->fillcolorname ("white");
  $handle->filltype (1);
  $handle->fcircle(0.,0.,$r);	
  $handle->fillcolorname ("yellow");

    for($t=0;$t<$n_slices;++$t)
				# draw one path for every slice
    {
    	$distance=360./$n_slices;
				
	$handle->fmove(0,0);		# start at center..
	$handle->fcont(XY($r,$angle));	
    	if($distance>179)
    	{			# we need to draw a semicircle first
				# we have to be sure to draw 
				#  counterclockwise (180 wouldn`t work 
				#  in all cases)
	    $handle->farc(0,0,XY($r,$angle),XY($r,$angle+179)); 
	    $angle+=179;	
	    $distance-=179;
    	}
	$handle->farc(0,0,XY($r,$angle),XY($r,$angle+$distance));
	$handle->fcont(0,0);		# return to center

	$place=$angle+0.5*$distance;
	$handle->fmove(XY($r*0.8,$place));
	$handle->alabel('c','c',pop(@WORD));
	
	$angle+=$distance;	# log fraction of circle already drawn

    }
    $handle->filltype(0);
    $handle->fcircle(0.,0.,$r);	
    				# one point in the middle
    $handle->colorname("red");
    $handle->filltype("white");
    $handle->fpoint(0,0);	

  if ($handle->closepl () < 0)		# close Plotter
    {
      print STDERR "Couldn't close Plotter\n";
      return 1;
    }
  return 0;
}  
