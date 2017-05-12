#==========================================================================
# Module: GD::Graph3d
#
# Copyright (C) 2000 Wadsack-Allen. All Rights Reserved.
#
#--------------------------------------------------------------------------
# Date      Modification                                             Author
# -------------------------------------------------------------------------
# 08Nov2001 Re-sourced to use standard module files and structure.
#           The package is now GD-Graph3d which us what people expect    JW
#==========================================================================
package GD::Graph3d;
$GD::Graph3d::VERSION = '0.63';
1;

=head1 NAME

GD::Graph3D - Create 3D Graphs with GD and GD::Graph

=head1 SYNOPSIS

	use GD::Graph::moduleName;
	my @data = ( 
	   ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
	   [ 1203,  3500,  3973,  2859,  3012,  3423,  1230]
	);
	my $graph = new GD::Graph::moduleName( 400, 300 );
	$graph->set( 
		x_label           => 'Day of the week',
		y_label           => 'Number of hits',
		title             => 'Daily Summary of Web Site',
	);
	my $gd = $graph->plot( \@data );

Where I<moduleName> is one of C<bars3d>, C<lines3d> or C<pie3d>. 

=head1 DESCRIPTION

This is the GD::Graph3d extensions module. It provides 3D graphs for the 
GD::Graph module by Martien Verbruggen, which in turn generates graph 
using Lincoln Stein's GD.pm.

You use these modules just as you would any of the GD::Graph modules, except 
that they generate 3d-looking graphs. Each graph type is described below 
with only the options that are unique to the 3d version. The modules are 
based on their 2d versions (e.g. GD::Graph::bars3d works like 
GD::Graph::bars), and support all the options in those. Make sure to read 
the documentation on GD::Graph.

=over 4

=item GD::Graph::pie3d

This is merely a wrapper around GD::Graph::pie for consistency. It also 
sets 3d pie mode by default (which GD::Graph does as of version 1.22).
All options are exactly as in GD::Graph::pie.

=item GD::Graph::bars3d

This works like GD::Graph::bars, but draws 3d bars. The following settings 
are new or changed in GD::Graph::bars3d.

=over 4

=item bar_depth

Sets the z-direction depth of the bars. This defaults to 10. If you have a 
large number of bars or a small chart width, you may want to change this. 
A visually good value for this is approximately 
width_of_chart / number_of_bars.

=item overwrite

In GD::Graph::bars, multiple series of bars are normally drawn side-by-side. 
You can set overwrite to 1 to tell it to draw each series behind the 
previous one. By setting overwrite to 2 you can have them drawn on top of 
each other, that is the series are stacked.

=item shading

By default this is set to '1' and will shade and highlight the bars (and axes).
The light source is at top-left-center which scan well for most computer 
users. You can disable the shading of bars and axes by specifying a false 
value for this option.

=back

=item GD::Graph::lines3d

This works like GD::Graph::lines, but draws 3d line. The following settings 
are new or changed in GD::Graph::line3d.

=over 4

=item line_depth

Sets the z-direction depth of the lines. This defaults to 10. If you have a 
large number of bars or a small chart width, you may want to change this. 
A visually good value for this is approximately 
width_of_chart / number_of_bars.

=item shading

By default this is set to '1' and will shade and highlight the line (and axes).
The light source is at top-left-center which scan well for most computer 
users. You can disable the shading of lines and axes by specifiying a false 
value for this option.

=back

=back

=head1 VERSION

0.63 (6 December 2002)

=head1 INSTALLATION

You will need to have the GD::Graph version 1.30 or later installed. You should also 
have Perl version 5.005 or 5.6 installed.

To install, just do the normal:

	perl Makefile.PL
	make
	make install

The documentation is in GD::Graph::Graph3d.pod.

=head1 AUTHOR

Jeremy Wadsack for Wadsack-Allen Digital Group. 
<F<dgsupport at wadsack-allen dot com>>

Most of the modules are based on the GD::Graph modules by Martien Verbruggen.

=head1 LATEST RELEASE

The latest release is available from CPAN: http://www.cpan.org/.

=head1 COPYRIGHT

Copyright (c) 1999-2001 Wadsack-Allen. All rights reserved.

Much of the original code is from GD::Graph:

GIFgraph: Copyright (c) 1995-1999 Martien Verbruggen.

Chart::PNGgraph: Copyright (c) 1999 Steve Bonds.

GD::Graph: Copyright (c) 1999 Martien Verbruggen.

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

