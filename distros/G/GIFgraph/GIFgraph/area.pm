#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		GIFgraph::area.pm
#
# $Id: area.pm,v 1.3 1999/12/26 10:59:19 mgjv Exp $
#
#==========================================================================

package GIFgraph::area;
use strict;
use GIFgraph;
use GD::Graph::area;
@GIFgraph::area::ISA = qw(GD::Graph::area GIFgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
