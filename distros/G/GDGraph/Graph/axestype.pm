#==========================================================================
#              Copyright (c) 1995-1998 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::axestype.pm
#
# $Id: axestype.pm,v 1.45 2007/04/26 03:16:09 ben Exp $
#
#==========================================================================

package GD::Graph::axestype;

($GD::Graph::axestype::VERSION) = '$Revision: 1.45 $' =~ /\s([\d.]+)/;

use strict;
 
use GD::Graph;
use GD::Graph::utils qw(:all);
use Carp;

@GD::Graph::axestype::ISA = qw(GD::Graph);

use constant PI => 4 * atan2(1,1);

my %Defaults = (
 
    # Set the length for the 'short' ticks on the axes.
    x_tick_length           => 4,
    y_tick_length           => 4,
 
    # Do you want ticks to span the entire width of the graph?
    x_long_ticks            => 0,
    y_long_ticks            => 0,
 
    # Number of ticks for the y axis
    y_tick_number       => 5,
    x_tick_number       => undef,       # CONTRIB Scott Prahl
    x_tick_offset       => 0,           # CONTRIB Damon Brodi
 
    # Skip every nth label. if 1 will print every label on the axes,
    # if 2 will print every second, etc..
    x_label_skip        => 1,
    y_label_skip        => 1,

    # When skipping labels, also skip the last one.
    x_last_label_skip	=> 0,

    # Do we want ticks on the x axis?
    x_ticks             => 1,
    x_all_ticks         => 0,

    # Where to place the x and y labels
    x_label_position    => 3/4,
    y_label_position    => 1/2,

    # vertical printing of x labels
    x_labels_vertical   => 0,
 
    # Draw axes as a box? (otherwise just left and bottom)
    box_axis            => 1,

    # Disable axes?
    # undef -> all axes, 0 -> Only line for bars, other -> no axes at all.
    no_axes             => undef,
 
    # Use two different axes for the first and second dataset. The first
    # will be displayed using the left axis, the second using the right
    # axis. You cannot use more than two datasets when this option is on.
    two_axes            => 0,

    # Which axis to use for each dataset. This only is in effect when
    # two_axes is true. The axis number will wrap around, just like
    # the dclrs array.
    use_axis            => [1, 2],
 
    # Print values on the axes?
    x_plot_values       => 1,
    y_plot_values       => 1,
 
    # Space between axis and text
    axis_space          => 4,
 
    # Do you want bars to be drawn on top of each other, or side by side?
    overwrite           => 0,

    # This will replace 'overwrite = 2'. For now, it is hardcoded to set
    # overwrite to 2
    cumulate            => 0,

    # Do you want me to correct the width of the graph, so that bars are
    # always drawn with a nice integer number of pixels?
    #
    # The GD::Graph::bars::initialise sub will switch this on.
    # Do not set this to anything else than undef!
    correct_width       => undef,

    # XXX The following two need to get better defaults. Maybe computed.
    # Draw the zero axis in the graph in case there are negative values
    zero_axis           =>  0,

    # Draw the zero axis, but do not draw the bottom axis, in case
    # box-axis == 0
    # This also moves the x axis labels to the zero axis
    zero_axis_only      =>  0,

    # Size of the legend markers
    legend_marker_height    => 8,
    legend_marker_width     => 12,
    legend_spacing          => 4,
    legend_placement        => 'BC',        # '[BR][LCR]'
    lg_cols                 => undef,

    # Display the y values above the bar or point in the graph.
    show_values             => undef,
    hide_overlapping_values => 0,
    values_vertical         => undef,   # vertical?
    values_space            => 4,       # extra spacing
    values_format           => undef,   # how to format the value
    
    # Draw the X axis left and the y1 axis at the bottom (y2 at top)
    rotate_chart            => undef,

    # CONTRIB Edwin Hildebrand
    # How narrow is a dataset allowed to become before we drop the
    # accents?
    accent_treshold         => 4,

    # Format of the numbers on the x and y axis
    y_number_format         => undef,
    y1_number_format        => undef,       # CONTRIB Andrew OBrien
    y2_number_format        => undef,       # CONTRIB Andrew OBrien
    x_number_format         => undef,       # CONTRIB Scott Prahl

    # and some attributes without default values
    x_label         => undef,
    y_label         => undef,
    y1_label        => undef,
    y2_label        => undef,
    x_min_value     => undef,
    x_max_value     => undef,
    y_min_value     => undef,
    y1_min_value    => undef,
    y2_min_value    => undef,
    y_max_value     => undef,
    y1_max_value    => undef,
    y2_max_value    => undef,
    y_min_range     => undef,               # CONTRIB Ben Tilly
    y1_min_range     => undef,
    y2_min_range     => undef,

    borderclrs      => undef,

    # XXX
    # Multiple inheritance (linespoints and mixed) finally bit me. The
    # _has_defaults and set methods can only work correctly when the
    # spot where the defaults are kept are in a mutual parent, which
    # would be this. The odd implementation of SUPER doesn't help

    # XXX points
    # The size of the marker to use in the points and linespoints graphs
    # in pixels
    marker_size => 4,

    # attributes with no default
    markers => undef,

    # XXX lines
    # The width of the line to use in the lines and linespoints graphs
    # in pixels
    line_width      => 1,

    # Set the scale of the line types
    line_type_scale => 8,

    # Which line types to use
    line_types      => [1],

    # Skip undefined values, and don't draw them at all
    skip_undef      => 0,

    # XXX bars
    # Spacing between the bars and groups of bars
    bar_width       => undef,
    bar_spacing     => 0,
    bargroup_spacing=> 0,                   # CONTRIB Grant McLean

    # cycle through colours per data point, not set
    cycle_clrs      => 0,

    # colour of the shadow
    shadowclr       => 'dgray',
    shadow_depth    => 0,

    # XXX mixed
    default_type    => 'lines',
    types           => undef,
);

sub _has_default { 
    my $self = shift;
    my $attr = shift || return;
    exists $Defaults{$attr} || $self->SUPER::_has_default($attr);
}

sub initialise
{
    my $self = shift;

    $self->SUPER::initialise();

    while (my($key, $val) = each %Defaults) 
        { $self->{$key} = $val }

    $self->set_x_label_font(GD::gdSmallFont);
    $self->set_y_label_font(GD::gdSmallFont);
    $self->set_x_axis_font(GD::gdTinyFont);
    $self->set_y_axis_font(GD::gdTinyFont);
    $self->set_legend_font(GD::gdTinyFont);
    $self->set_values_font(GD::gdTinyFont);
}

# PUBLIC
sub plot
{
    my $self = shift;
    my $data = shift;

    $self->check_data($data)            or return;
    $self->init_graph()                 or return;
    $self->setup_text()                 or return;
    $self->setup_legend();
    $self->setup_coords()               or return;
    $self->draw_text();
    unless (defined $self->{no_axes})
    {
        $self->draw_axes();
        $self->draw_ticks()             or return;
    }
    $self->draw_data()                  or return;
    $self->draw_values()                or return;
    $self->draw_legend();

    return $self->{graph}
}

sub set
{
    my $self = shift;
    my %args = @_;

    for (keys %args) 
    { 
        /^tick_length$/ and do 
        {
            $self->{x_tick_length} = 
            $self->{y_tick_length} = $args{$_};
            delete $args{$_};
            next;
        };
        /^long_ticks$/ and do 
        {
            $self->{x_long_ticks} = 
            $self->{y_long_ticks} = $args{$_};
            delete $args{$_};
            next;
        };
        /^overwrite$/ and do
        {
            $self->{cumulate} = 1 if $args{$_} == 2;
            $self->{overwrite} = $args{$_};
            delete $args{$_};
            next;
        };
        /^cumulate$/ and do
        {
            $self->{cumulate} = $args{$_};
            # XXX And for now
            $self->{overwrite} = 2 if $args{$_};
            delete $args{$_};
            next;
        };
    }

    return $self->SUPER::set(%args);
}

sub setup_text
{
    my $self = shift;

    $self->{gdta_x_label}->set(colour => $self->{lci});
    $self->{gdta_y_label}->set(colour => $self->{lci});
    $self->{xlfh} = $self->{gdta_x_label}->get('height');
    $self->{ylfh} = $self->{gdta_y_label}->get('height');

    $self->{gdta_x_axis}->set(colour => $self->{alci});
    $self->{gdta_y_axis}->set(colour => $self->{alci});
    $self->{xafh} = $self->{gdta_x_axis}->get('height');
    $self->{yafh} = $self->{gdta_x_axis}->get('height');

    $self->{gdta_title}->set(colour => $self->{tci});
    $self->{gdta_title}->set_align('top', 'center');
    $self->{tfh} = $self->{gdta_title}->get('height');

    $self->{gdta_legend}->set(colour => $self->{legendci});
    $self->{gdta_legend}->set_align('top', 'left');
    $self->{lgfh} = $self->{gdta_legend}->get('height');

    $self->{gdta_values}->set(colour => $self->{valuesci});
    unless ($self->{rotate_chart})
    {
        if ($self->{values_vertical})
        {
            $self->{gdta_values}->set_align('center', 'left');
        }
        else
        {
            $self->{gdta_values}->set_align('bottom', 'center');
        }
    }
    else
    {
        if ($self->{values_vertical})
        {
            $self->{gdta_values}->set_align('top', 'center');
        }
        else
        {
            $self->{gdta_values}->set_align('center', 'left');
        }
    }

    return $self;
}

sub set_x_label_font # (fontname)
{
    my $self = shift;
    $self->_set_font('gdta_x_label', @_);
}
sub set_y_label_font # (fontname)
{
    my $self = shift;
    $self->_set_font('gdta_y_label', @_);
}
sub set_x_axis_font # (fontname)
{
    my $self = shift;
    $self->_set_font('gdta_x_axis', @_);
}

sub set_y_axis_font # (fontname)
{
    my $self = shift;
    $self->_set_font('gdta_y_axis', @_);
}

sub set_values_font
{
    my $self = shift;
    $self->_set_font('gdta_values', @_);
}

sub set_legend # List of legend keys
{
    my $self = shift;
    $self->{legend} = [@_];
}

sub set_legend_font # (font name)
{
    my $self = shift;
    $self->_set_font('gdta_legend', @_);
}

sub get_hotspot
{
    my $self = shift;
    my $ds = shift;     # Which data set
    my $np = shift;     # Which data point?

    if (defined $np && defined $ds)
    {
        return @{$self->{_hotspots}->[$ds]->[$np]};
    }
    elsif (defined $ds)
    {
        return @{$self->{_hotspots}->[$ds]};
    }
    else
    {
        return @{$self->{_hotspots}};
    }
}

sub _set_feature_coords
{
    my $self = shift;
    my $feature = shift;
    my $type = shift;
    $self->{_feat_coords}->{$feature} = [ $type, @_ ];
}

sub _set_text_feature_coords
{
    my $self = shift;
    my $feature = shift;
    $self->_set_feature_coords($feature, "rect", @_[0,1,4,5]);
}

sub get_feature_coordinates
{
    my $self = shift;
    my $feature = shift;
    if ($feature)
    {
        $self->{_feat_coords}->{$feature};
    }
    else
    {
        $self->{_feat_coords};
    }
}

# PRIVATE

# inherit check_data from GD::Graph

#
# calculate the bottom of the bounding box for the graph
#
sub setup_bottom_boundary
{
    my $self = shift;
    $self->{bottom} = $self->{height} - $self->{b_margin} - 1;
    if (! $self->{rotate_chart})
    {
        # X label
        $self->{bottom} -= $self->{xlfh} + $self->{text_space}
            if $self->{xlfh};
        # X axis tick labels
        $self->{bottom} -= $self->{x_label_height} + $self->{axis_space}
            if $self->{xafh};
    }
    else
    {
        # Y1 label
        $self->{bottom} -= $self->{ylfh} + $self->{text_space}
            if $self->{y1_label};
        # Y1 axis labels
        $self->{bottom} -= $self->{y_label_height}[1] + $self->{axis_space}
            if $self->{y_label_height}[1];
    }
}
#
# Calculate the top of the bounding box for the graph
#
sub setup_top_boundary
{
    my $self = shift;

    $self->{top} = $self->{t_margin};
    # Chart title
    $self->{top} += $self->{tfh} + $self->{text_space} if $self->{tfh};
    if (! $self->{rotate_chart})
    {
        # Make sure the text for the y axis tick markers fits on the canvas
        $self->{top} = $self->{yafh}/2 if $self->{top} == 0;
    }
    else
    {
        if ($self->{two_axes})
        {
            # Y2 label
            $self->{top} += $self->{ylfh} + $self->{text_space}
                if $self->{y2_label};
            # Y2 axis labels
            $self->{top} += $self->{y_label_height}[2] + $self->{axis_space}
                if $self->{y_label_height}[2];
        }
    }
}
#
# calculate the left of the bounding box for the graph
#
sub setup_left_boundary
{
    my $self = shift;

    $self->{left} = $self->{l_margin};
    if (! $self->{rotate_chart})
    {
        # Y1 label
        $self->{left} += $self->{ylfh} + $self->{text_space}
            if $self->{y1_label};
        # Y1 axis labels
        $self->{left} += $self->{y_label_len}[1] + $self->{axis_space}
            if $self->{y_label_len}[1];
    }
    else
    {
        # X label
        $self->{left} += $self->{xlfh} + $self->{text_space}
            if $self->{x_label};
        # X axis labels
        $self->{left} += $self->{x_label_width} + $self->{axis_space}
            if $self->{x_label_width};
    }
}
#
# calculate the right of the bounding box for the graph
#
sub setup_right_boundary
{
    my $self = shift;
    $self->{right} = $self->{width} - $self->{r_margin} - 1;

    if (! $self->{rotate_chart})
    {
        if ($self->{two_axes})
        {
            # Y2 label
            $self->{right} -= $self->{ylfh} + $self->{text_space}
                if $self->{y2_label};
            # Y2 axis label
            $self->{right} -= $self->{y_label_len}[2] + $self->{axis_space}
                if $self->{y_label_len}[2];
        }
    }
    else
    {
        # Adjust right margin to allow last label of y axes. Only do
        # this when the right margin doesn't have enough space
        # already.
        #
        # TODO Don't assume rightmost label is the same as the
        # longest label (stored in y_label_len) The worst that can
        # happen now is that we reserve too much space.
    
        my $max_len = $self->{y_label_len}[1];
        if ($self->{two_axes})
        {
            $max_len = $self->{y_label_len}[2] if 
            $self->{y_label_len}[2] > $max_len;
        }
        $max_len = int ($max_len/2);
    
        if ($self->{right} + $max_len >= $self->{width} - $self->{r_margin})
        {
            $self->{right} -= $max_len;
        }
    }
}

sub _setup_boundaries
{
    my $self = shift;

    $self->setup_bottom_boundary();
    $self->setup_top_boundary();
    $self->setup_left_boundary();
    $self->setup_right_boundary();

    if ($self->correct_width && !$self->{x_tick_number})
    {
        if (! $self->{rotate_chart})
        {
            # Make sure we have a nice integer number of pixels
            $self->{r_margin} += ($self->{right} - $self->{left}) %
                ($self->{_data}->num_points + 1);
            
            $self->setup_right_boundary();
        }
        else
        {
            # Make sure we have a nice integer number of pixels
            $self->{b_margin} += ($self->{bottom} - $self->{top}) %
                ($self->{_data}->num_points + 1);
            
            $self->setup_bottom_boundary();
        }
    }

    return $self->_set_error('Vertical size too small')
        if $self->{bottom} <= $self->{top};
    return $self->_set_error('Horizontal size too small')   
        if $self->{right} <= $self->{left};

    return $self;
}

# This method should return 1 if the width of the graph needs to be
# corrected to whole integers, and 0 if not. The default behaviour is to
# not correct the width. Individual classes should override this by
# setting the $self->{correct_width} attribute in their initialise
# method. Only in complex cases (see mixed.pm) should this method be
# overridden
sub correct_width { $_[0]->{correct_width} }

sub setup_x_step_size_v
{
    my $s = shift;

    # calculate the step size for x data
    # CONTRIB Changes by Scott Prahl
    if (defined $s->{x_tick_number})
    {
        my $delta = ($s->{right} - $s->{left})/($s->{x_max} - $s->{x_min});
        # 'True' numerical X axis addition # From: Gary Deschaines
        if (defined($s->{x_min_value}) && defined($s->{x_max_value}))
        {
            $s->{x_offset} = $s->{left};
            $s->{x_step} = $delta;
        }
        else
        {
            $s->{x_offset} = 
                ($s->{true_x_min} - $s->{x_min}) * $delta + $s->{left};
            $s->{x_step} = 
                ($s->{true_x_max} - $s->{true_x_min}) * 
                $delta/($s->{_data}->num_points - 1);
        }
    }
    else
    {
        $s->{x_step} = ($s->{right} - $s->{left})/($s->{_data}->num_points + 1);
        $s->{x_offset} = $s->{left};
    }
}

sub setup_x_step_size_h
{
    my $s = shift;

    # calculate the step size for x data
    # CONTRIB Changes by Scott Prahl
    if (defined $s->{x_tick_number})
    {
        my $delta = ($s->{bottom} - $s->{top})/($s->{x_max} - $s->{x_min});
        # 'True' numerical X axis addition # From: Gary Deschaines
        if (defined($s->{x_min_value}) && defined($s->{x_max_value}))
        {
            $s->{x_offset} = $s->{top};
            $s->{x_step} = $delta;
        }
        else
        {
            $s->{x_offset} = 
                ($s->{true_x_min} - $s->{x_min}) * $delta + $s->{top};
            $s->{x_step} = 
                ($s->{true_x_max} - $s->{true_x_min}) * 
                $delta/($s->{_data}->num_points - 1);
        }
    }
    else
    {
        $s->{x_step} = ($s->{bottom} - $s->{top})/($s->{_data}->num_points + 1);
        $s->{x_offset} = $s->{top};
    }
}

sub setup_coords
{
    my $s = shift;

    # Do some sanity checks
    $s->{two_axes} = 0 if $s->{_data}->num_sets < 2 || $s->{two_axes} < 0;
    $s->{two_axes} = 1 if $s->{two_axes} > 1;

    delete $s->{y_label2} unless $s->{two_axes};

    # Set some heights for text
    $s->{tfh}  = 0 unless $s->{title};
    $s->{xlfh} = 0 unless $s->{x_label};

    # Make sure the y1 axis has a label if there is one set for y in
    # general
    $s->{y1_label} = $s->{y_label} if !$s->{y1_label} && $s->{y_label};

    # Set axis tick text heights and widths to 0 if they don't need to
    # be plotted.
    $s->{xafh} = 0, $s->{xafw} = 0 unless $s->{x_plot_values}; 
    $s->{yafh} = 0, $s->{yafw} = 0 unless $s->{y_plot_values};

    # Calculate minima and maxima for the axes
    $s->set_max_min() or return;

    # Create the labels for the axes, and calculate the max length
    $s->create_y_labels();
    $s->create_x_labels(); # CONTRIB Scott Prahl

    # Calculate the boundaries of the chart
    $s->_setup_boundaries() or return;

    # CONTRIB Scott Prahl
    # make sure that we can generate valid x tick marks
    undef($s->{x_tick_number}) if $s->{_data}->num_points < 3;
    undef($s->{x_tick_number}) if
        !defined $s->{x_max} || 
        !defined $s->{x_min} || 
        $s->{x_max} == $s->{x_min};

    $s->{rotate_chart} ? $s->setup_x_step_size_h() :
                         $s->setup_x_step_size_v();

    # get the zero axis level
    my ($zl, $zb) = $s->val_to_pixel(0, 0, 1);
    my ($min,$val,$max) = $s->{rotate_chart} 
        ? ( $s->{left}, $zl, $s->{right} )
        : ( $s->{top}, $zb, $s->{bottom} );
    
    $s->{zeropoint} = $min > $val ? $min : $max < $val ? $max : $val;

    # More sanity checks
    $s->{x_label_skip} = 1      if $s->{x_label_skip}  < 1;
    $s->{y_label_skip} = 1      if $s->{y_label_skip}  < 1;
    $s->{y_tick_number} = 1     if $s->{y_tick_number} < 1;

    return $s;
}

sub create_y_labels
{
    my $self = shift;

    # XXX This should really be y_label_width
    $self->{y_label_len}[$_]    = 0 for 1, 2;
    $self->{y_label_height}[$_] = 0 for 1, 2;

    for my $t (0 .. $self->{y_tick_number})
    {
        # XXX Ugh, why did I ever do it this way? How bloody obscure.
        for my $axis (1 .. ($self->{two_axes} + 1))
        {
            my $label = $self->{y_min}[$axis] +
                $t * ($self->{y_max}[$axis] - $self->{y_min}[$axis]) /
                $self->{y_tick_number};
            
            $self->{y_values}[$axis][$t] = $label;

            if (my ($fmt) = grep defined, map($self->{"y${_}_number_format"},$axis,'') )
            {
                $label = ref $fmt eq 'CODE' ?
                    $fmt->($label) :
                    sprintf($fmt, $label);
            }
            
            $self->{gdta_y_axis}->set_text($label);
            my $len = $self->{gdta_y_axis}->get('width');

            $self->{y_labels}[$axis][$t] = $label;

            # TODO Allow vertical y labels
            $self->{y_label_len}[$axis] = $len 
                if $len > $self->{y_label_len}[$axis];
            $self->{y_label_height}[$axis] = $self->{yafh};
        }
    }
}

sub get_x_axis_label_length
{
    my $self = shift;

    my @values = $self->{x_tick_number} ? 
        @{$self->{x_values}} : 
        $self->{_data}->x_values;

    my $maxlen = 0;
    foreach my $label (@values)
    {
        $self->{gdta_x_axis}->set_text($label);
        my $len = $self->{gdta_x_axis}->get('width');
        $maxlen = $len if $maxlen < $len;
    }

    return $maxlen;
}

# CONTRIB Scott Prahl
sub create_x_labels
{
    my $self = shift;
    my $maxlen = 0;

    $self->{x_label_height} = 0;
    $self->{x_label_width} = 0;

    if (defined $self->{x_tick_number})
    {
        # We want to emulate numerical x axes
        foreach my $t (0..$self->{x_tick_number})
        {
            my $label =
                $self->{x_min} +
                $t * ($self->{x_max} - $self->{x_min})/$self->{x_tick_number};

            $self->{x_values}[$t] = $label;

            if (defined $self->{x_number_format})
            {
                $label = ref $self->{x_number_format} eq 'CODE' ?
                    &{$self->{x_number_format}}($label) :
                    sprintf($self->{x_number_format}, $label);
            }

            $self->{gdta_x_label}->set_text($label);
            my $len = $self->{gdta_x_label}->get('width');

            $self->{x_labels}[$t] = $label;
            $maxlen = $len 
                if $len > $self->{x_label_height};
        }
    }
    else
    {
        $maxlen = $self->get_x_axis_label_length;
    }

    $self->{x_label_height} = $self->{x_labels_vertical} ?
        $maxlen : $self->{xafh};
    $self->{x_label_width} = $self->{x_labels_vertical} ?
        $self->{xafh} : $maxlen;
}

#
# The drawing of labels for the axes. This is split up in the four
# positions a label can appear in, depending on a few settings. These
# settings are all dealt with in the draw_x_labels and draw_y_labels
# subroutines, which in turn call the appropriate directional label
# drawer
#
sub draw_left_label
{
    my ($self, $label, $align) = @_;

    $label->set_align('top', 'left');
    my $tx = $self->{l_margin};
    my $ty = $self->{bottom} - $align * ($self->{bottom} - $self->{top}) + 
        $align * $label->get('width');
    $label->draw($tx, $ty, PI/2);
}

sub draw_bottom_label
{
    my ($self, $label, $align) = @_;

    $label->set_align('bottom', 'left');
    my $tx = $self->{left} + $align * ($self->{right} - $self->{left}) - 
        $align * $label->get('width');
    my $ty = $self->{height} - $self->{b_margin};
    $label->draw($tx, $ty, 0);
}

sub draw_top_label
{
    my ($self, $label, $align) = @_;

    $label->set_align('top', 'left');
    my $tx = $self->{left} + $align * ($self->{right} - $self->{left}) - 
        $align * $label->get('width');
    my $ty = $self->{t_margin};
    $ty += $self->{tfh} + $self->{text_space} if $self->{tfh};
    $label->draw($tx, $ty, 0);
}

sub draw_right_label
{
    my ($self, $label, $align) = @_;

    $label->set_align('bottom', 'left');
    my $tx = $self->{width} - $self->{r_margin};
    my $ty = $self->{bottom} - $align * ($self->{bottom} - $self->{top}) + 
        $align * $label->get('width');
    $label->draw($tx, $ty, PI/2);
}

sub draw_x_label
{
    my $self = shift;
    my ($tx, $ty, $a);

    my @coords; # coordinates of the label drawn

    return unless $self->{x_label};

    $self->{gdta_x_label}->set_text($self->{x_label});
    if ($self->{rotate_chart})
    {
        @coords = $self->draw_left_label($self->{gdta_x_label}, 
                               $self->{x_label_position});
    }
    else
    {
        @coords = $self->draw_bottom_label($self->{gdta_x_label}, 
                               $self->{x_label_position});
    }
    $self->_set_text_feature_coords("x_label", @coords);
}

sub draw_y_labels
{
    my $self = shift;

    my @coords; # coordinates of the labels drawn

    if (defined $self->{y1_label}) 
    {
        $self->{gdta_y_label}->set_text($self->{y1_label});
        if ($self->{rotate_chart})
        {
            @coords = $self->draw_bottom_label($self->{gdta_y_label}, 
                                     $self->{y_label_position});
        }
        else
        {
            @coords = $self->draw_left_label($self->{gdta_y_label}, 
                                   $self->{y_label_position});
        }
        $self->_set_text_feature_coords("y1_label", @coords);
        $self->_set_text_feature_coords("y_label", @coords);
    }
    if ( $self->{two_axes} && defined $self->{y2_label} ) 
    {
        $self->{gdta_y_label}->set_text($self->{y2_label});
        if ($self->{rotate_chart})
        {
            @coords = $self->draw_top_label($self->{gdta_y_label}, 
                                  $self->{y_label_position});
        }
        else
        {
            @coords = $self->draw_right_label($self->{gdta_y_label}, 
                                    $self->{y_label_position});
        }
        $self->_set_text_feature_coords("y2_label", @coords);
    }
}

sub draw_text
{
    my $self = shift;

    if ($self->{title})
    {
        my $xc = $self->{left} + ($self->{right} - $self->{left})/2;
        $self->{gdta_title}->set_align('top', 'center');
        $self->{gdta_title}->set_text($self->{title});
        my @coords = $self->{gdta_title}->draw($xc, $self->{t_margin});
        $self->_set_text_feature_coords("title", @coords);
    }

    $self->draw_x_label();
    $self->draw_y_labels();
}

sub draw_axes
{
    my $self = shift;

    my ($l, $r, $b, $t) = 
        ( $self->{left}, $self->{right}, $self->{bottom}, $self->{top} );
    
    # Sanity check for zero_axis and zero_axis_only
    unless ($self->{y_min}[1] < 0 && $self->{y_max}[1] > 0)
    {
        $self->{zero_axis} = 0;
        $self->{zero_axis_only} = 0;
    }

    if ( $self->{box_axis} ) 
    {
        $self->{graph}->filledRectangle($l+1, $t+1, $r-1, $b-1, $self->{boxci})
            if $self->{boxci};

        $self->{graph}->rectangle($l, $t, $r, $b, $self->{fgci});
    }
    else
    {
        $self->{graph}->line($l, $t, $l, $b, $self->{fgci});
        $self->{graph}->line($l, $b, $r, $b, $self->{fgci}) 
            unless ($self->{zero_axis_only});
        $self->{graph}->line($r, $b, $r, $t, $self->{fgci}) 
            if ($self->{two_axes});
    }

    if ($self->{zero_axis} or $self->{zero_axis_only})
    {
        my ($x, $y) = $self->val_to_pixel(0, 0, 1);
        $self->{graph}->line($l, $y, $r, $y, $self->{fgci});
    }

    $self->_set_feature_coords("axes", "rect", $l, $b, $r, $t);
}

#
# Ticks and values for y axes
#
sub draw_y_ticks_h
{
    my $self = shift;

    for my $t (0 .. $self->{y_tick_number}) 
    {
        for my $axis (1 .. ($self->{two_axes} + 1)) 
        {
            my $value = $self->{y_values}[$axis][$t];
            my $label = $self->{y_labels}[$axis][$t];
            
            my ($x, $y) = $self->val_to_pixel(0, $value, -$axis);
            $y = ($axis == 1) ? $self->{bottom} : $self->{top};
            
            if ($self->{y_long_ticks}) 
            {
                $self->{graph}->line( 
                    $x, $self->{bottom}, 
                    $x, $self->{top}, 
                    $self->{fgci} 
                ) unless ($axis-1);
            } 
            else 
            {
                $self->{graph}->line( 
                    $x, $y, 
                    $x, $y  - $self->{y_tick_length}, 
                    $self->{fgci} 
                );
            }

            next 
                if $t % ($self->{y_label_skip}) || ! $self->{y_plot_values};

            $self->{gdta_y_axis}->set_text($label);
            if ($axis == 1)
            {
                $self->{gdta_y_axis}->set_align('top', 'center');
                $y += $self->{axis_space};
            }
            else
            {
                $self->{gdta_y_axis}->set_align('bottom', 'center');
                $y -= $self->{axis_space};
            }
            $self->{gdta_y_axis}->draw($x, $y);
        }
    }

    return $self;
}

sub draw_y_ticks_v
{
    my $self = shift;

    for my $t (0 .. $self->{y_tick_number}) 
    {
        # XXX Ugh, why did I ever do it this way? How bloody obscure.
        for my $axis (1 .. ($self->{two_axes} + 1)) 
        {
            my $value = $self->{y_values}[$axis][$t];
            my $label = $self->{y_labels}[$axis][$t];
            
            my ($x, $y) = $self->val_to_pixel(0, $value, -$axis);
            $x = ($axis == 1) ? $self->{left} : $self->{right};

            if ($self->{y_long_ticks}) 
            {
                $self->{graph}->line( 
                    $x, $y, 
                    $x + $self->{right} - $self->{left}, $y, 
                    $self->{fgci} 
                ) unless ($axis-1);
            } 
            else 
            {
                $self->{graph}->line( 
                    $x, $y, 
                    $x + (3 - 2 * $axis) * $self->{y_tick_length}, $y, 
                    $self->{fgci} 
                );
            }

            next 
                if $t % ($self->{y_label_skip}) || ! $self->{y_plot_values};

            $self->{gdta_y_axis}->set_text($label);
            if ($axis == 1)
            {
                $self->{gdta_y_axis}->set_align('center', 'right');
                $x -= $self->{axis_space};
            }
            else
            {
                $self->{gdta_y_axis}->set_align('center', 'left');
                $x += $self->{axis_space};
            }
            $self->{gdta_y_axis}->draw($x, $y);
        }
    }

    return $self;
}

sub draw_y_ticks
{
    #TODO Clean this up!
    $_[0]->{rotate_chart} ? goto &draw_y_ticks_h : goto &draw_y_ticks_v;
}


#
# Ticks and values for x axes
#
sub draw_x_ticks_h
{
    my $self = shift;

    for (my $i = 0; $i < $self->{_data}->num_points; $i++) 
    {
        my ($x, $y) = $self->val_to_pixel($i + 1, 0, 1);

        $x = $self->{left} unless $self->{zero_axis_only};

	# Skip unwanted axis ticks
        next unless 
	    $self->{x_all_ticks} or 
	    ($i - $self->{x_tick_offset}) % $self->{x_label_skip} == 0 or
	    $i == $self->{_data}->num_points - 1 && !$self->{x_last_label_skip};

	# Draw the tick on the X axis
        if ($self->{x_ticks})
        {
            if ($self->{x_long_ticks})
            {
                $self->{graph}->line($self->{left}, $y, $self->{right}, $y, 
                    $self->{fgci});
            }
            else
            {
                $self->{graph}->line( $x, $y, $x + $self->{x_tick_length}, $y,
                    $self->{fgci});
            }
        }

	# Skip unwanted axis tick labels.
        next unless 
	    ($i - $self->{x_tick_offset}) % $self->{x_label_skip} == 0 or
	    $i == $self->{_data}->num_points - 1 && !$self->{x_last_label_skip};

        my $text = $self->{_data}->get_x($i);
        if (defined $text)
        {
            $self->{gdta_x_axis}->set_text($text);

	# Draw the tick label
            my $angle = 0;
            if ($self->{x_labels_vertical})
            {
                $self->{gdta_x_axis}->set_align('bottom', 'center');
                $angle = PI/2;
            }
            else
            {
                $self->{gdta_x_axis}->set_align('center', 'right');
            }
            $self->{gdta_x_axis}->draw($x - $self->{axis_space}, $y, $angle);
        } 
        elsif ($INC{'warnings.pm'} && warnings::enabled('uninitialized') || $^W ) 
        {
            carp("Uninitialized label value at index $i");
        }
    }

    return $self;
}

sub draw_x_ticks_v
{
    my $self = shift;

    for (my $i = 0; $i < $self->{_data}->num_points; $i++) 
    {
        my ($x, $y) = $self->val_to_pixel($i + 1, 0, 1);

        $y = $self->{bottom} unless $self->{zero_axis_only};

	# Skip unwanted axis ticks
        next unless 
	    $self->{x_all_ticks} or 
	    ($i - $self->{x_tick_offset}) % $self->{x_label_skip} == 0 or
	    $i == $self->{_data}->num_points - 1 && !$self->{x_last_label_skip};

        if ($self->{x_ticks})
        {
            if ($self->{x_long_ticks})
            {
                $self->{graph}->line($x, $self->{bottom}, $x, $self->{top},
                    $self->{fgci});
            }
            else
            {
                $self->{graph}->line($x, $y, $x, $y - $self->{x_tick_length},
                    $self->{fgci});
            }
        }

	# Skip unwanted axis tick labels.
        next unless 
	    ($i - $self->{x_tick_offset}) % $self->{x_label_skip} == 0 or
	    $i == $self->{_data}->num_points - 1 && !$self->{x_last_label_skip};

        my $text = $self->{_data}->get_x($i);
        if (defined $text)
        {
            $self->{gdta_x_axis}->set_text($text);

            my $angle = 0;
            if ($self->{x_labels_vertical})
            {
                $self->{gdta_x_axis}->set_align('center', 'right');
                $angle = PI/2;
            }
            else
            {
                $self->{gdta_x_axis}->set_align('top', 'center');
            }
            $self->{gdta_x_axis}->draw($x, $y + $self->{axis_space}, $angle);
        } 
        elsif ($INC{'warnings.pm'} && warnings::enabled('uninitialized') || $^W ) 
        {
            carp("Uninitialized label value at index $i");
        }
    }

    return $self;
}

sub draw_x_ticks
{
    #TODO Clean this up!
    $_[0]->{rotate_chart} ? goto &draw_x_ticks_h : goto &draw_x_ticks_v;
}

# CONTRIB Scott Prahl
# Assume x array contains equally spaced x-values
# and generate an appropriate axis
#
####
# 'True' numerical X axis addition 
# From: Gary Deschaines
#
# These modification to draw_x_ticks_number pass x-tick values to the
# val_to_pixel subroutine instead of x-tick indices when ture numerical
# x-axis mode is detected.  Also, x_tick_offset and x_label_skip are
# processed differently when true numerical x-axis mode is detected to
# allow labeled major x-tick marks and un-labeled minor x-tick marks.
#
# For example:
#
#      x_tick_number =>  14,
#      x_ticks       =>   1,
#      x_long_ticks  =>   1,
#      x_tick_length =>  -4,
#      x_min_value   => 100,
#      x_max_value   => 800,
#      x_tick_offset =>   2,
#      x_label_skip  =>   2,
#
#
#      ~         ~    ~    ~    ~    ~    ~    ~    ~    ~    ~    ~         ~
#      |         |    |    |    |    |    |    |    |    |    |    |         |
#   1 -|         |    |    |    |    |    |    |    |    |    |    |         |
#      |         |    |    |    |    |    |    |    |    |    |    |         |
#   0 _|_________|____|____|____|____|____|____|____|____|____|____|_________|
#                |    |    |    |    |    |    |    |    |    |    |
#               200       300       400       500       600       700
sub draw_x_ticks_number
{
    my $self = shift;

    for my $i (0 .. $self->{x_tick_number})
    {
        my ($value, $x, $y);

        if (defined($self->{x_min_value}) && defined($self->{x_max_value}))
        {
            next if ($i - $self->{x_tick_offset}) < 0;
            next if ($i + $self->{x_tick_offset}) > $self->{x_tick_number};
            $value = $self->{x_values}[$i];
            ($x, $y) = $self->val_to_pixel($value, 0, 1);
        }
        else
        {
            $value = ($self->{_data}->num_points - 1)
                        * ($self->{x_values}[$i] - $self->{true_x_min})
                        / ($self->{true_x_max} - $self->{true_x_min});
            ($x, $y) = $self->val_to_pixel($value + 1, 0, 1);
        }

        $y = $self->{bottom} unless $self->{zero_axis_only};

        if ($self->{x_ticks})
        {
            if ($self->{x_long_ticks})
            {
                # XXX This mod needs to be done everywhere ticks are
                # drawn
                if ( $self->{x_tick_length} >= 0 ) 
                {
                    $self->{graph}->line($x, $self->{bottom}, 
                        $x, $self->{top}, $self->{fgci});
                } 
                else 
                {
                    $self->{graph}->line(
                        $x, $self->{bottom} - $self->{x_tick_length}, 
                        $x, $self->{top}, $self->{fgci});
                }
            }
            else
            {
                $self->{graph}->line($x, $y, 
                    $x, $y - $self->{x_tick_length}, $self->{fgci} );
            }
        }

        # If we have to skip labels, we'll do it here.
        # Make sure to always draw the last one.
        next if $i % $self->{x_label_skip} and
		    $i != $self->{_data}->num_points - 1;

        $self->{gdta_x_axis}->set_text($self->{x_labels}[$i]);

        if ($self->{x_labels_vertical})
        {
            $self->{gdta_x_axis}->set_align('center', 'right');
            my $yt = $y + $self->{text_space}/2;
            $self->{gdta_x_axis}->draw($x, $yt, PI/2);
        }
        else
        {
            $self->{gdta_x_axis}->set_align('top', 'center');
            my $yt = $y + $self->{text_space}/2;
            $self->{gdta_x_axis}->draw($x, $yt);
        }
    }

    return $self;
}

sub draw_ticks
{
    my $self = shift;

    $self->draw_y_ticks() or return;

    return $self 
        unless $self->{x_plot_values};

    if (defined $self->{x_tick_number})
    {
        $self->draw_x_ticks_number() or return;
    }
    else
    {
        $self->draw_x_ticks() or return;
    }

    return $self;
}

sub draw_data
{
    my $self = shift;

    # Calculate bar_spacing from bar_width
    if ($self->{bar_width})
    {
        my $chart_width = !$self->{rotate_chart} ? 
            $self->{right} - $self->{left} :
            $self->{bottom} - $self->{top};
        my $n_bars = $self->{_data}->num_points;
        my $n_sets = $self->{_data}->num_sets;
        my $bar_space = $chart_width/($n_bars + 1) /
            ($self->{overwrite} ? 1 : $n_sets);
        $self->{bar_spacing} = $bar_space - $self->{bar_width};
        $self->{bar_spacing} = 0 if $self->{bar_spacing} < 0;
    }

    # XXX is this comment still pertinent?
    # The drawing of 'cumulated' sets needs to be done in reverse,
    # for area and bar charts. This is mainly because of backward
    # compatibility

    for (my $dsn = 1; $dsn <= $self->{_data}->num_sets; $dsn++)
    {
        $self->draw_data_set($dsn) or return;
    }

    return $self
}

#
# Draw the values of the data point with the bars, lines or markers
sub draw_values
{
    my $self = shift;
    
    return $self unless $self->{show_values};
    
    my $text_angle = $self->{values_vertical} ? PI/2 : 0;
    my (@bars,@others);

    if ($self->isa('GD::Graph::mixed') ) {
        # 1-indexed, like data-sets themselves
        my @types = $self->types;
        push @{'bars' eq $types[$_ - 1] ? \@bars : \@others}, $_ for 1 .. @types;
        $self->GD::Graph::bars::draw_values(@bars) if @bars;
    } else { 
        @others = 1 .. $self->{_data}->num_sets;
    }   

    foreach my $dsn ( @others )
    {
        my @values = $self->{_data}->y_values($dsn) or
                return $self->_set_error("Impossible illegal data set: $dsn",
                    $self->{_data}->error);
        my @display = $self->{show_values}->y_values($dsn) or next;

        for (my $i = 0; $i < @values; $i++)
        {
            next unless defined $display[$i];
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
            $yp -= $self->{values_space};

            my $value = $display[$i];
            if (defined $self->{values_format})
            {
                $value = ref $self->{values_format} eq 'CODE' ?
                    &{$self->{values_format}}($value) :
                    sprintf($self->{values_format}, $value);
            }

            $self->{gdta_values}->set_text($value);
            $self->{gdta_values}->draw($xp, $yp, $text_angle);
        }
    }

    return $self
}

#
# draw_data_set is in sub classes
#
sub draw_data_set
{
    # ABSTRACT
    my $self = shift;
    $self->die_abstract( "sub draw_data missing, ")
}

#
# This method corrects the minimum and maximum y values for chart
# types that need to always include a zero point.
# This is supposed to be called before the methods that pick
# good-looking values.
#
# Input: current minimum and maximum.
# Output: new minimum and maximum.
#
sub _correct_y_min_max
{
    my $self = shift;
    my ($min, $max) = @_;

    # Make sure bars and area always have a zero offset
    # Only bars and areas need 
    return ($min, $max)
        unless $self->isa("GD::Graph::bars") or $self->isa("GD::Graph::area");

    # If either $min or $max are 0, we can return
    return ($min, $max) if $max == 0 or $min == 0;

    # If $min and $max on opposite end of zero axis, no work needed
    return ($min, $max) unless $min/$max > 0;

    if ($min > 0)
    {
        $min = 0;
    }
    else
    {
        $max = 0;
    }

    return ($min, $max);
}

#
# Figure out the maximum values for the vertical exes, and calculate
# a more or less sensible number for the tops.
#
sub set_max_min
{
    my $self = shift;

    # XXX fix to calculate min and max for each data set
    # independently, and store in an array. Then, based on use_axis,
    # pick the minimust and maximust for each axis, and use those.

    # First, calculate some decent values
    if ( $self->{two_axes} ) 
    {
        my $min_range_1 = defined($self->{y1_min_range})
                ? $self->{y1_min_range}
                : $self->{y_min_range};
        my $min_range_2 = defined($self->{y2_min_range})
                ? $self->{y2_min_range}
                : $self->{y_min_range};

        my(@y_min, @y_max);
        for my $nd (1 .. $self->{_data}->num_sets)
        {
            my $axis = $self->{use_axis}->[$nd - 1];
            my($y_min, $y_max) = $self->{_data}->get_min_max_y($nd);
            if (!defined $y_min[$axis] || $y_min[$axis] > $y_min)
            {
                $y_min[$axis] = $y_min;
            }
            if (!defined $y_max[$axis] || $y_max[$axis] < $y_max)
            {
                $y_max[$axis] = $y_max;
            }
        }

        (
            $self->{y_min}[1], $self->{y_max}[1],
            $self->{y_min}[2], $self->{y_max}[2],
            $self->{y_tick_number}
        ) = _best_dual_ends(
            $self->_correct_y_min_max($y_min[1], $y_max[1]),
              $min_range_1,
            $self->_correct_y_min_max($y_min[2], $y_max[2]),
              $min_range_2,
            $self->{y_tick_number}
        );
    } 
    else 
    {
        my ($y_min, $y_max);
        if ($self->{cumulate})
        {
            my $data_set = $self->{_data}->copy();
            $data_set->cumulate;
            ($y_min, $y_max) = $data_set->get_min_max_y($data_set->num_sets);
        }
        else
        {
            ($y_min, $y_max) = $self->{_data}->get_min_max_y_all;
        }
        ($y_min, $y_max) = $self->_correct_y_min_max($y_min, $y_max);
        ($self->{y_min}[1], $self->{y_max}[1], $self->{y_tick_number}) =
            _best_ends($y_min, $y_max, @$self{'y_tick_number','y_min_range'});
    }

    if (defined($self->{x_tick_number}))
    {
        if (defined($self->{x_min_value}) && defined($self->{x_max_value}))
        {
            $self->{true_x_min} = $self->{x_min_value};
            $self->{true_x_max} = $self->{x_max_value};
        }
        else
        {
            ($self->{true_x_min}, $self->{true_x_max}) = 
                $self->{_data}->get_min_max_x;
        }
        ($self->{x_min}, $self->{x_max}, $self->{x_tick_number}) =
            _best_ends($self->{true_x_min}, $self->{true_x_max},
                    @$self{'x_tick_number','x_min_range'});
    }

    # Overwrite these with any user supplied ones
    $self->{y_min}[1] = $self->{y_min_value}  if defined $self->{y_min_value};
    $self->{y_min}[2] = $self->{y_min_value}  if defined $self->{y_min_value};

    $self->{y_max}[1] = $self->{y_max_value}  if defined $self->{y_max_value};
    $self->{y_max}[2] = $self->{y_max_value}  if defined $self->{y_max_value};

    $self->{y_min}[1] = $self->{y1_min_value} if defined $self->{y1_min_value};
    $self->{y_max}[1] = $self->{y1_max_value} if defined $self->{y1_max_value};

    $self->{y_min}[2] = $self->{y2_min_value} if defined $self->{y2_min_value};
    $self->{y_max}[2] = $self->{y2_max_value} if defined $self->{y2_max_value};

    $self->{x_min}    = $self->{x_min_value}  if defined $self->{x_min_value};
    $self->{x_max}    = $self->{x_max_value}  if defined $self->{x_max_value};

    if (
        $self->{two_axes} && !defined $self->{y1_min_value} && !defined $self->{y2_min_value}
        && !defined $self->{y1_max_value} && !defined $self->{y2_max_value}
    )
    {
        # If we have two axes, we need to make sure that the zero is at
        # the same spot.
        # And we need to change the number of ticks on the axes

        my $l_range = $self->{y_max}[1] - $self->{y_min}[1];
        my $r_range = $self->{y_max}[2] - $self->{y_min}[2];

        my $l_top = $self->{y_max}[1]/$l_range;
        my $r_top = $self->{y_max}[2]/$r_range;
        my $l_bot = $self->{y_min}[1]/$l_range;
        my $r_bot = $self->{y_min}[2]/$r_range;

        if ($l_top > $r_top)
        {
            $self->{y_max}[2] = $l_top * $r_range;
            $self->{y_min}[1] = $r_bot * $l_range;
            $self->{y_tick_number} *= 1 + abs $r_bot - $l_bot;
        }
        else
        {
            $self->{y_max}[1] = $r_top * $l_range;
            $self->{y_min}[2] = $l_bot * $r_range;
            $self->{y_tick_number} *= 1 + abs $r_top - $l_top;
        }
    }

    # Check to see if we have sensible values
    if ($self->{two_axes}) 
    {
        for my $i (1 .. $self->{_data}->num_sets)
        {
            my ($min, $max) = $self->{_data}->get_min_max_y($i);
            return $self->_set_error("Minimum for y" . $i . " too large")
                if $self->{y_min}[$self->{use_axis}[$i-1]] > $min;
            return $self->_set_error("Maximum for y" . $i . " too small")
                if $self->{y_max}[$self->{use_axis}[$i-1]] < $max;
        }
    } 

    return $self;
}

# CONTRIB Scott Prahl
#
# Calculate best endpoints and number of intervals for an axis and
# returns ($nice_min, $nice_max, $n), where $n is the number of
# intervals and
#
#    $nice_min <= $min < $max <= $nice_max
#
# Usage:
#       ($nmin,$nmax,$nint) = _best_ends(247, 508);
#       ($nmin,$nmax) = _best_ends(247, 508, 5); 
#           use 5 intervals
#       ($nmin,$nmax,$nint) = _best_ends(247, 508, [4..7]);   
#           best of 4,5,6,7 intervals
#       ($nmin,$nmax,$nint) = _best_ends(247, 508, 'auto');
#           best of 3,4,5,6 intervals
#       ($nmin,$nmax,$nint) = _best_ends(247, 508, [2..5]);
#           best of 2,3,4,5 intervals
sub _best_ends 
{
    my ($min, $max, $n_ref, $min_range) = @_;

    # Adjust for the min range if need be
    ($min, $max) = _fit_vals_range($min, $max, $min_range);

    my ($best_min, $best_max, $best_num) = ($min, $max, 1);

    # Check that min and max are not the same, and not 0
    ($min, $max) = ($min) ? ($min * 0.5, $min * 1.5) : (-1,1)
        if ($max == $min);
    
    # mgjv - Sometimes, for odd values, and only one data set, this will be
    # necessary _after_ the previous step, not before. Data sets of one
    # long with negative values were causing infinite loops later on.
    ($min, $max) = ($max, $min) if ($min > $max);

    my @n = ref($n_ref) ? @$n_ref : $n_ref;

    if (@n <= 0)
    {
        @n = (3..6);
    }
    else
    {
        @n = map { ref($_) ? @$_ : /(\d+)/i ? $1 : (3..6) } @n;
    }

    my $best_fit = 1e30;
    my $range = $max - $min;

    # create array of interval sizes
    my $s = 1;
    while ($s < $range) { $s *= 10 }
    while ($s > $range) { $s /= 10 }
    my @step = map {$_ * $s} (0.2, 0.5, 1, 2, 5);

    for my $n (@n) 
    {                               
        # Try all numbers of intervals
        next if ($n < 1);

        for my $step (@step) 
        {
            next if ($n != 1) and ($step < $range/$n) || ($step <= 0); 
            # $step too small

            my ($nice_min, $nice_max, $fit)
                    = _fit_interval($min, $max, $n, $step);

            next if $best_fit <= $fit;

            $best_min = $nice_min;
            $best_max = $nice_max;
            $best_fit = $fit;
            $best_num = $n;
        }
    }
    return ($best_min, $best_max, $best_num)
}

# CONTRIB Ben Tilly
#
# Calculate best endpoints and number of intervals for a pair of axes
# where it is trying to line up the scale of the two intervals.  It
# returns ($nice_min_1, $nice_max_1, $nice_min_2, $nice_max_2, $n),
# where $n is the number of intervals and
#
#    $nice_min_1 <= $min_1 < $max_1 <= $nice_max_1
#    $nice_min_2 <= $min_2 < $max_2 <= $nice_max_2
#
# and 0 will appear at the same point on both axes.
#
# Usage:
#       ($nmin_1,$nmax_1,$nmin_2,$nmax_2,$nint) = _best_dual_ends(247, 508, undef, -1, 5, undef, [2..5]);
# etc.  (The usage of the last arguments just parallels _best_ends.)
#
sub _best_dual_ends
{
    my ($min_1, $max_1) = _fit_vals_range(splice @_, 0, 3);
    my ($min_2, $max_2) = _fit_vals_range(splice @_, 0, 3);
    my @rem_args = @_;

    # Fix the situation where both min_1 and max_1 are 0, which makes it
    # loop forever
    ($min_1, $max_1) = (0, 1) unless $min_1 or $max_1;

    my $scale_1 = _max(abs($min_1), abs($max_1));
    my $scale_2 = _max(abs($min_2), abs($max_2));

    $scale_1 = defined($scale_2) ? $scale_2 : 1 unless defined($scale_1);
    $scale_2 = $scale_1 unless defined($scale_2);

    my $ratio = $scale_1 / ($scale_2 || 1);
    my $fact_1 = my $fact_2 = 1;

    while ($ratio < sqrt(0.1))
    {
        $ratio *= 10;
        $fact_2 *= 10;
    }
    while ($ratio > sqrt(10))
    {
        $ratio /= 10;
        $fact_1 *= 10;
    }

    my ($best_min_1, $best_max_1, $best_min_2, $best_max_2, $best_n, $best_fit)
            = ($min_1, $max_1, $min_2, $max_2, 1, 1e10);

    # Now try all of the ratios of "simple numbers" in the right size-range
    foreach my $frac
    (
        [1,1], [1,2], [1,3], [2,1], [2,3], [2,5],
        [3,1], [3,2], [3,4], [3,5], [3,8], [3,10],
        [4,3], [4,5], [5,2], [5,3], [5,4], [5,6],
        [5,8], [6,5], [8,3], [8,5], [10,3]
    )
    {
        my $bfact_1 = $frac->[0] * $fact_1;
        my $bfact_2 = $frac->[1] * $fact_2;

        my $min = _min( $min_1/$bfact_1, $min_2/$bfact_2 );
        my $max = _max( $max_1/$bfact_1, $max_2/$bfact_2 );

        my ($bmin, $bmax, $n) = _best_ends($min, $max, @rem_args);
        my ($bmin_1, $bmax_1) = ($bfact_1*$bmin, $bfact_1*$bmax);
        my ($bmin_2, $bmax_2) = ($bfact_2*$bmin, $bfact_2*$bmax);

        my $fit = _measure_interval_fit($bmin_1, $min_1, $max_1, $bmax_1)
                + _measure_interval_fit($bmin_2, $min_2, $max_2, $bmax_2);

        next if $best_fit < $fit;

        (
            $best_min_1, $best_max_1, $best_min_2, $best_max_2, 
            $best_n,     $best_fit
        ) = (
            $bmin_1,     $bmax_1,     $bmin_2,     $bmax_2,
            $n,          $fit
        );
    }

    return ($best_min_1, $best_max_1, $best_min_2, $best_max_2, $best_n);
}

# Takes $min, $max, $step_count, $step_size.  Assumes $min <= $max and both
# $step_count and $step_size are positive.  Returns the fitted $min, $max,
# and a $fit statistic (where smaller is better).  Failure to fit the
# interval results in a poor fit statistic. :-)
sub _fit_interval
{
    my ($min, $max, $step_count, $step_size) = @_;

    my $nice_min = $step_size * int($min/$step_size);
    $nice_min  -= $step_size if ($nice_min > $min);
    my $nice_max   = ($step_count == 1)
            ? $step_size * int($max/$step_size + 1)
            : $nice_min + $step_count * $step_size;

    my $fit = _measure_interval_fit($nice_min, $min, $max, $nice_max);

    # Prevent division by zero errors further up
    return ($min, $max, 0) if ($step_size == 0);
    return ($nice_min, $nice_max, $fit);
}

# Takes 2 values and a minimum range.  Returns a min and max which holds
# both values and is at least that minimum size
sub _fit_vals_range
{
    my ($min, $max, $min_range) = @_;

    ($min, $max) = ($max, $min) if $max < $min;

    if (defined($min_range) and $min_range > $max - $min)
    {
        my $nice_min = $min_range * int($min/$min_range);
        $nice_min = $nice_min - $min_range if $min < $nice_min;
        my $nice_max = $max < $nice_min + $min_range
                ? $nice_min + $min_range
                : $max;
        ($min, $max) = ($nice_min, $nice_max);
    }
    return (0+$min, 0+$max);
}

# Takes $bmin, $min, $max, $bmax and returns a fit statistic for how well
# ($bmin, $bmax) encloses the interval ($min, $max).  Smaller is better,
# and failure to fit will be a very bad fit.  Assumes that $min <= $max
# and $bmin < $bmax.
sub _measure_interval_fit
{
    my ($bmin, $min, $max, $bmax) = @_;
    return 1000 if $bmin > $min or $bmax < $max;

    my $range = $max - $min;
    my $brange = $bmax - $bmin;

    return $brange < 10 * $range
            ? ($brange / $range)
            : 10;
 }

sub _get_bottom
{
    my $self = shift;
    my ($ds, $np) = @_;
    my $bottom = $self->{zeropoint};

    if ($self->{cumulate} && $ds > 1)
    {
        my $left;
        my $pvalue = $self->{_data}->get_y_cumulative($ds - 1, $np);
        ($left, $bottom) = $self->val_to_pixel($np + 1, $pvalue, $ds);
        $bottom = $left if $self->{rotate_chart};
    }

    return $bottom;
}

#
# Convert value coordinates to pixel coordinates on the canvas.
# TODO Clean up all the rotate_chart stuff
#
sub val_to_pixel    # ($x, $y, $dataset) or ($x, $y, -$axis) in real coords
{                   # return [x, y] in pixel coords
    my $self = shift;
    my ($x, $y, $i) = @_;

    # XXX use_axis
    my $axis = 1;
    if ( $self->{two_axes} ) {
        $axis = $i < 0 ? -$i : $self->{use_axis}[$i - 1];
    }
    
    my $y_min = $self->{y_min}[$axis];
    my $y_max = $self->{y_max}[$axis];
    my $y_range = ($y_max - $y_min) || 1; 
    # XXX the above might be an appropriate place for a conditional warning

    my $y_step = $self->{rotate_chart} ?
        abs(($self->{right} - $self->{left}) / $y_range) :
        abs(($self->{bottom} - $self->{top}) / $y_range);

    my $ret_x;
    my $origin = $self->{rotate_chart} ? $self->{top} : $self->{left};

    if (defined($self->{x_min_value}) && defined($self->{x_max_value}))
    {
        $ret_x = $origin + ($x - $self->{x_min}) * $self->{x_step};
    }
    else
    {
        $ret_x = ($self->{x_tick_number} ? $self->{x_offset} : $origin) 
            + $x * $self->{x_step};
    }
    my $ret_y = $self->{rotate_chart} ? 
        $self->{left} + ($y - $y_min) * $y_step :
        $self->{bottom} - ($y - $y_min) * $y_step;

    return $self->{rotate_chart} ?
        (_round($ret_y), _round($ret_x)) :
        (_round($ret_x), _round($ret_y));
}

#
# Legend
#
sub setup_legend
{
    my $self = shift;

    return unless defined $self->{legend};

    my $maxlen = 0;
    my $num = 0;

    # Save some variables
    $self->{r_margin_abs} = $self->{r_margin};
    $self->{b_margin_abs} = $self->{b_margin};

    foreach my $legend (@{$self->{legend}})
    {
        if (defined($legend) and $legend ne "")
        {
            $self->{gdta_legend}->set_text($legend);
            my $len = $self->{gdta_legend}->get('width');
            $maxlen = ($maxlen > $len) ? $maxlen : $len;
            $num++;
        }
        last if $num >= $self->{_data}->num_sets;
    }

    $self->{lg_num} = $num or return; 
    # not actually bug 20792 (unsure that this will ever get hit, but if it does..!)

    # calculate the height and width of each element
    my $legend_height = _max($self->{lgfh}, $self->{legend_marker_height});

    $self->{lg_el_width} = 
        $maxlen + $self->{legend_marker_width} + 3 * $self->{legend_spacing};
    $self->{lg_el_height} = $legend_height + 2 * $self->{legend_spacing};

    my ($lg_pos, $lg_align) = split(//, $self->{legend_placement});

    if ($lg_pos eq 'R')
    {
        # Always work in one column
        $self->{lg_cols} = 1;
        $self->{lg_rows} = $num;

        # Just for completeness, might use this in later versions
        $self->{lg_x_size} = $self->{lg_cols} * $self->{lg_el_width};
        $self->{lg_y_size} = $self->{lg_rows} * $self->{lg_el_height};

        # Adjust the right margin for the rest of the graph
        $self->{r_margin} += $self->{lg_x_size};

        # Set the x starting point
        $self->{lg_xs} = $self->{width} - $self->{r_margin};

        # Set the y starting point, depending on alignment
        if ($lg_align eq 'T')
        {
            $self->{lg_ys} = $self->{t_margin};
        }
        elsif ($lg_align eq 'B')
        {
            $self->{lg_ys} = $self->{height} - $self->{b_margin} - 
                $self->{lg_y_size};
        }
        else # default 'C'
        {
            my $height = $self->{height} - $self->{t_margin} - 
                $self->{b_margin};

            $self->{lg_ys} = 
                int($self->{t_margin} + $height/2 - $self->{lg_y_size}/2) ;
        }
    }
    else # 'B' is the default
    {
        # What width can we use
        my $width = $self->{width} - $self->{l_margin} - $self->{r_margin};

        (!defined($self->{lg_cols})) and 
            $self->{lg_cols} = int($width/$self->{lg_el_width}) || 1; # bug 20792
        
        $self->{lg_cols} = _min($self->{lg_cols}, $num);

        $self->{lg_rows} = 
            int($num / $self->{lg_cols}) + (($num % $self->{lg_cols}) ? 1 : 0);

        $self->{lg_x_size} = $self->{lg_cols} * $self->{lg_el_width};
        $self->{lg_y_size} = $self->{lg_rows} * $self->{lg_el_height};

        # Adjust the bottom margin for the rest of the graph
        $self->{b_margin} += $self->{lg_y_size};

        # Set the y starting point
        $self->{lg_ys} = $self->{height} - $self->{b_margin};

        # Set the x starting point, depending on alignment
        if ($lg_align eq 'R')
        {
            $self->{lg_xs} = $self->{width} - $self->{r_margin} - 
                $self->{lg_x_size};
        }
        elsif ($lg_align eq 'L')
        {
            $self->{lg_xs} = $self->{l_margin};
        }
        else # default 'C'
        {
            $self->{lg_xs} =  
                int($self->{l_margin} + $width/2 - $self->{lg_x_size}/2);
        }
    }
}

sub draw_legend
{
    my $self = shift;

    return unless defined $self->{legend};

    my $xl = $self->{lg_xs} + $self->{legend_spacing};
    my $y  = $self->{lg_ys} + $self->{legend_spacing} - 1;
    
    my $i = 0;
    my $row = 1;
    my $x = $xl;    # start position of current element

    foreach my $legend (@{$self->{legend}})
    {
        $i++;
        last if $i > $self->{_data}->num_sets;

        my $xe = $x;    # position within an element

        next unless defined($legend) && $legend ne "";

        $self->draw_legend_marker($i, $xe, $y);

        $xe += $self->{legend_marker_width} + $self->{legend_spacing};
        my $ys = int($y + $self->{lg_el_height}/2 - $self->{lgfh}/2);

        $self->{gdta_legend}->set_text($legend);
        $self->{gdta_legend}->draw($xe, $ys);

        $x += $self->{lg_el_width};

        if (++$row > $self->{lg_cols})
        {
            $row = 1;
            $y += $self->{lg_el_height};
            $x = $xl;
        }
    }
}

#
# This will be virtual; every sub class should define their own
# if this one doesn't suffice
#
sub draw_legend_marker # data_set_number, x, y
{
    my $s = shift;
    my $n = shift;
    my $x = shift;
    my $y = shift;

    my $g = $s->{graph};

    my $ci = $s->set_clr($s->pick_data_clr($n));
    return unless defined $ci;

    $y += int($s->{lg_el_height}/2 - $s->{legend_marker_height}/2);

    $g->filledRectangle(
        $x, $y, 
        $x + $s->{legend_marker_width}, $y + $s->{legend_marker_height},
        $ci
    );

    $g->rectangle(
        $x, $y, 
        $x + $s->{legend_marker_width}, $y + $s->{legend_marker_height},
        $s->{acci}
    );
}

"Just another true value";
