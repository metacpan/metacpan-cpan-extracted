package GD::Graph::splined;

($GD::Graph::splined::VERSION) = '$Revision: 0.01 $' =~ /\s([\d.]+)/;

use strict;
use warnings;

use GD::Graph::axestype;
use GD::Graph::area;			# v1.16
use GD::Polyline;

@GD::Graph::splined::ISA = qw(
	GD::Graph::axestype
	GD::Graph::area
);

# PRIVATE
sub draw_data_set {
    my $self = shift;       # object reference
    my $ds   = shift;       # number of the data set

    my @values = $self->{_data}->y_values($ds) or
        return $self->_set_error("Impossible illegal data set: $ds",
            $self->{_data}->error);

    # Select a data colour
    my $dsci = $self->set_clr($self->pick_data_clr($ds));
    my $brci = $self->set_clr($self->pick_border_clr($ds));

    # Create a new polygon
    my $poly = GD::Polyline->new();

    my @bottom;

    # Add the data points
    for (my $i = 0; $i < @values; $i++) {
        my $value = $values[$i];
        next unless defined $value;

        my $bottom = $self->_get_bottom($ds, $i);
        $value = $self->{_data}->get_y_cumulative($ds, $i)
            if ($self->{overwrite} == 2);

        my ($x, $y) = $self->val_to_pixel($i + 1, $value, $ds);
        $poly->addPt($x, $y);
		# Need to keep track of this stuff for hotspots, and because
		# it's the only reliable way of closing the polygon, without
		# making odd assumptions.
        push @bottom, [$x, $bottom];

        # Hotspot stuff
        # XXX needs fixing. Not used at the moment.
		next unless defined $self->{_hotspots}->[$ds]->[$i];

        if ($i == 0) {
            $self->{_hotspots}->[$ds]->[$i] = ["poly",
                $x, $y,
                $x , $bottom,
                $x - 1, $bottom,
                $x - 1, $y,
                $x, $y];
        }
        else {
            $self->{_hotspots}->[$ds]->[$i] = ["poly",
                $poly->getPt($i),
                @{$bottom[$i]},
                @{$bottom[$i-1]},
                $poly->getPt($i-1),
                $poly->getPt($i)];
        }
    }

	my $spline = $poly->addControlPoints->toSpline;
	$self->{graph}->polydraw($spline,$dsci);

    # Draw the accent lines
    if (defined $brci and
       ($self->{right} - $self->{left})/@values > $self->{accent_treshold}
	) {
        for (my $i = 1; $i < @values - 1; $i++) {
            my $value = $values[$i];
		    ## XXX Why don't I need this line?
            ##next unless defined $value;

            my ($x, $y) = $poly->getPt($i);
            my $bottom = $bottom[$i]->[1];

            $self->{graph}->dashedLine($x, $y, $x, $bottom, $brci);
        }
    }

    return $ds
}

'End of module';

__END__

=head1 NAME

GD::Graph::splined - Smooth line graphs with GD::Graph

=head1 SYNOPSIS

	use strict;
	use GD::Graph::splined;

	my @data = (
	    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
	    [    5,   12,   24,   33,   19,undef,    6,    15,    21],
	    [    1,    2,    5,    6,    3,  1.5,    1,     3,     4]
	);

	my $graph = GD::Graph::splined->new;

	$graph->set(
		x_label => 'X Label',
		y_label => 'Y label',
		title => 'A Splined Graph',
	);
	$graph->set_legend( 'one', 'two' );
	$graph->plot(\@data);

	open(OUT, ">splined.png") or die $!;
	binmode OUT;
	print OUT $graph->gd->png;
	close OUT;

=head1 DESCRIPTION

A L<GD::Graph|GD::Graph> module that can be treated as an C<area> graph, but
renders splined (smoothed) line graphs.

See L<GD::Graph|GD::Graph> for more details of how to produce graphs with GD.

=head1 BUGS

Please use the CPAN Request Tracker to lodge bugs: L<http://rt.cpan.org|http://rt.cpan.org>.

=head1 SEE ALSO

L<GD::Graph>, L<GD::Graph::area>, L<GD::Polyline>, L<GD>.

=head1 AUTHOR AND COPYRIGHT

Lee Goddard added to Martien Verbruggen's L<GD::Graph::area|GD::Graph::area> module
the ability to use Daniel J Harasty's L<GD::Polyline> module.

Thus, Copyright (c) 1995-2000 Martien Verbruggen
with parts copyright (c) 2006 Lee Goddard (lgoddard -at- cpan -dot- org).

This software is made available under the same terms as L<GD::Graph|GD::Graph>.
