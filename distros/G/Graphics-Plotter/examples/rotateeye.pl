#!/usr/bin/perl
#
# Name: rotateeye.pl
# rotates an eye in the X window
# This file is an example file of Plotter.pm perl module
#
# Piotr Klaban <makler@man.torun.pl>
# Date: Mar 15 1999
#

       use Graphics::Plotter;

       $i = 0; $j = 0;
     
       # set Plotter parameters
#       Graphics::Plotter::parampl ("BITMAPSIZE", "300x150");
       Graphics::Plotter::parampl ("VANISH_ON_DELETE", "yes");
       Graphics::Plotter::parampl ("USE_DOUBLE_BUFFERING", "fast");
     
       # create an X Plotter with the specified parameters 
       if (($handle = Graphics::Plotter::X->new(STDIN, STDOUT, STDERR)) < 0)
         {
           printf STDERR "Couldn't create Plotter\n";
           return 1;
         }
     
       if ($handle->openpl () < 0)          # open Plotter 
         {
           fprintf (STDERR, "Couldn't open Plotter\n");
           return 1;
         }
       $handle->space (0, 0, 299, 149);     # specify user coordinate system 
       $handle->linewidth (8);              # width of lines in user coordinates 
       $handle->filltype (1);               # objects will be filled 
       $handle->bgcolorname ("saddle brown");  # background color for the window 
       for ($j = 0; $j < 300; $j++)
         {
	   for (1..10000) {}
           $handle->erase ();               # erase window 
           $handle->pencolorname ("red");   # choose red pen, with cyan filling 
           $handle->fillcolorname ("cyan");
           $handle->ellipse ($i, 75, 35, 50, $i);  # draw an ellipse 
           $handle->colorname ("black");    # choose black pen, with black filling 
           $handle->circle ($i, 75, 12);     # draw a circle [the pupil] 
           $i = ($i + 2) % 300;      # shift rightwards 
         }
       if ($handle->closepl () < 0)         # close Plotter 
         {
           printf STDERR "Couldn't close Plotter\n";
           return 1;
         }
