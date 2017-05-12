package Image::Leptonica::Func::gplot;
$Image::Leptonica::Func::gplot::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::gplot

=head1 VERSION

version 0.04

=head1 C<gplot.c>

  gplot.c

     Basic plotting functions
          GPLOT      *gplotCreate()
          void        gplotDestroy()
          l_int32     gplotAddPlot()
          l_int32     gplotSetScaling()
          l_int32     gplotMakeOutput()
          l_int32     gplotGenCommandFile()
          l_int32     gplotGenDataFiles()

     Quick and dirty plots
          l_int32     gplotSimple1()
          l_int32     gplotSimple2()
          l_int32     gplotSimpleN()

     Serialize for I/O
          GPLOT      *gplotRead()
          l_int32     gplotWrite()


     Utility for programmatic plotting using gnuplot 7.3.2 or later
     Enabled:
         - output to png (color), ps (mono), x11 (color), latex (mono)
         - optional title for graph
         - optional x and y axis labels
         - multiple plots on one frame
         - optional title for each plot on the frame
         - optional log scaling on either or both axes
         - choice of 5 plot styles for each plot
         - choice of 2 plot modes, either using one input array
           (Y vs index) or two input arrays (Y vs X).  This
           choice is made implicitly depending on the number of
           input arrays.

     Usage:
         gplotCreate() initializes for plotting
         gplotAddPlot() for each plot on the frame
         gplotMakeOutput() to generate all output files and run gnuplot
         gplotDestroy() to clean up

     Example of use:
         gplot = gplotCreate("tempskew", GPLOT_PNG, "Skew score vs angle",
                    "angle (deg)", "score");
         gplotAddPlot(gplot, natheta, nascore1, GPLOT_LINES, "plot 1");
         gplotAddPlot(gplot, natheta, nascore2, GPLOT_POINTS, "plot 2");
         gplotSetScaling(gplot, GPLOT_LOG_SCALE_Y);
         gplotMakeOutput(gplot);
         gplotDestroy(&gplot);

     Note for output to GPLOT_LATEX:
         This creates latex output of the plot, named <rootname>.tex.
         It needs to be placed in a latex file <latexname>.tex
         that precedes the plot output with, at a minimum:
           \documentclass{article}
           \begin{document}
         and ends with
           \end{document}
         You can then generate a dvi file <latexname>.dvi using
           latex <latexname>.tex
         and a PostScript file <psname>.ps from that using
           dvips -o <psname>.ps <latexname>.dvi

=head1 FUNCTIONS

=head2 gplotAddPlot

l_int32 gplotAddPlot ( GPLOT *gplot, NUMA *nax, NUMA *nay, l_int32 plotstyle, const char *plottitle )

  gplotAddPlot()

      Input:  gplot
              nax (<optional> numa: set to null for Y_VS_I;
                   required for Y_VS_X)
              nay (numa: required for both Y_VS_I and Y_VS_X)
              plotstyle (GPLOT_LINES, GPLOT_POINTS, GPLOT_IMPULSES,
                         GPLOT_LINESPOINTS, GPLOT_DOTS)
              plottitle  (<optional> title for individual plot)
      Return: 0 if OK, 1 on error

  Notes:
      (1) There are 2 options for (x,y) values:
            o  To plot an array vs the index, set nax = NULL.
            o  To plot one array vs another, use both nax and nay.
      (2) If nax is defined, it must be the same size as nay.
      (3) The 'plottitle' string can have spaces, double
          quotes and backquotes, but not single quotes.

=head2 gplotCreate

GPLOT * gplotCreate ( const char *rootname, l_int32 outformat, const char *title, const char *xlabel, const char *ylabel )

  gplotCreate()

      Input:  rootname (root for all output files)
              outformat (GPLOT_PNG, GPLOT_PS, GPLOT_EPS, GPLOT_X11,
                         GPLOT_LATEX)
              title  (<optional> overall title)
              xlabel (<optional> x axis label)
              ylabel (<optional> y axis label)
      Return: gplot, or null on error

  Notes:
      (1) This initializes the plot.
      (2) The 'title', 'xlabel' and 'ylabel' strings can have spaces,
          double quotes and backquotes, but not single quotes.

=head2 gplotDestroy

void gplotDestroy ( GPLOT **pgplot )

   gplotDestroy()

        Input: &gplot (<to be nulled>)
        Return: void

=head2 gplotGenCommandFile

l_int32 gplotGenCommandFile ( GPLOT *gplot )

  gplotGenCommandFile()

      Input:  gplot
      Return: 0 if OK, 1 on error

=head2 gplotGenDataFiles

l_int32 gplotGenDataFiles ( GPLOT *gplot )

  gplotGenDataFiles()

      Input:  gplot
      Return: 0 if OK, 1 on error

=head2 gplotMakeOutput

l_int32 gplotMakeOutput ( GPLOT *gplot )

  gplotMakeOutput()

      Input:  gplot
      Return: 0 if OK; 1 on error

  Notes:
      (1) This uses gplot and the new arrays to add a plot
          to the output, by writing a new data file and appending
          the appropriate plot commands to the command file.
      (2) The gnuplot program for windows is wgnuplot.exe.  The
          standard gp426win32 distribution does not have a X11 terminal.

=head2 gplotRead

GPLOT * gplotRead ( const char *filename )

  gplotRead()

      Input:  filename
      Return: gplot, or NULL on error

=head2 gplotSetScaling

l_int32 gplotSetScaling ( GPLOT *gplot, l_int32 scaling )

  gplotSetScaling()

      Input:  gplot
              scaling (GPLOT_LINEAR_SCALE, GPLOT_LOG_SCALE_X,
                       GPLOT_LOG_SCALE_Y, GPLOT_LOG_SCALE_X_Y)
      Return: 0 if OK; 1 on error

  Notes:
      (1) By default, the x and y axis scaling is linear.
      (2) Call this function to set semi-log or log-log scaling.

=head2 gplotSimple1

l_int32 gplotSimple1 ( NUMA *na, l_int32 outformat, const char *outroot, const char *title )

  gplotSimple1()

      Input:  na (numa; plot Y_VS_I)
              outformat (GPLOT_PNG, GPLOT_PS, GPLOT_EPS, GPLOT_X11,
                         GPLOT_LATEX)
              outroot (root of output files)
              title  (<optional>, can be NULL)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This gives a line plot of a numa, where the array value
          is plotted vs the array index.  The plot is generated
          in the specified output format; the title  is optional.
      (2) When calling this function more than once, be sure the
          outroot strings are different; otherwise, you will
          overwrite the output files.

=head2 gplotSimple2

l_int32 gplotSimple2 ( NUMA *na1, NUMA *na2, l_int32 outformat, const char *outroot, const char *title )

  gplotSimple2()

      Input:  na1 (numa; we plot Y_VS_I)
              na2 (ditto)
              outformat (GPLOT_PNG, GPLOT_PS, GPLOT_EPS, GPLOT_X11,
                         GPLOT_LATEX)
              outroot (root of output files)
              title  (<optional>)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This gives a line plot of two numa, where the array values
          are each plotted vs the array index.  The plot is generated
          in the specified output format; the title  is optional.
      (2) When calling this function more than once, be sure the
          outroot strings are different; otherwise, you will
          overwrite the output files.

=head2 gplotSimpleN

l_int32 gplotSimpleN ( NUMAA *naa, l_int32 outformat, const char *outroot, const char *title )

  gplotSimpleN()

      Input:  naa (numaa; we plot Y_VS_I for each numa)
              outformat (GPLOT_PNG, GPLOT_PS, GPLOT_EPS, GPLOT_X11,
                         GPLOT_LATEX)
              outroot (root of output files)
              title (<optional>)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This gives a line plot of all numas in a numaa (array of numa),
          where the array values are each plotted vs the array index.
          The plot is generated in the specified output format;
          the title  is optional.
      (2) When calling this function more than once, be sure the
          outroot strings are different; otherwise, you will
          overwrite the output files.

=head2 gplotWrite

l_int32 gplotWrite ( const char *filename, GPLOT *gplot )

  gplotWrite()

      Input:  filename
              gplot
      Return: 0 if OK; 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
