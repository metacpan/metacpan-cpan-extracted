#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		GIFgraph::lines.pm
#
# $Id: lines.pm,v 1.3 1999/12/26 10:59:19 mgjv Exp $
#
#==========================================================================

package GIFgraph::lines;
use strict;
use GIFgraph;
use GD::Graph::lines;
@GIFgraph::lines::ISA = qw(GD::Graph::lines GIFgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
