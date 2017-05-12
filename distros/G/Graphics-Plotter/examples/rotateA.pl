#!/usr/bin/perl
#
# Name: test.pl
# rotates 'A' label in the X window
# This file is an example file of Plotter.pm perl module
#
# Piotr Klaban <makler@man.torun.pl>
# Date: Mar 15 1999
#

	$cycles = 0;
	$maxcycles = 1 * 360;

	use Graphics::Plotter;

	$| = 1;

	$angle = 0;
     
	# set Plotter parameters
	Graphics::Plotter::parampl ("BITMAPSIZE", "300x300");
	Graphics::Plotter::parampl ("BG_COLOR", "blue"); # background color for window
	Graphics::Plotter::parampl ("USE_DOUBLE_BUFFERING", "fast"); # or "no" or "yes" or "fast"
	Graphics::Plotter::parampl ("VANISH_ON_DELETE", "yes");
     
	# create an X Plotter with the specified parameters
	$handle = Graphics::Plotter::X->new(STDIN, STDOUT, STDERR);
     
	# open X Plotter, initialize coordinates, pen, and font
	if ($handle->openpl() < 0) {
		die "Could not create plotter: $!\n";
	}
	$handle->fspace (0.0, 0.0, 1.0, 1.0);  # use normalized coordinates
	$handle->pencolorname ("black");
	$handle->ffontsize (0.5);
# utopia eats too much Xserver memory for rasterizing
#	$handle->fontname ("utopia-medium-r-normal");
	$handle->fontname ("HersheySerif");
     
	$handle->fmove (.50,.50);              # move to center
	while (1)                     # loop endlessly
	{
	    $handle->textangle ($angle++);      # set new rotation angle
	    last if $cycles++ > $maxcycles;
	    $handle->erase ();
	    $handle->alabel ('c', 'c', "A");   # draw a centered `A'
	}

	$handle->closepl();                    # close Plotter
