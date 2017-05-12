package Spline;

=head1 NAME

Spline - A XFig file animator class - Spline object

=head1 DESCRIPTION

Spline object - object code in FIG format: 3.
Here are all the attributes of this class:

B<sub_type, line_style, thickness, pen_color, fill_color, depth, pen_style,
area_fill, style_val, cap_style, forward_arrow, backward_arrow, npoints,
f_arrow_type, f_arrow_style, f_arrow_thickness, f_arrow_width, f_arrow_height,
b_arrow_type, b_arrow_style, b_arrow_thickness, b_arrow_width, b_arrow_height,
xnpoints, ynpoints, control_points, visibility, center_x, center_y,
max_spline_step, high_precision>

=head1 FIG ATTRIBUTES

=over

=item sub_type

0: opened approximated spline;
1: closed approximated spline;
2: opened interpolated spline;
3: closed interpolated spline;
4: opened x-spline;
5: closed x-spline.

=item line_style

-1: Default;
0: Solid;
1: Dashed;
2: Dotted;
3: Dash-dotted;
4: Dash-double-dotted;
5: Dash-triple-dotted.

=item thickness

80-ths of an inch ("display units")

=item pen_color

-1..31: FIG colors;
32..543 (512 total): user colors.

=item fill_color

-1..31: FIG colors;
32..543 (512 total): user colors.

=item depth

0 ... 999: larger value means object is deeper than (under)
objects with smaller depth

=item pen_style

unused

=item area_fill

fill type

=item style_val

length, in 1/80 inches, of the on/off
dashes for dashed lines, and the distance between the dots, in 1/80 inches,
for dotted lines

=item cap_style

0 = Butt (default);
1 = Round;
2 = Projecting.

=item forward_arrow

0: no forward arrow;
1: on

=item backward_arrow

0: no backward arrow;
1: on

=item npoints

number of control points in spline

=item f_arrow_type, b_arrow_type

0: Stick-type (default);
1: Closed triangle;
2: Closed with "indented" butt;
3: Closed with "pointed" butt

=item f_arrow_style, b_arrow_style

0: Hollow (filled with white);
1: Filled with pen_color

=item f_arrow_thickness, b_arrow_thickness

1/80 inch

=item f_arrow_width, b_arrow_width

Fig units

=item f_arrow_height, b_arrow_height

Fig units

=item xnpoints, ynpoints

arrays of points coordinates in Fig units

=item control_points

array of control points values:
there is one shape factor for each point. The value of this factor
must be between -1 (which means that the spline is interpolated at
this point) and 1 (which means that the spline is approximated at
this point). The spline is always smooth in the neighbourhood of a
control point, except when the value of	the factor is 0 for which
there is a first-order discontinuity (i.e. angular point).

=back

=head1 ADDITONNAL ATTRIBUTES

=over

=item visibility

0: hidden;
1: shown

=item center_x, center_y

calculated center (Fig units)

=item max_spline_step

parameter for computing polyline from spline (default 0.2)

=item high_precision

parameter for computing polyline from spline (default 0.5)

=back

=cut

use strict;
use warnings;

# useful classes
use FigAnim::Utils;
use FigAnim::Point;

# constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    
    $self->{name} = shift; # object's name in comment
    
    #$self->{object_code} = 3;
    $self->{sub_type} = shift;
    $self->{line_style} = shift;
    $self->{thickness} = shift;
    $self->{pen_color} = shift;
    $self->{fill_color} = shift;
    $self->{depth} = shift;
    $self->{pen_style} = shift;
    $self->{area_fill} = shift;
    $self->{style_val} = shift;
    $self->{cap_style} = shift;
    $self->{forward_arrow} = shift;
    $self->{backward_arrow} = shift;
    $self->{npoints} = shift;
    
    # forward arrow
    $self->{f_arrow_type} = shift;
    $self->{f_arrow_style} = shift;
    $self->{f_arrow_thickness} = shift;
    $self->{f_arrow_width} = shift;
    $self->{f_arrow_height} = shift;
    
    # backward arrow
    $self->{b_arrow_type} = shift;
    $self->{b_arrow_style} = shift;
    $self->{b_arrow_thickness} = shift;
    $self->{b_arrow_width} = shift;
    $self->{b_arrow_height} = shift;
    
    # points
    $self->{xnpoints} = shift;
    $self->{ynpoints} = shift;
    $self->{points} = [];

    # control points
    $self->{control_points} = shift;
    
    # reference to the FigFile
    $self->{fig_file} = shift;
    
    # object's visibility : 0=hidden 1=shown
    $self->{visibility} = 1;
    
    # calculated center
    $self->{center_x} = undef;
    $self->{center_y} = undef;

    # computed polyline from spline
    $self->{x} = []; # computed x points
    $self->{y} = []; # computed y points
    $self->{n} = 0; # number of computed points

    # parameters for computing splines
    $self->{max_spline_step} = 0.2;
    $self->{high_precision} = 0.5;

    # animations
    $self->{animations} = [];

    bless ($self, $class);
    return $self;
}


# methods
sub clone {
    my $self = shift;
    my $obj = new Spline;

    foreach ('name','sub_type','line_style','thickness','pen_color',
	     'fill_color','depth','pen_style','area_fill','style_val',
	     'cap_style','forward_arrow','backward_arrow','npoints',
	     'f_arrow_type','f_arrow_style','f_arrow_thickness',
	     'f_arrow_width','f_arrow_height','b_arrow_type','b_arrow_style',
	     'b_arrow_thickness','b_arrow_width','b_arrow_height','fig_file',
	     'visibility','center_x','center_y') {
	$obj->{$_} = $self->{$_};
    }

    $obj->{xnpoints} = [];
    push @{$obj->{xnpoints}}, @{$self->{xnpoints}};

    $obj->{ynpoints} = [];
    push @{$obj->{ynpoints}}, @{$self->{ynpoints}};

    $obj->{control_points} = [];
    push @{$obj->{control_points}}, @{$self->{control_points}};

    return $obj;
}

sub output {
    my $self = shift;
    return if ($self->{visibility} == 0);
    
    my $fh = shift;
    
    foreach (split(/\n/, $self->{name})) {
	printf $fh "# $_\n";
    }
    
    printf $fh
	"3 %d %d %d %d %d %d %d %d %.3f %d %d %d %d\n",
	@$self{'sub_type','line_style','thickness','pen_color','fill_color',
	       'depth','pen_style','area_fill','style_val','cap_style',
	       'forward_arrow','backward_arrow','npoints'};
    
    if ($self->{forward_arrow}) {
	printf $fh "\t%d %d %.2f %.2f %.2f\n",
	    @$self{'f_arrow_type','f_arrow_style','f_arrow_thickness',
		   'f_arrow_width','f_arrow_height'};
    }
    
    if ($self->{backward_arrow}) {
	printf $fh "\t%d %d %.2f %.2f %.2f\n",
	    @$self{'b_arrow_type','b_arrow_style','b_arrow_thickness',
		   'b_arrow_width','b_arrow_height'};
    }
    
    for (0..$self->{npoints}-1) {
	printf $fh "\t" if (($_ % 6) == 0);
	printf $fh " %d %d", $self->{xnpoints}[$_], $self->{ynpoints}[$_];
	printf $fh "\n" if (($_ % 6) == 5);
    }
    printf $fh "\n" if (($self->{npoints} % 6) != 0);
    
    for (0..$self->{npoints}-1) {
	printf $fh "\t" if (($_ % 8) == 0);
	printf $fh " %.3f", $self->{control_points}[$_];
	printf $fh "\n" if (($_ % 8) == 7);
    }
    printf $fh "\n" if (($self->{npoints} % 8) != 0);
}

sub calculateCenter {
    my $self = shift;
    if (($self->{npoints} > 1) &&
	($self->{xnpoints}[$self->{npoints}-1] == $self->{xnpoints}[0]) &&
	($self->{ynpoints}[$self->{npoints}-1] == $self->{ynpoints}[0])) {
	$self->{center_x} =
	    sprintf("%.0f",
		    eval(join('+',
			      @{$self->{xnpoints}}[0..$self->{npoints}-2]
			      )
			 ) / ($self->{npoints}-1));
	$self->{center_y} =
	    sprintf("%.0f",
		    eval(join('+',
			      @{$self->{ynpoints}}[0..$self->{npoints}-2]
			      )
			 ) / ($self->{npoints}-1));
    } else {
	$self->{center_x} =
	    sprintf("%.0f",
		    eval(join('+',@{$self->{xnpoints}}))/$self->{npoints});
	$self->{center_y} =
	    sprintf("%.0f",
		    eval(join('+',@{$self->{ynpoints}}))/$self->{npoints});
    }
}


# animation methods
sub setAttributeValue {
    my $self = shift;
    my @anim = (0, $self->{name}, shift, 0, shift, shift);
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub setPenColor {
    my $self = shift;
    my $time = shift;
    my $color = shift;
    my $code = $FigAnim::Utils::colors_codes{$color};
    if (defined $color) {
	my @anim = (0, $self->{name}, $time, 0, 'pen_color', $code);
	push @{$self->{fig_file}->{animations}}, \@anim;
    }
}

sub setFillColor {
    my $self = shift;
    my $time = shift;
    my $color = shift;
    my $code = $FigAnim::Utils::colors_codes{$color};
    if (defined $color) {
	my @anim = (0, $self->{name}, $time, 0, 'fill_color', $code);
	push @{$self->{fig_file}->{animations}}, \@anim;
    }
}

sub hide {
    my $self = shift;
    my @anim = (0, $self->{name}, shift, 0, 'visibility', 0);
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub show {
    my $self = shift;
    my @anim = (0, $self->{name}, shift, 0, 'visibility', 1);
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub changeThickness {
    my $self = shift;
    my @anim = (1, $self->{name}, shift, shift, int shift);
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub changeFillIntensity {
    my $self = shift;
    my @anim = (2, $self->{name}, shift, shift, int shift);
    $anim[4] = 0 if ($anim[4] < 0);
    $anim[4] = 20 if ($anim[4] > 20);
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub translate {
    my $self = shift;
    my @anim = (13, $self->{name}, shift, shift, shift, shift, shift);
    $anim[6] = '' if (!(defined $anim[6]));
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub rotate {
    my $self = shift;
    my @anim = (23, $self->{name}, shift, shift, shift, shift, shift, shift);
    if (!((defined $anim[5]) && (defined $anim[6]))) {
	$anim[5] = $self->{center_x};
	$anim[6] = $self->{center_y};
    }
    $anim[7] = '' if (!(defined $anim[7]));
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub scale {
    my $self = shift;
    my @anim = (33, $self->{name}, shift, shift, shift, shift, shift);
    if (!((defined $anim[5]) && (defined $anim[6]))) {
	$anim[5] = $self->{center_x};
	$anim[6] = $self->{center_y};
    }
    push @{$self->{fig_file}->{animations}}, \@anim;
}


# outputs a SVG element
sub outputSVG {
    my $self = shift;
    my $fh = shift;

    my ($colors) = @_;

    foreach (split(/\n/, $self->{name})) {
	print $fh "<!-- $_ -->\n";
    }
    
    # converts values in SVG-CSS

    # points
    for (0 .. $self->{npoints}-1) {
	push @{$self->{points}}, new Point($self->{xnpoints}[$_],
					   $self->{ynpoints}[$_]);
    }

    if ($self->{sub_type} % 2 == 0) {
	$self->compute_open_spline($self->{high_precision});
    } else {
	$self->compute_closed_spline($self->{high_precision});
    }
    my $points = "points=\"";
    for (0 .. $self->{n}-1) {
	$points .= $self->{x}[$_] . " " . $self->{y}[$_];
	$points .= ", " if ($_ < $self->{n}-1);
    }
    $points .= "\"";

    # style
    my $style = "style=\"";

    # converts arrows into SVG paths
    # - too much bugs


    # line_style, style_val, pen_color
    $style .= ConvertSVG::line_style_to_stroke($self->{line_style},
					       $self->{style_val},
					       $self->{pen_color},
					       $colors) . "; ";
    # thickness
    $style .= ConvertSVG::thickness_to_stroke($self->{thickness}) . "; ";

    # fill_color, area_fill
    $style .= ConvertSVG::area_fill_to_fill($self->{area_fill},
					    $self->{fill_color},
					    $colors) . "; ";

    # cap_style
    $style .= ConvertSVG::cap_style_to_linecap($self->{cap_style}) . "; ";

    # end of style
    $style .= "\"";

    print $fh "<polyline $points $style";

    if ($#{$self->{animations}} >= 0) { # SVG + SMIL
	print $fh ">\n";
	for (my $i = 0; $i <= $#{$self->{animations}}; $i++) {
	    print $fh "\t";
	    my $smil = ConvertSMIL::smil($self->{animations}[$i]);
	    print $fh $smil;
	    print $fh "\n";
	}
	print $fh "</polyline>\n\n";
    } else { # SVG only
	print $fh " />\n\n";
    }
}


# curves for X-splines
# the following spline drawing routines are from:
# "X-splines : A Spline Model Designed for the End User"
# by Carole BLANC and Christophe SCHLICK, Proceedings of SIGGRAPH'95
# and "trans_spline.c" from "fig2dev" sources

sub round {
    my ($number) = shift;
    return int($number + .5);
}

sub add_point {
    my $self = shift;

    my ($i, $j) = @_;

    if (($self->{n} > 0) &&
	($i == $self->{x}[$self->{n}-1]) &&
	($j == $self->{y}[$self->{n}-1])) {
    } else {
	push @{$self->{x}}, $i;
	push @{$self->{y}}, $j;
	$self->{n}++;
    }
}

sub compute_open_spline {
    my $self = shift;

    my ($precision) = @_;

    my $k;
    my $step;
    my ($p0, $p1, $p2, $p3);
    my ($s0, $s1, $s2, $s3);

    # special case - two point spline is just straight line
    if ($self->{npoints} == 2) {
	$self->add_point($self->{points}[0]->{x},$self->{points}[0]->{y});
	$self->add_point($self->{points}[1]->{x},$self->{points}[1]->{y});
	return;
    }

    $p0 = $self->{points}[0]; $s0 = $self->{control_points}[0];
    $p1 = $p0; $s1 = $s0;
    # first control point is needed twice for the first segment
    $p2 = $self->{points}[1]; $s2 = $self->{control_points}[1];

    if ($self->{npoints} == 2) {
	$p3 = $p2; $s3 = $s2;
    } else {
	$p3 = $self->{points}[2]; $s3 = $self->{control_points}[2];
    }

    OPEN_SPLINE: for ($k = 0; ; $k++) {
	$step = $self->step_computing($k,
				      $p0, $p1, $p2, $p3,
				      $s1, $s2, $precision);
	$self->spline_segment_computing($step, $k,
					$p0, $p1, $p2, $p3, $s1, $s2);

	last OPEN_SPLINE if ($k >= $self->{npoints}-3);

	$p0 = $p1; $s0 = $s1;
	$p1 = $p2; $s1 = $s2;
	$p2 = $p3; $s2 = $s3;
	$p3 = $self->{points}[$k+3]; $s3 = $self->{control_points}[$k+3];
    }

    # last control point is needed twice for the last segment
    $p0 = $p1; $s0 = $s1;
    $p1 = $p2; $s1 = $s2;
    $p2 = $p3; $s2 = $s3;

    $step = $self->step_computing($k,
				  $p0, $p1, $p2, $p3,
				  $s1, $s2, $precision);
    $self->spline_segment_computing($step, $k,
				    $p0, $p1, $p2, $p3, $s1, $s2);

    $self->add_point($p3->{x}, $p3->{y});
}

sub compute_closed_spline {
    my $self = shift;

    my ($precision) = @_;

    my ($k, $i);
    my $step;
    my ($p0, $p1, $p2, $p3, $first);
    my ($s0, $s1, $s2, $s3, $s_first);

    $p0 = $self->{points}[0]; $s0 = $self->{control_points}[0];
    $p1 = $self->{points}[1]; $s1 = $self->{control_points}[1];
    $p2 = $self->{points}[2]; $s2 = $self->{control_points}[2];
    $p3 = $self->{points}[3]; $s3 = $self->{control_points}[3];

    $first = $p0; $s_first = $s0;

    for ($k = 0; $k < $self->{npoints}-3; $k++) {
	# probleme ici
	$step = $self->step_computing($k,
				      $p0, $p1, $p2, $p3,
				      $s1, $s2, $precision);
	# ok
	$self->spline_segment_computing($step, $k,
					$p0, $p1, $p2, $p3, $s1, $s2);
	$p0 = $p1; $s0 = $s1;
	$p1 = $p2; $s1 = $s2;
	$p2 = $p3; $s2 = $s3;
	$p3 = $self->{points}[$k+4]; $s3 = $self->{control_points}[$k+4];
    }

    # when we are at the end, join to the beginning
    $p3 = $first; $s3 = $s_first;

    $step = $self->step_computing($k,
				  $p0, $p1, $p2, $p3, $s1, $s2, $precision);
    $self->spline_segment_computing($step, $k, $p0, $p1, $p2, $p3, $s1, $s2);

    for ($i = 0; $i < 2; $i++) {
	$k++;

	$p0 = $p1; $s0 = $s1;
	$p1 = $p2; $s1 = $s2;
	$p2 = $p3; $s2 = $s3;
	$p3 = $self->{points}[$i+1]; $s3 = $self->{control_points}[$i+1];

	$step = $self->step_computing($k,
				      $p0, $p1, $p2, $p3,
				      $s1, $s2, $precision);
	$self->spline_segment_computing($step, $k,
					$p0, $p1, $p2, $p3, $s1, $s2);
    }

    $self->add_point($self->{x}[0], $self->{y}[0]);
}

sub Q {
    my ($d) = @_;
    return -1.0 * $d;
}

sub f_blend {
    my ($numerator, $denominator) = @_;

    my $p = 2.0 * $denominator * $denominator;
    my $u = $numerator / $denominator;
    my $u2 = $u * $u;

    return ($u * $u2 * (10.0 - $p + (2.0*$p - 15.0)*$u + (6.0 - $p)*$u2));
}

sub g_blend {
    my ($u, $q) = @_;

    return
	($u*($q +
	     $u*(2.0*$q +
		 $u*(8.0 - 12.0*$q +
		     $u*(14.0*$q - 11.0 +
			 $u*(4.0 - 5.0*$q))))));
}

sub h_blend {
    my ($u, $q) = @_;

    my $u2 = $u * $u;
    return
	($u * ($q + $u * (2.0 * $q + $u2 * (-2.0*$q - $u*$q))));
}

sub negative_s1_influence {
    my ($t, $s1, $A0, $A2) = @_;

    $$A0 = h_blend(-$t, Q($s1));
    $$A2 = g_blend($t, Q($s1));
}

sub negative_s2_influence {
    my ($t, $s2, $A1, $A3) = @_;

    $$A1 = g_blend(1-$t, Q($s2));
    $$A3 = h_blend($t-1, Q($s2));
}

sub positive_s1_influence {
    my ($k, $t, $s1, $A0, $A2) = @_;

    my $Tk;

    $Tk = $k+1.0+$s1;
    $$A0 = ($t+$k+1.0<$Tk) ? f_blend($t+$k+1.0-$Tk, $k-$Tk) : 0.0;

    $Tk = $k+1.0-$s1;
    $$A2 = f_blend($t+$k+1.0-$Tk, $k+2.0-$Tk);
}

sub positive_s2_influence {
    my ($k, $t, $s2, $A1, $A3) = @_;

    my $Tk;

    $Tk = $k+2.0+$s2;
    $$A1 = f_blend($t+$k+1-$Tk, $k+1-$Tk);

    $Tk = $k+2.0-$s2;
    $$A3 = ($t+$k+1.0>$Tk) ? f_blend($t+$k+1.0-$Tk, $k+3.0-$Tk) : 0.0;
}

sub point_adding {
    my $self = shift;

    my ($A_blend, $p0, $p1, $p2, $p3) = @_;

    my $weights_sum =
	@$A_blend[0] + @$A_blend[1] + @$A_blend[2] + @$A_blend[3];

    my $x_sum = @$A_blend[0]*$p0->{x} + @$A_blend[1]*$p1->{x} +
	@$A_blend[2]*$p2->{x} + @$A_blend[3]*$p3->{x};

    my $y_sum = @$A_blend[0]*$p0->{y} + @$A_blend[1]*$p1->{y} +
	@$A_blend[2]*$p2->{y} + @$A_blend[3]*$p3->{y};

    $self->add_point(round($x_sum / $weights_sum),
		     round($y_sum / $weights_sum));
}

sub point_computing {
    my $self = shift;

    my ($A_blend, $p0, $p1, $p2, $p3, $x, $y) = @_;

    my $weights_sum =
	@$A_blend[0] + @$A_blend[1] + @$A_blend[2] + @$A_blend[3];

    my $x_sum = @$A_blend[0]*$p0->{x} + @$A_blend[1]*$p1->{x} +
	@$A_blend[2]*$p2->{x} + @$A_blend[3]*$p3->{x};

    my $y_sum = @$A_blend[0]*$p0->{y} + @$A_blend[1]*$p1->{y} +
	@$A_blend[2]*$p2->{y} + @$A_blend[3]*$p3->{y};

    $$x = round($x_sum / $weights_sum);
    $$y = round($y_sum / $weights_sum);
}

sub step_computing {
    my $self = shift;

    my ($k, $p0, $p1, $p2, $p3, $s1, $s2, $precision) = @_;

    my @A_blend = [0.0, 0.0, 0.0, 0.0];
    my ($xstart, $ystart, $xend, $yend, $xmid, $ymid, $xlength, $ylength);
    my ($start_to_end_dist, $number_of_steps);
    my ($step, $angle_cos, $scal_prod,
	$xv1, $xv2, $yv1, $yv2,
	$sides_length_prod);

    # origin
    if ($s1 > 0.0) {
	if ($s2 < 0.0) {
	    positive_s1_influence($k, 0.0, $s1, \$A_blend[0], \$A_blend[2]);
	    negative_s2_influence(0.0, $s2, \$A_blend[1], \$A_blend[3]);
	} else {
	    positive_s1_influence($k, 0.0, $s1, \$A_blend[0], \$A_blend[2]);
	    positive_s2_influence($k, 0.0, $s2, \$A_blend[1], \$A_blend[3]); 
	}
	$self->point_computing(\@A_blend, $p0, $p1, $p2, $p3,
			       \$xstart, \$ystart);
    } else {
	$xstart = $p1->{x};
	$ystart = $p1->{y};
    }

    # extremity
    if ($s2 > 0.0) {
	if ($s1 < 0) {
	    negative_s1_influence(1.0, $s1, \$A_blend[0], \$A_blend[2]);
	    positive_s2_influence($k, 1.0, $s2, \$A_blend[1], \$A_blend[3]);
	} else {
	    positive_s1_influence($k, 1.0, $s1, \$A_blend[0], \$A_blend[2]);
	    positive_s2_influence($k, 1.0, $s2, \$A_blend[1], \$A_blend[3]);
	}
	$self->point_computing(\@A_blend, $p0, $p1, $p2, $p3,
			       \$xend, \$yend);
    } else {
	$xend = $p2->{x};
	$yend = $p2->{y};
    }

    # middle
    if ($s2 > 0.0) {
	if ($s1 < 0.0) {
	    negative_s1_influence(0.5, $s1, \$A_blend[0], \$A_blend[2]);
	    positive_s2_influence($k, 0.5, $s2, \$A_blend[1], \$A_blend[3]);
	} else {
	    positive_s1_influence($k, 0.5, $s1, \$A_blend[0], \$A_blend[2]);
	    positive_s2_influence($k, 0.5, $s2, \$A_blend[1], \$A_blend[3]);
	}
    } elsif ($s1 < 0.0) {
	negative_s1_influence(0.5, $s1, \$A_blend[0], \$A_blend[2]);
	negative_s2_influence(0.5, $s2, \$A_blend[1], \$A_blend[3]);
    } else {
	positive_s1_influence($k, 0.5, $s1, \$A_blend[0], \$A_blend[2]);
	negative_s2_influence(0.5, $s2, \$A_blend[1], \$A_blend[3]);
    }

    $self->point_computing(\@A_blend, $p0, $p1, $p2, $p3, \$xmid, \$ymid);

    $xv1 = $xstart - $xmid;
    $yv1 = $ystart - $ymid;
    $xv2 = $xend - $xmid;
    $yv2 = $yend - $ymid;

    $scal_prod = $xv1*$xv2 + $yv1*$yv2;

    $sides_length_prod = sqrt(($xv1*$xv1 + $yv1*$yv1)*($xv2*$xv2 + $yv2*$yv2));

    # cosinus of origin-middle-extremity angle
    if ($sides_length_prod == 0.0) {
	$angle_cos = 0.0;
    } else {
	$angle_cos = $scal_prod/$sides_length_prod;
    }

    $xlength = $xend - $xstart;
    $ylength = $yend - $ystart;

    $start_to_end_dist = int(sqrt($xlength*$xlength + $ylength*$ylength));

    # more steps if segment's origin and extremity are remote
    $number_of_steps = int(sqrt($start_to_end_dist)/2);

    # more steps if the curve is high
    $number_of_steps += int(((1.0 + $angle_cos)*10.0));

    if (($number_of_steps == 0) || ($number_of_steps > 999)) {
	$step = 1.0;
    } else {
	$step = $precision/$number_of_steps;
    }

    if (($step > $self->{max_spline_step}) || ($step == 0)) {
	$step = $self->{max_spline_step};
    }

    return $step;
}

sub spline_segment_computing {
    my $self = shift;

    my ($step, $k, $p0, $p1, $p2, $p3, $s1, $s2) = @_;

    my @A_blend = [0.0, 0.0, 0.0, 0.0];
    my $t;

    if ($s1 < 0.0) {
	if ($s2 < 0.0) {
	    for ($t = 0.0; $t < 1.0; $t += $step) {
		negative_s1_influence($t, $s1, \$A_blend[0], \$A_blend[2]);
		negative_s2_influence($t, $s2, \$A_blend[1], \$A_blend[3]);

		$self->point_adding(\@A_blend, $p0, $p1, $p2, $p3);
	    }
	} else {
	    for ($t = 0.0; $t < 1.0; $t += $step) {
		negative_s1_influence($t, $s1, \$A_blend[0], \$A_blend[2]);
		positive_s2_influence($k, $t, $s2, \$A_blend[1], \$A_blend[3]);

		$self->point_adding(\@A_blend, $p0, $p1, $p2, $p3);
	    }
	}
    } elsif ($s2 < 0.0) {
	for ($t = 0.0; $t < 1.0; $t += $step) {
	    positive_s1_influence($k, $t, $s1, \$A_blend[0], \$A_blend[2]);
	    negative_s2_influence($t, $s2, \$A_blend[1], \$A_blend[3]);

	    $self->point_adding(\@A_blend, $p0, $p1, $p2, $p3);
	}
    } else {
	for ($t = 0.0; $t < 1.0; $t += $step) {
	    positive_s1_influence($k, $t, $s1, \$A_blend[0], \$A_blend[2]);
	    positive_s2_influence($k, $t, $s2, \$A_blend[1], \$A_blend[3]);

	    $self->point_adding(\@A_blend, $p0, $p1, $p2, $p3);
	}
    }
}



1;
