#==========================================================================
#              Copyright (c) 1995-1998 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::points.pm
#
# $Id: points.pm,v 1.13 2005/12/14 04:13:32 ben Exp $
#
#==========================================================================

package GD::Graph::points;

($GD::Graph::points::VERSION) = '$Revision: 1.13 $' =~ /\s([\d.]+)/;

use strict;
 
use GD::Graph::axestype;
use GD::Graph::utils qw(:all);

@GD::Graph::points::ISA = qw( GD::Graph::axestype );

# PRIVATE
sub draw_data_set
{
    my $self = shift;
    my $ds = shift;

    my @values = $self->{_data}->y_values($ds) or
        return $self->_set_error("Impossible illegal data set: $ds",
            $self->{_data}->error);

    # Pick a colour
    my $dsci = $self->set_clr($self->pick_data_clr($ds));
    my $type = $self->pick_marker($ds);

    for (my $i = 0; $i < @values; $i++)
    {
        next unless defined $values[$i];
        my ($xp, $yp);
        if (defined($self->{x_min_value}) && defined($self->{x_max_value}))
        {
            ($xp, $yp) = $self->val_to_pixel(
                $self->{_data}->get_x($i), $values[$i], $ds);
        }
        else    
        {
            ($xp, $yp) = $self->val_to_pixel($i+1, $values[$i], $ds);
        }
        $self->marker($xp, $yp, $type, $dsci );
        $self->{_hotspots}->[$ds]->[$i] = 
            ['rect', $self->marker_coordinates($xp, $yp)];
    }

    return $ds;
}

# Pick a marker type

sub pick_marker # number
{
    my $self = shift;
    my $num = shift;

    ref $self->{markers} ?
        $self->{markers}[ $num % (1 + $#{$self->{markers}}) - 1 ] :
        ($num % 8) || 8;
}

# Draw a marker

sub marker_coordinates
{
    my $self = shift;
    my ($xp, $yp) = @_;
    return (
        $xp - $self->{marker_size},
        $xp + $self->{marker_size},
        $yp + $self->{marker_size},
        $yp - $self->{marker_size},
    );
}

sub marker # $xp, $yp, $type, $colourindex
{
    my $self = shift;
    my ($xp, $yp, $mtype, $mclr) = @_;
    return unless defined $mclr;

    my ($l, $r, $b, $t) = $self->marker_coordinates($xp, $yp);

    MARKER: {

        ($mtype == 1) && do 
        { # Square, filled
            $self->{graph}->filledRectangle($l, $t, $r, $b, $mclr);
            last MARKER;
        };
        ($mtype == 2) && do 
        { # Square, open
            $self->{graph}->rectangle($l, $t, $r, $b, $mclr);
            last MARKER;
        };
        ($mtype == 3) && do 
        { # Cross, horizontal
            $self->{graph}->line($l, $yp, $r, $yp, $mclr);
            $self->{graph}->line($xp, $t, $xp, $b, $mclr);
            last MARKER;
        };
        ($mtype == 4) && do 
        { # Cross, diagonal
            $self->{graph}->line($l, $b, $r, $t, $mclr);
            $self->{graph}->line($l, $t, $r, $b, $mclr);
            last MARKER;
        };
        ($mtype == 5) && do 
        { # Diamond, filled
            $self->{graph}->line($l, $yp, $xp, $t, $mclr);
            $self->{graph}->line($xp, $t, $r, $yp, $mclr);
            $self->{graph}->line($r, $yp, $xp, $b, $mclr);
            $self->{graph}->line($xp, $b, $l, $yp, $mclr);
            $self->{graph}->fillToBorder($xp, $yp, $mclr, $mclr);
            last MARKER;
        };
        ($mtype == 6) && do 
        { # Diamond, open
            $self->{graph}->line($l, $yp, $xp, $t, $mclr);
            $self->{graph}->line($xp, $t, $r, $yp, $mclr);
            $self->{graph}->line($r, $yp, $xp, $b, $mclr);
            $self->{graph}->line($xp, $b, $l, $yp, $mclr);
            last MARKER;
        };
        ($mtype == 7) && do 
        { # Circle, filled
            $self->{graph}->arc($xp, $yp, 2 * $self->{marker_size},
                         2 * $self->{marker_size}, 0, 360, $mclr);
            $self->{graph}->fillToBorder($xp, $yp, $mclr, $mclr);
            last MARKER;
        };
        ($mtype == 8) && do 
        { # Circle, open
            $self->{graph}->arc($xp, $yp, 2 * $self->{marker_size},
                         2 * $self->{marker_size}, 0, 360, $mclr);
            last MARKER;
        };
        ($mtype == 9) && do
        { # Horizontal line
            $self->{graph}->line($l, $yp, $r, $yp, $mclr);
            last MARKER;
        };
        ($mtype == 10) && do
        { # vertical line
            $self->{graph}->line($xp, $t, $xp, $b, $mclr);
            last MARKER;
        };
    }
}

sub draw_legend_marker
{
    my $self = shift;
    my $n = shift;
    my $x = shift;
    my $y = shift;

    my $ci = $self->set_clr($self->pick_data_clr($n));

    my $old_ms = $self->{marker_size};
    my $ms = _min($self->{legend_marker_height}, $self->{legend_marker_width});

    ($self->{marker_size} > $ms/2) and $self->{marker_size} = $ms/2;
    
    $x += int($self->{legend_marker_width}/2);
    $y += int($self->{lg_el_height}/2);

    $n = $self->pick_marker($n);

    $self->marker($x, $y, $n, $ci);

    $self->{marker_size} = $old_ms;
}

"Just another true value";
