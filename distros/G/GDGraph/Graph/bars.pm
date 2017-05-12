#==========================================================================
#              Copyright (c) 1995-1998 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::bars.pm
#
# $Id: bars.pm,v 1.26 2007/04/26 03:16:09 ben Exp $
#
#==========================================================================
 
package GD::Graph::bars;

($GD::Graph::bars::VERSION) = '$Revision: 1.26 $' =~ /\s([\d.]+)/;

use strict;

use GD::Graph::axestype;
use GD::Graph::utils qw(:all);
use GD::Graph::colour qw(:colours);

@GD::Graph::bars::ISA = qw(GD::Graph::axestype);

use constant PI => 4 * atan2(1,1);

sub initialise
{
    my $self = shift;
    $self->SUPER::initialise();
    $self->set(correct_width => 1);
}

sub draw_data
{
    my $self = shift;

    $self->SUPER::draw_data() or return;

    unless ($self->{no_axes})
    {
        # redraw the 'zero' axis
        if ($self->{rotate_chart})
        {
            $self->{graph}->line( 
                $self->{zeropoint}, $self->{top},
                $self->{zeropoint}, $self->{bottom},
                $self->{fgci} );
        }
        else
        {
            $self->{graph}->line( 
                $self->{left}, $self->{zeropoint}, 
                $self->{right}, $self->{zeropoint}, 
                $self->{fgci} );
        }
    }
    
    return $self;
}

sub _top_values
{
    my $self = shift;
    my @topvalues;

    if ($self->{cumulate})
    {
        my $data = $self->{_data};
        for my $i (0 .. $data->num_points - 1)
        {
            push @topvalues, $data->get_y_cumulative($data->num_sets, $i);
        }
    }

    return \@topvalues;
}

#
# Draw the shadow
#
sub _draw_shadow
{
    my $self = shift;
    my ($ds, $i, $value, $topvalues, $l, $t, $r, $b) = @_;
    my $bsd = $self->{shadow_depth} or return;
    my $bsci = $self->set_clr(_rgb($self->{shadowclr}));

    if ($self->{cumulate})
    {
        return if $ds > 1;
        $value = $topvalues->[$i];
        if ($self->{rotate_chart})
        {
            $r = ($self->val_to_pixel($i + 1, $value, $ds))[0];
        }
        else
        {
            $t = ($self->val_to_pixel($i + 1, $value, $ds))[1];
        }
    }

    # XXX Clean this up
    if ($value >= 0)
    {
        if ($self->{rotate_chart})
        {
            $self->{graph}->filledRectangle(
                $l, $t + $bsd, $r - $bsd, $b + $bsd, $bsci);
        }
        else
        {
            $self->{graph}->filledRectangle(
                $l + $bsd, $t + $bsd, $r + $bsd, $b, $bsci);
        }
    }
    else
    {
        if ($self->{rotate_chart})
        {
            $self->{graph}->filledRectangle(
                $l + $bsd, $t, $r + $bsd, $b, $bsci);
        }
        else
        {
            $self->{graph}->filledRectangle(
                $l + $bsd, $b, $r + $bsd, $t + $bsd, $bsci);
        }
    }
}

sub draw_data_set_h
{
    my $self = shift;
    my $ds = shift;

    my $bar_s = $self->{bar_spacing}/2;

    # Pick a data colour
    my $dsci = $self->set_clr($self->pick_data_clr($ds));
    # contrib "Bremford, Mike" <mike.bremford@gs.com>
    my $brci = $self->set_clr($self->pick_border_clr($ds));

    my @values = $self->{_data}->y_values($ds) or
        return $self->_set_error("Impossible illegal data set: $ds",
            $self->{_data}->error);

    my $topvalues = $self->_top_values;
    #
    # Draw all shadows.
    for my $i (0 .. $#values) 
    {
        my $value = $values[$i];
        next unless defined $value;

        my $l = $self->_get_bottom($ds, $i);
        my ($r, $xp) = $self->val_to_pixel($i + 1, $value, $ds);

        # calculate top and bottom of bar
        my ($t, $b);
        my $window = $self->{x_step} - $self->{bargroup_spacing};

        if (ref $self eq 'GD::Graph::mixed' || $self->{overwrite})
        {
            $t = $xp - $window/2 + $bar_s + 1;
            $b = $xp + $window/2 - $bar_s;
        }
        else
        {
            $t = $xp 
                - $window/2
                + ($ds - 1) * $window/$self->{_data}->num_sets
                + $bar_s + 1; # GRANTM thinks this +1 should be conditional on bargroup_spacing being absent
            $b = $xp 
                - $window/2
                + $ds * $window/$self->{_data}->num_sets
                - $bar_s;
        }

        $self->_draw_shadow($ds, $i, $value, $topvalues, $l, $t, $r, $b);
    }

    for my $i (0 .. $#values) 
    {
        my $value = $values[$i];
        next unless defined $value;

        my $l = $self->_get_bottom($ds, $i);
        $value = $self->{_data}->get_y_cumulative($ds, $i)
            if ($self->{cumulate});

        # CONTRIB Jeremy Wadsack
        #
        # cycle_clrs option sets the color based on the point, 
        # not the dataset.
        $dsci = $self->set_clr($self->pick_data_clr($i + 1))
            if $self->{cycle_clrs};
        $brci = $self->set_clr($self->pick_data_clr($i + 1))
            if $self->{cycle_clrs} > 1;

        # get coordinates of right and center of bar
        my ($r, $xp) = $self->val_to_pixel($i + 1, $value, $ds);

        # calculate top and bottom of bar
        my ($t, $b);
        my $window = $self->{x_step} - $self->{bargroup_spacing};

        if (ref $self eq 'GD::Graph::mixed' || $self->{overwrite})
        {
            $t = $xp - $window/2 + $bar_s + 1;
            $b = $xp + $window/2 - $bar_s;
        }
        else
        {
            $t = $xp 
                - $window/2
                + ($ds - 1) * $window/$self->{_data}->num_sets
                + $bar_s + 1; # GRANTM thinks this +1 should be conditional on bargroup_spacing being absent
            $b = $xp 
                - $window/2
                + $ds * $window/$self->{_data}->num_sets
                - $bar_s;
        }

        # draw the bar
        if ($value < 0) { ($r,$l) = ($l,$r) } 

        $self->{graph}->filledRectangle($l, $t, $r, $b, $dsci)
            if defined $dsci;
        $self->{graph}->rectangle($l, $t, $r, $b, $brci) 
               if defined $brci && $b - $t > $self->{accent_treshold};

        $self->{_hotspots}->[$ds]->[$i] = ['rect', $l, $t, $r, $b];
    }

    return $ds;
}

sub draw_data_set_v
{
    my $self = shift;
    my $ds = shift;

    my $bar_s = $self->{bar_spacing}/2;

    # Pick a data colour
    my $dsci = $self->set_clr($self->pick_data_clr($ds));
    # contrib "Bremford, Mike" <mike.bremford@gs.com>
    my $brci = $self->set_clr($self->pick_border_clr($ds));

    my @values = $self->{_data}->y_values($ds) or
        return $self->_set_error("Impossible illegal data set: $ds",
            $self->{_data}->error);

    my $topvalues = $self->_top_values;

    my ($bar_sets,$ds_adj) = ( $self->{_data}->num_sets , $ds );
    if ( $self->isa( 'GD::Graph::mixed' ) ) {
        my @types =  $self->types;
        $bar_sets =  grep { $_  eq 'bars' } @types;
        $ds_adj   =  grep { $_  eq 'bars' } @types[0..$ds-1];
    }

    # Draw all shadows.
    for my $i (0 .. $#values) 
    {
        my $value = $values[$i];
        next unless defined $value;

        my $bottom = $self->_get_bottom($ds, $i);
        my ($xp, $t) = $self->val_to_pixel($i + 1, $value, $ds);
        my ($l, $r);
        my $window = $self->{x_step} - $self->{bargroup_spacing};

        if ($self->{overwrite})
        {
            $l = $xp - $window/2 + $bar_s + 1;
            $r = $xp + $window/2 - $bar_s;
        }
        else
        {
            $l = $xp 
                - $window/2
                + ($ds_adj - 1) * $window/$bar_sets
                + $bar_s + 1; # GRANTM thinks this +1 should be conditional on bargroup_spacing being absent
            $r = $xp 
                - $window/2
                + $ds_adj * $window/$bar_sets
                - $bar_s;
        }

        $self->_draw_shadow($ds, $i, $value, $topvalues, $l, $t, $r, $bottom);
    }

    # Then all bars.
    for my $i (0 .. $#values) 
    {
        my $value = $values[$i];
        next unless defined $value;

        my $bottom = $self->_get_bottom($ds, $i);
        $value = $self->{_data}->get_y_cumulative($ds, $i)
            if ($self->{cumulate});

        # CONTRIB Jeremy Wadsack
        #
        # cycle_clrs option sets the color based on the point, 
        # not the dataset.
        $dsci = $self->set_clr($self->pick_data_clr($i + 1))
            if $self->{cycle_clrs};
        $brci = $self->set_clr($self->pick_data_clr($i + 1))
            if $self->{cycle_clrs} > 1;

        # get coordinates of top and center of bar
        my ($xp, $t) = $self->val_to_pixel($i + 1, $value, $ds);

        # calculate left and right of bar
        my ($l, $r);
        my $window = $self->{x_step} - $self->{bargroup_spacing};

        if ($self->{overwrite})
        {
            $l = $xp - $window/2 + $bar_s + 1;
            $r = $xp + $window/2 - $bar_s;
        }
        else
        {
            $l = $xp 
                - $window/2
                + ($ds_adj - 1) * $window/$bar_sets
                + $bar_s + 1; # GRANTM thinks this +1 should be conditional on bargroup_spacing being absent
            $r = $xp 
                - $window/2
                + $ds_adj * $window/$bar_sets
                - $bar_s;
        }

        # draw the bar

        if ($value < 0) { ($bottom,$t) = ($t,$bottom) } 
        $self->{graph}->filledRectangle($l, $t, $r, $bottom, $dsci)
            if defined $dsci;
        $self->{graph}->rectangle($l, $t, $r, $bottom, $brci) 
            if defined $brci && $r - $l > $self->{accent_treshold};
        $self->{_hotspots}->[$ds]->[$i] = ['rect', $l, $t, $r, $bottom]
    }

    return $ds;
}

sub draw_data_set
{
    $_[0]->{rotate_chart} ? goto &draw_data_set_h : goto &draw_data_set_v;
}

sub draw_values
{
    my $self = shift;

    return $self unless $self->{show_values};
    my $has_args = @_;
    
    my $text_angle = $self->{values_vertical} ? PI/2 : 0;
    my @numPoints = $self->{_data}->num_points();
    my @datasets = $has_args ? @_ : 1 .. $self->{_data}->num_sets;

    my ($l, $r, $b, $t) = ($self->{left}, $self->{right}, $self->{bottom}, $self->{top});

    for my $dsn ( @datasets )
    {   # CONTRIB Romeo Juncu
        my @values = ();
        if (!$self->get("cumulate")) {
          @values = $self->{_data}->y_values($dsn) or
            return $self->_set_error("Impossible illegal data set: $dsn",
                $self->{_data}->error);
        } else {
          my $nPoints = $numPoints[$dsn] || 0;
          my $vec = $has_args ? \@datasets : undef;
          @values = map { $self->{_data}->get_y_cumulative($dsn, $_, $vec) }
            (0..$nPoints - 1) ;
        }
        my @display = $self->{show_values}->y_values($dsn) or next;

        for (my $i = 0; $i < @values; $i++)
        {
            next unless defined $display[$i];

            my $value = $display[$i];
            if (defined $self->{values_format})
            {
                $value = ref $self->{values_format} eq 'CODE' ?
                    &{$self->{values_format}}($value) :
                    sprintf($self->{values_format}, $value);
            }

            my ($xp, $yp);
            if (defined($self->{x_min_value}) && defined($self->{x_max_value}))
            {
                ($xp, $yp) = $self->val_to_pixel(
                    $self->{_data}->get_x($i), $values[$i], $dsn);
            }
            else    
            {
                ($xp, $yp) = $self->val_to_pixel($i+1, $values[$i], $dsn);
            }
            if ($self->{rotate_chart})
            {
                $xp += $self->{values_space};
                unless ($self->{overwrite})
                {
                    $yp -= $self->{x_step}/2 - ($dsn - 0.5) 
                        * $self->{x_step}/@datasets;
                }
            }
            else
            {
                $yp -= $self->{values_space};
                unless ($self->{overwrite})
                {
                    $xp -= $self->{x_step}/2 - ($dsn - 0.5) 
                        * $self->{x_step}/@datasets;
                }
            }

            $self->{gdta_values}->set_text($value);
            if ( $self->{'hide_overlapping_values'} ) {
                my @bbox = $self->{gdta_values}->bounding_box($xp, $yp, $text_angle);
                next if grep $_ < $l || $_ > $r, @bbox[0, 2];
                next if grep $_ < $t || $_ > $b, @bbox[1, 5];
            }
            $self->{gdta_values}->draw($xp, $yp, $text_angle);
        }
    }

    return $self
}

"Just another true value";
