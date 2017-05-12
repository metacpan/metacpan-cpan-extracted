#==========================================================================
#              Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		GIFgraph.pm
#
#	Description:
#       Module to create graphs from a data set, outputting
#		GIF format graphics.
#
#		Package of a number of graph types:
#		GIFgraph::bars
#		GIFgraph::lines
#		GIFgraph::points
#		GIFgraph::linespoints
#		GIFgraph::area
#		GIFgraph::pie
#		GIFgraph::mixed
#
# $Id: GIFgraph.pm,v 1.7 1999/12/29 12:36:06 mgjv Exp $
#
#==========================================================================

package GIFgraph;

use strict;
use Carp;

use GD::Graph;
use GIFgraph::Convert;

$GIFgraph::VERSION = '1.20';
@GIFgraph::ISA = qw(GD::Graph);

# Old plot returned GIF data. GD::Graph::plot returns GD data
sub _old_plot
{
	my $self = shift;
	my $gd   = shift;

	for ($self->export_format)
	{
		/^gif$/ and 
			return $gd->gif;

		/^png$/ and 
			return GIFgraph::Convert::png2gif($gd->png);

		croak 'Cannot deal with GD export format. Please contact author';
	}
}

sub plot_to_gif # ("file.gif", \@data)
{
	my $self = shift;
	my $file = shift;
	my $data = shift;
	local(*PLOT);
	my $img_data;

	$img_data = $self->plot($data) or
		croak "GIFgraph::plot_to_gif: Cannot get image data";

	open (PLOT,">$file") or 
		carp "Cannot open $file for writing: $!", return;
	binmode PLOT;
	print PLOT $img_data;
	close(PLOT);
}

$GIFgraph::VERSION;

__END__

=head1 NAME

GIFgraph - Graph Plotting Module (deprecated)

=head1 SYNOPSIS

use GIFgraph::moduleName;

=head1 DESCRIPTION

B<GIFgraph> is a I<perl5> module to create and display GIF output 
for a graph.

GIFgraph is nothing more than a wrapper around GD::Graph, and its use is
deprecated. It only exists for backward compatibility. The documentation
for all the functionality can be found in L<GD::Graph>.

This module should work with all versions of GD, but it has only been
tested with version 1.19 and above. Version 1.19 is the last version
that produces GIF output directly. Any version later than that requires
a conversion step. The default distribution of GIFgraph uses
Image::Magick for this. If you'd like to use something else, please
replace the sub png2gif in GIFgraph::Convert with something more to your
liking.

=head1 NOTES

Note that if you use GIFgraph with a GD version 1.20 or up that any
included logos will have to be in the PNG format. The only time that GIF
comes into play is _after_ GD has done its work, and the PNG gets
converted to GIF. There are no plans to change that behaviour; it's too
much work, and for you, the user, it is a one time conversion of these
pictures, when you move from GD < 1.20 to GD >= 1.20.

=head1 SEE ALSO

GD::Graph(3), Chart::PNGgraph(3).

=head1 AUTHOR

Martien Verbruggen <mgjv@comdyn.com.au>

=head2 Copyright

Copyright (C) 1995-2000 Martien Verbruggen.
All rights reserved.  This package is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=cut

