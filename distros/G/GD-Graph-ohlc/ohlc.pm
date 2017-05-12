#==========================================================================
#              Copyright (c) 2008 Paul Miller
#==========================================================================

package GD::Graph::ohlc;

use strict;
use warnings;

use GD::Graph::mixed; # NOTE: we pull this in so we can modify part of it.
use GD::Graph::axestype;
use GD::Graph::utils qw(:all);
use GD::Graph::colour qw(:colours);

use constant PI => 4 * atan2(1,1);

our $VERSION = "0.9703";
our @ISA = qw(GD::Graph::axestype);

push @GD::Graph::mixed::ISA, __PACKAGE__;

# draw_data_set {{{
sub draw_data_set {
    my $self = shift;
    my $ds   = shift;

    my @values = $self->{_data}->y_values($ds) or
        return $self->_set_error("Impossible illegal data set: $ds", $self->{_data}->error);

    # Pick a colour
    my $dsci = $self->set_clr($self->pick_data_clr($ds));

    my $GX;
    my ($ox,$oy, $cx,$cy, $lx,$ly, $hx,$hy); # NOTE: all the x's are the same...
    for (my $i = 0; $i < @values; $i++) {
        my $value = $values[$i];
        next unless ref($value) eq "ARRAY" and @$value==4;
        my ($open, $high, $low, $close) = @$value;

        if (defined($self->{x_min_value}) && defined($self->{x_max_value})) {
            $GX = $self->{_data}->get_x($i);

            ($ox, $oy) = $self->val_to_pixel($GX, $value->[0], $ds);
            ($hx, $hy) = $self->val_to_pixel($GX, $value->[1], $ds);
            ($lx, $ly) = $self->val_to_pixel($GX, $value->[2], $ds);
            ($cx, $cy) = $self->val_to_pixel($GX, $value->[3], $ds);

        } else {
            ($ox, $oy) = $self->val_to_pixel($i+1, $value->[0], $ds);
            ($hx, $hy) = $self->val_to_pixel($i+1, $value->[1], $ds);
            ($lx, $ly) = $self->val_to_pixel($i+1, $value->[2], $ds);
            ($cx, $cy) = $self->val_to_pixel($i+1, $value->[3], $ds);
        }

        $self->ohlc_marker($ox,$oy, $cx,$cy, $lx,$ly, $hx,$hy, $dsci );
        $self->{_hotspots}[$ds][$i] = ['rect', $self->ohlc_marker_coordinates($ox,$oy, $cx,$cy, $lx,$ly, $hx,$hy)];
    }

    return $ds;
}
# }}}
# ohlc_marker_coordinates {{{
sub ohlc_marker_coordinates {
    my $self = shift;
    my ($ox,$oy, $cx,$cy, $lx,$ly, $hx,$hy) = @_;

    my ($l,$t,$r,$b) = ( $ox-2, $hy, $ox+2, $ly );
    return ($t <= $b) ? ( $l, $t, $r, $b ) : ( $l, $b, $r, $t );
}
# }}}
# ohlc_marker {{{
sub ohlc_marker {
    my $self = shift;
    my ($ox,$oy, $cx,$cy, $lx,$ly, $hx,$hy, $mclr) = @_;
    return unless defined $mclr;

    $self->{graph}->line( ($ox,$oy) => ($ox-2,$oy), $mclr );
    $self->{graph}->line( ($cx,$cy) => ($cx+2,$cy), $mclr );
    $self->{graph}->line( ($lx,$ly) => ($hx,$hy),   $mclr );

    return;
}
# }}}

1;
