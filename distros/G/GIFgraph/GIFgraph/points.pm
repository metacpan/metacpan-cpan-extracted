#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		GIFgraph::points.pm
#
# $Id: points.pm,v 1.3 1999/12/26 10:59:19 mgjv Exp $
#
#==========================================================================

package GIFgraph::points;
use strict;
use GIFgraph;
use GD::Graph::points;
@GIFgraph::points::ISA = qw(GD::Graph::points GIFgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
