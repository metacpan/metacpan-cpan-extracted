#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		GIFgraph::axestype.pm
#
#	This package is not in use for GIFgraph itself anymore, but it's
#	here in case anyone subclasses this. Hopefully it will still work.
#
# $Id: axestype.pm,v 1.5 1999/12/29 12:17:44 mgjv Exp $
#
#==========================================================================

package GIFgraph::axestype;
use strict;
use GIFgraph;
use GD::Graph::axestype;
@GIFgraph::axestype::ISA = qw(GD::Graph::axestype GIFgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
