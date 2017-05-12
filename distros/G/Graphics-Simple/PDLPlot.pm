=head1 NAME

Graphics::Simple::PDLPlot -- Plot PDL data using Graphics::Simple

=head1 DESCRIPTION

Functions:

	line $pdl_y;
	line $pdl_x, $pdl_y;

Methods:

	$g = Graphics::Simple::PDLPlot::Graph->new();

	$g->line($pdl_x, $pdl_y);
	$g->points($pdl_x, $pdl_y);
	$g->x_axis(1.0,2.0);
	$g->y_axis(0.1,1000,LOG);
	$g->plot($win);

=cut

sub line {
	my($x, $y) = @_;
}

sub points {
}


=head1 BUGS

This module is in the wrong place - it should be in the PDL distribution
and will be in the future.

Wildly inefficient - there must be more synergy between this module
and the C<Graphics::Simple> implementations for vectorization.

=head1 AUTHOR

Copyright(C) Tuomas J. Lukka 1999. All rights reserved.
This software may be distributed under the same conditions as Perl itself.

=cut
