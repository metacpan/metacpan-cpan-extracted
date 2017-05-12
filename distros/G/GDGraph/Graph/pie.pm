#==========================================================================
#              Copyright (c) 1995-1998 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::pie.pm
#
# $Id: pie.pm,v 1.21 2007/04/26 03:16:09 ben Exp $
#
#==========================================================================

package GD::Graph::pie;

($GD::Graph::pie::VERSION) = '$Revision: 1.21 $' =~ /\s([\d.]+)/;

use strict;

use constant PI => 4 * atan2(1,1);

use GD;
use GD::Graph;
use GD::Graph::utils qw(:all);
use GD::Graph::colour qw(:colours :lists);
use GD::Text::Align;
use Carp;

@GD::Graph::pie::ISA = qw( GD::Graph );

my $ANGLE_OFFSET = 90;

my %Defaults = (
 
    # Set the height of the pie.
    # Because of the dependency of this on runtime information, this
    # is being set in GD::Graph::pie::initialise
 
    #   pie_height => _round(0.1*${'width'}),
    pie_height  => undef,
 
    # Do you want a 3D pie?
    '3d'        => 1,
 
    # The angle at which to start the first data set
    # 0 is at the front/bottom
    start_angle => 0,

    # Angle below which a label on a pie slice is suppressed.
    suppress_angle => 0,    # CONTRIB idea ryan <xomina@bitstream.net>

    # and some public attributes without defaults
    label       => undef,

    # This misnamed attribute is used for pie marker colours
    axislabelclr => 'black',
);

# PRIVATE
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
    $self->set( pie_height => _round(0.1 * $self->{height}) );
    $self->set_value_font(gdTinyFont);
    $self->set_label_font(gdSmallFont);
}

# PUBLIC methods, documented in pod
sub plot
{
    my $self = shift;
    my $data = shift;

    $self->check_data($data)        or return;
    $self->init_graph()             or return;
    $self->setup_text()             or return;
    $self->setup_coords()           or return;
    $self->draw_text()              or return;
    $self->draw_pie()               or return;
    $self->draw_data()              or return;

    return $self->{graph};
}

sub set_label_font # (fontname)
{
    my $self = shift;
    $self->_set_font('gdta_label', @_) or return;
    $self->{gdta_label}->set_align('bottom', 'center');
}

sub set_value_font # (fontname)
{
    my $self = shift;
    $self->_set_font('gdta_value', @_) or return;
    $self->{gdta_value}->set_align('center', 'center');
}

# Inherit defaults() from GD::Graph

# inherit checkdata from GD::Graph

# Setup the coordinate system and colours, calculate the
# relative axis coordinates in respect to the canvas size.

sub setup_coords()
{
    my $self = shift;

    # Make sure we're not reserving space we don't need.
    $self->{'3d'} = 0           if     $self->{pie_height} <= 0;
    $self->set(pie_height => 0) unless $self->{'3d'};

    my $tfh = $self->{title} ? $self->{gdta_title}->get('height') : 0;
    my $lfh = $self->{label} ? $self->{gdta_label}->get('height') : 0;

    # Calculate the bounding box for the pie, and
    # some width, height, and centre parameters (don't forget fenceposts!)
    $self->{bottom} = 
        $self->{height} - $self->{pie_height} - $self->{b_margin} -
        ( $lfh ? $lfh + $self->{text_space} : 0 ) - 1;
    $self->{top} = 
        $self->{t_margin} + ( $tfh ? $tfh + $self->{text_space} : 0 );

    return $self->_set_error('Vertical size too small') 
        if $self->{bottom} - $self->{top} <= 0;

    $self->{left} = $self->{l_margin};
    $self->{right} = $self->{width} - $self->{r_margin} - 1;

    # ensure that the center is a single pixel, not a half-pixel position
    $self->{right}--  if ($self->{right} - $self->{left}) % 2;
    $self->{bottom}-- if ($self->{bottom} - $self->{top}) % 2;

    return $self->_set_error('Horizontal size too small')
        if $self->{right} - $self->{left} <= 0;

    $self->{w} = $self->{right}  - $self->{left} + 1;
    $self->{h} = $self->{bottom} - $self->{top} + 1;

    $self->{xc} = ($self->{right}  + $self->{left})/2; 
    $self->{yc} = ($self->{bottom} + $self->{top})/2;

    return $self;
}

# inherit open_graph from GD::Graph

# Setup the parameters for the text elements
sub setup_text
{
    my $self = shift;

    if ( $self->{title} ) 
    {
        #print "'$s->{title}' at ($s->{xc},$s->{t_margin})\n";
        $self->{gdta_title}->set(colour => $self->{tci});
        $self->{gdta_title}->set_text($self->{title});
    }

    if ( $self->{label} ) 
    {
        $self->{gdta_label}->set(colour => $self->{lci});
        $self->{gdta_label}->set_text($self->{label});
    }

    $self->{gdta_value}->set(colour => $self->{alci});

    return $self;
}

# Put the text on the canvas.
sub draw_text
{
    my $self = shift;

    $self->{gdta_title}->draw($self->{xc}, $self->{t_margin}) 
        if $self->{title}; 
    $self->{gdta_label}->draw($self->{xc}, $self->{height} - $self->{b_margin})
        if $self->{label};
    
    return $self;
}

# draw the pie, without the data slices
sub draw_pie
{
    my $self = shift;

    my $left = $self->{xc} - $self->{w}/2;

    $self->{graph}->arc(
        $self->{xc}, $self->{yc}, 
        $self->{w}, $self->{h},
        0, 360, $self->{acci}
    );

    $self->{graph}->arc(
        $self->{xc}, $self->{yc} + $self->{pie_height}, 
        $self->{w}, $self->{h},
        0, 180, $self->{acci}
    ) if ( $self->{'3d'} );

    $self->{graph}->line(
        $left, $self->{yc},
        $left, $self->{yc} + $self->{pie_height}, 
        $self->{acci}
    );

    $self->{graph}->line(
        $left + $self->{w}, $self->{yc},
        $left + $self->{w}, $self->{yc} + $self->{pie_height}, 
        $self->{acci}
    );

    return $self;
}

# Draw the data slices

sub draw_data
{
    my $self = shift;

    my $total = 0;
    my @values = $self->{_data}->y_values(1);   # for now, only one pie..
    for (@values)
    {   
        $total += $_ 
    }

    return $self->_set_error("Pie data total is <= 0") 
        unless $total > 0;

    my $ac = $self->{acci};         # Accent colour
    my $pb = $self->{start_angle};

    for (my $i = 0; $i < @values; $i++)
    {
        next unless $values[$i];
        # Set the data colour
        my $dc = $self->set_clr_uniq($self->pick_data_clr($i + 1));

        # Set the angles of the pie slice
        # Angle 0 faces down, positive angles are clockwise 
        # from there.
        #         ---
        #        /   \
        #        |    |
        #        \ | /
        #         ---
        #          0
        # $pa/$pb include the start_angle (so if start_angle
        # is 90, there will be no pa/pb < 90.
        my $pa = $pb;
        $pb += my $slice_angle = 360 * $values[$i]/$total;

        # Calculate the end points of the lines at the boundaries of
        # the pie slice
        my ($xe, $ye) = cartesian(
                $self->{w}/2, $pa, 
                $self->{xc}, $self->{yc}, $self->{h}/$self->{w}
            );

        $self->{graph}->line($self->{xc}, $self->{yc}, $xe, $ye, $ac);

        # Draw the lines on the front of the pie
        $self->{graph}->line($xe, $ye, $xe, $ye + $self->{pie_height}, $ac)
            if in_front($pa) && $self->{'3d'};

        # Make an estimate of a point in the middle of the pie slice
        # And fill it
        ($xe, $ye) = cartesian(
                3 * $self->{w}/8, ($pa+$pb)/2,
                $self->{xc}, $self->{yc}, $self->{h}/$self->{w}
            );

        $self->{graph}->fillToBorder($xe, $ye, $ac, $dc);

        # If it's 3d, colour the front ones as well
        #
        # if one slice is very large (>180 deg) then we will need to
        # fill it twice.  sbonds.
        #
        # Independently noted and fixed by Jeremy Wadsack, in a slightly
        # different way.
        if ($self->{'3d'}) 
        {
            foreach my $fill ($self->_get_pie_front_coords($pa, $pb)) 
            {
                my ($fx,$fy) = @$fill;
                my $new_y = $fy + $self->{pie_height}/2;
                # Edge case (literally): if lines have converged, back up 
                # looking for a gap to fill
                while ( $new_y > $fy ) {
                    if ($self->{graph}->getPixel($fx,$new_y) != $ac) {
                        $self->{graph}->fillToBorder($fx, $new_y, $ac, $dc);
                        last;
                    }
                } continue { $new_y-- }
            }
        }
    }

    # CONTRIB Jeremy Wadsack
    #
    # Large text, sticking out over the pie edge, could cause 3D pies to
    # fill improperly: Drawing the text for a given slice before the
    # next slice was drawn and filled could make the slice boundary
    # disappear, causing the fill colour to flow out.  With this
    # implementation, all the text is on top of the pie.

    $pb = $self->{start_angle};
    for (my $i = 0; $i < @values; $i++)
    {
        next unless $values[$i];

        my $pa = $pb;
        $pb += my $slice_angle = 360 * $values[$i]/$total;

        next if $slice_angle <= $self->{suppress_angle};

        my ($xe, $ye) = 
            cartesian(
                3 * $self->{w}/8, ($pa+$pb)/2,
                $self->{xc}, $self->{yc}, $self->{h}/$self->{w}
            );

        $self->put_slice_label($xe, $ye, $self->{_data}->get_x($i));
    }

    return $self;

} #GD::Graph::pie::draw_data

sub _get_pie_front_coords # (angle 1, angle 2)
{
    my $self = shift;
    my $pa = level_angle(shift);
    my $pb = level_angle(shift);
    my @fills = ();

    if (in_front($pa))
    {
        if (in_front($pb))
        {
            # both in front
            # don't do anything
            # Ah, but if this wraps all the way around the back
            # then both pieces of the front need to be filled.
            # sbonds.
            if ($pa >= $pb ) 
            {
                # This takes care of the left bit on the front
                # Since we know exactly where we are, and in which
                # direction this works, we can just get the coordinates
                # for $pa.
                my ($x, $y) = cartesian(
                    $self->{w}/2, $pa,
                    $self->{xc}, $self->{yc}, $self->{h}/$self->{w}
                );

                # and move one pixel to the left, but only if we don't
                # fall out of the pie!.
                push @fills, [$x - 1, $y]
                    if $x - 1 > $self->{xc} - $self->{w}/2;

                # Reset $pa to the right edge of the front arc, to do
                # the right bit on the front.
                $pa = level_angle(-$ANGLE_OFFSET);
            }
        }
        else
        {
            # start in front, end in back
            $pb = $ANGLE_OFFSET;
        }
    }
    else
    {
        if (in_front($pb))
        {
            # start in back, end in front
            $pa = $ANGLE_OFFSET - 180;
        }
        elsif ( # both in back, but wrapping around the front
                # CONTRIB kedlubnowski, Dan Rosendorf 
            $pa >= $pb && ($pa < 0 || $pb > 0)
            or $pa < 0 && $pb > 0
        ) 
        {   
            $pa=$ANGLE_OFFSET - 180;
            $pb=$ANGLE_OFFSET;
        }
        else
        {
            return;
        }
    }

    my ($x, $y) = cartesian(
        $self->{w}/2, ($pa + $pb)/2,
        $self->{xc}, $self->{yc}, $self->{h}/$self->{w}
    );

    push @fills, [$x, $y];

    return @fills;
}

# return true if this angle is on the front of the pie
# XXX UGLY! We need to leave a slight room for error because of rounding
# problems
sub in_front
{
    my $a = level_angle(shift);
    return 
        $a > ($ANGLE_OFFSET - 180 + 0.00000001) && 
        $a < $ANGLE_OFFSET - 0.000000001;
}

# XXX Ugh! I need to fix this. See the GD::Text module for better ways
# of doing this.
# return a value for angle between -180 and 180
sub level_angle # (angle)
{
    my $a = shift;
    return level_angle($a-360) if ( $a > 180 );
    return level_angle($a+360) if ( $a <= -180 );
    return $a;
}

# put the slice label on the pie
sub put_slice_label
{
    my $self = shift;
    my ($x, $y, $label) = @_;

    return unless defined $label;

    $self->{gdta_value}->set_text($label);
    $self->{gdta_value}->draw($x, $y);
}

# return x, y coordinates from input
# radius, angle, center x and y and a scaling factor (height/width)
#
# $ANGLE_OFFSET is used to define where 0 is meant to be
sub cartesian
{
    my ($r, $phi, $xi, $yi, $cr) = @_; 

    return map _round($_), (
        $xi + $r * cos(PI * ($phi + $ANGLE_OFFSET)/180), 
        $yi + $cr * $r * sin(PI * ($phi + $ANGLE_OFFSET)/180)
    )
}

"Just another true value";
