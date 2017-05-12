#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		GIFgraph::pie.pm
#
# $Id: pie.pm,v 1.3 1999/12/26 10:59:19 mgjv Exp $
#
#==========================================================================

package GIFgraph::pie;
use strict;
use GIFgraph;
use GD::Graph::pie;
@GIFgraph::pie::ISA = qw(GD::Graph::pie GIFgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
