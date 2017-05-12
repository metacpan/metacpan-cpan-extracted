#==========================================================================
#              Copyright (c) 1995-1998 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::lines.pm
#
# $Id: lines.pm,v 1.15 2005/12/14 04:13:00 ben Exp $
#
#==========================================================================

package GD::Graph::lines;

($GD::Graph::lines::VERSION) = '$Revision: 1.15 $' =~ /\s([\d.]+)/;

use strict;
 
use GD;
use GD::Graph::axestype;

@GD::Graph::lines::ISA = qw( GD::Graph::axestype );

# PRIVATE

sub draw_data_set
{
    my $self = shift;
    my $ds = shift;

    my @values = $self->{_data}->y_values($ds) or
        return $self->_set_error("Impossible illegal data set: $ds",
            $self->{_data}->error);

    my $dsci = $self->set_clr($self->pick_data_clr($ds) );
    my $type = $self->pick_line_type($ds);

    my ($xb, $yb);
    if (defined $values[0])
    {
        if (defined($self->{x_min_value}) && defined($self->{x_max_value}))
        {
            ($xb, $yb) =
                $self->val_to_pixel($self->{_data}->get_x(0), $values[0], $ds);
        }
        else    
        {
            ($xb, $yb) = $self->val_to_pixel(1, $values[0], $ds);
        }
    }

    for (my $i = 0; $i < @values; $i++)
    {
        if (!defined $values[$i])
        {
            ($xb, $yb) = () if $self->{skip_undef};
            next;
        }

        my ($xe, $ye);

        if (defined($self->{x_min_value}) && defined($self->{x_max_value}))
        {
            ($xe, $ye) = $self->val_to_pixel(
                $self->{_data}->get_x($i), $values[$i], $ds);
        }
        else
        {
            ($xe, $ye) = $self->val_to_pixel($i+1, $values[$i], $ds);
        }

        if (defined $xb)
        {
            $self->draw_line($xb, $yb, $xe, $ye, $type, $dsci)
                if defined $dsci;
            $self->{_hotspots}->[$ds]->[$i] = 
                ['line', $xb, $yb, $xe, $ye, $self->{line_width}];
        }
        ($xb, $yb) = ($xe, $ye);
   }

   return $ds;
}

sub pick_line_type
{
    my $self = shift;
    my $num = shift;

    ref $self->{line_types} ?
        $self->{line_types}[ $num % (1 + $#{$self->{line_types}}) - 1 ] :
        $num % 4 ? $num % 4 : 4
}

sub draw_line # ($xs, $ys, $xe, $ye, $type, $colour_index)
{
    my $self = shift;
    my ($xs, $ys, $xe, $ye, $type, $clr) = @_;

    my $lw = $self->{line_width};
    my $lts = $self->{line_type_scale};

    my $style = gdStyled;
    my @pattern = ();

    LINE: {

        ($type == 2) && do {
            # dashed

            for (1 .. $lts) { push @pattern, $clr }
            for (1 .. $lts) { push @pattern, gdTransparent }

            $self->{graph}->setStyle(@pattern);

            last LINE;
        };

        ($type == 3) && do {
            # dotted,

            for (1 .. 2) { push @pattern, $clr }
            for (1 .. 2) { push @pattern, gdTransparent }

            $self->{graph}->setStyle(@pattern);

            last LINE;
        };

        ($type == 4) && do {
            # dashed and dotted

            for (1 .. $lts) { push @pattern, $clr }
            for (1 .. 2)    { push @pattern, gdTransparent }
            for (1 .. 2)    { push @pattern, $clr }
            for (1 .. 2)    { push @pattern, gdTransparent }

            $self->{graph}->setStyle(@pattern);

            last LINE;
        };

        # default: solid
        $style = $clr;
    }

    # Tried the line_width thing with setBrush, ugly results
    # TODO: This loop probably should be around the datasets 
    # for nicer results
    my $i;
    for $i (1..$lw)
    {
        my $yslw = $ys + int($lw/2) - $i;
        my $yelw = $ye + int($lw/2) - $i;

        # Need the setstyle to reset 
        $self->{graph}->setStyle(@pattern) if (@pattern);
        $self->{graph}->line( $xs, $yslw, $xe, $yelw, $style );
    }
}

sub draw_legend_marker # (data_set_number, x, y)
{
    my $self = shift;
    my ($n, $x, $y) = @_;

    my $ci = $self->set_clr($self->pick_data_clr($n));
    return unless defined $ci;
    my $type = $self->pick_line_type($n);

    $y += int($self->{lg_el_height}/2);

    #  Joe Smith <jms@tardis.Tymnet.COM>
    local($self->{line_width}) = 2;    # Make these show up better

    $self->draw_line(
        $x, $y, 
        $x + $self->{legend_marker_width}, $y,
        $type, $ci
    );
}

"Just another true value";
