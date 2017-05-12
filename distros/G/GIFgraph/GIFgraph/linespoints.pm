#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		GIFgraph::linespoints.pm
#
# $Id: linespoints.pm,v 1.3 1999/12/26 10:59:19 mgjv Exp $
#
#==========================================================================

package GIFgraph::linespoints;
use strict;
use GIFgraph;
use GD::Graph::linespoints;
@GIFgraph::linespoints::ISA = qw(GD::Graph::linespoints GIFgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
