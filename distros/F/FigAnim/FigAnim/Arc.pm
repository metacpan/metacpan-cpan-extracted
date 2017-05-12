package Arc;

=head1 NAME

Arc - A XFig file animator class - Arc object

=head1 DESCRIPTION

Arc object - object code in FIG format: 5.
Here are all the attributes of this class:

B<sub_type, line_style, thickness, pen_color, fill_color, depth, pen_style,
area_fill, style_val, cap_style, direction, forward_arrow, backward_arrow,
center_x, center_y,  x1, y1, x2, y2, x3, y3, f_arrow_type, f_arrow_style,
f_arrow_thickness, f_arrow_width, f_arrow_height, b_arrow_type, b_arrow_style,
b_arrow_thickness, b_arrow_width, b_arrow_height, visibility>

=head1 FIG ATTRIBUTES

=over

=item sub_type

0: pie-wedge (closed)
1: open ended arc

=item line_style

-1: Default;
0: Solid;
1: Dashed;
2: Dotted;
3: Dash-dotted;
4: Dash-double-dotted;
5: Dash-triple-dotted

=item thickness

80-ths of an inch ("display units")

=item pen_color

-1..31: FIG colors;
32..543 (512 total): user colors

=item fill_color

-1..31: FIG colors;
32..543 (512 total): user colors

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

0: Butt (default);
1: Round;
2: Projecting

=item direction

0: clockwise;
1: counterclockwise

=item forward_arrow

0: no forward arrow;
1: on

=item backward_arrow

0: no backward arrow;
1: on

=item center_x, center_y

Fig units, the center of the arc

=item x1, y1

Fig units, the 1st point the user entered

=item x2, y2

Fig units, the 2nd point

=item x3, y3

Fig units, the last point

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

=back

=head1 ADDITONNAL ATTRIBUTES

=over

=item visibility

0: hidden;
1: shown

=back

=cut

use strict;
use warnings;

# useful classes
use FigAnim::Utils;

# constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    
    $self->{name} = shift; # object's name in comment
    
    #$self->{object_code} = 5;
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
    $self->{direction} = shift;
    $self->{forward_arrow} = shift;
    $self->{backward_arrow} = shift;
    $self->{center_x} = shift;
    $self->{center_y} = shift;
    $self->{x1} = shift;
    $self->{y1} = shift;
    $self->{x2} = shift;
    $self->{y2} = shift;
    $self->{x3} = shift;
    $self->{y3} = shift;
    
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
    
    # reference to the FigFile
    $self->{fig_file} = shift;
    
    # object's visibility : 0=hidden 1=shown
    $self->{visibility} = 1;

    # animations
    $self->{animations} = [];

    bless ($self, $class);
    return $self;
}


# methods
sub clone {
    my $self = shift;
    my $obj = new Arc;
    $obj->{$_} = $self->{$_} foreach (keys %{$self});
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
    "5 %d %d %d %d %d %d %d %d %.3f %d %d %d %d %.3f %.3f %d %d %d %d %d %d\n",
	@$self{'sub_type','line_style','thickness','pen_color',
	       'fill_color','depth','pen_style','area_fill','style_val',
	       'cap_style','direction','forward_arrow','backward_arrow',
	       'center_x','center_y','x1','y1','x2','y2','x3','y3'};
    
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
    my $color = $FigAnim::Utils::colors_codes{shift};
    if (defined $color) {
	my @anim = (0, $self->{name}, $time, 0, 'pen_color', $color);
	push @{$self->{fig_file}->{animations}}, \@anim;
    }
}

sub setFillColor {
    my $self = shift;
    my $time = shift;
    my $color = $FigAnim::Utils::colors_codes{shift};
    if (defined $color) {
	my @anim = (0, $self->{name}, $time, 0, 'fill_color', $color);
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
    my @anim = (15, $self->{name}, shift, shift, shift, shift, shift);
    $anim[6] = '' if (!(defined $anim[6]));
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub rotate {
    my $self = shift;
    my @anim = (25, $self->{name}, shift, shift, shift, shift, shift, shift);
    if (!((defined $anim[5]) && (defined $anim[6]))) {
	$anim[5] = $self->{center_x};
	$anim[6] = $self->{center_y};
    }
    $anim[7] = '' if (!(defined $anim[7]));
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub scale {
    my $self = shift;
    my @anim = (35, $self->{name}, shift, shift, shift, shift, shift);
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

    # converts values into SVG-CSS

    my $direction = $self->{direction};

    my $center_x = $self->{center_x};
    my $center_y = $self->{center_y};

    my $x1 = $self->{x1};
    my $y1 = $self->{y1};

    my $x2 = $self->{x2};
    my $y2 = $self->{y2};

    my $x3 = $self->{x3};
    my $y3 = $self->{y3};

    # radius_x, radius_y
    my $rx = int(sqrt(($x1-$self->{center_x})*($x1-$self->{center_x}) +
		      ($y1-$self->{center_y})*($y1-$self->{center_y})));
    my $ry = $rx;

    my $sweep_flag;
    my $large_arc_flag;

    if ($self->{direction} == 0) {
	$sweep_flag = 1;
	if (($x3 - $center_x) * ($y1 - $center_y) -
	    ($y3 - $center_y) * ($x1 - $center_x) >= 0) {
	    $large_arc_flag = 1;
	} else {
	    $large_arc_flag = 0;
	}
    } else {
	$sweep_flag = 0;
	if (($x1 - $center_x) * ($y3 - $center_y) -
	    ($y1 - $center_y) * ($x3 - $center_x) >= 0) {
	    $large_arc_flag = 1;
	} else {
	    $large_arc_flag = 0;
	}
    }

    my $style = "style=\"";

    # converts arrows into SVG paths

    my $f_arrow_name = "";
    my $b_arrow_name = "";

    if ($self->{forward_arrow} == 1) {
	$_ = $self->{name};
	s/\W//g;
	$f_arrow_name = $_ . "_f_arrow";

	my $f_arrow =
	    ConvertSVG::arrows_to_markers($f_arrow_name,
					  1,
					  "auto",
					  $self->{f_arrow_type},
					  $self->{f_arrow_style},
					  $self->{f_arrow_thickness},
					  $self->{f_arrow_width},
					  $self->{f_arrow_height},
					  $self->{pen_color},
					  $colors);
	print $fh $f_arrow;
	$style .=
	    "marker-end: url(#" . $f_arrow_name . "); ";
    }

    if ($self->{backward_arrow} == 1) {
	$_ = $self->{name};
	s/\W//g;
	$b_arrow_name = $_ . "_b_arrow";

	my $b_arrow =
	    ConvertSVG::arrows_to_markers($b_arrow_name,
					  0,
					  "auto",
					  $self->{b_arrow_type},
					  $self->{b_arrow_style},
					  $self->{b_arrow_thickness},
					  $self->{b_arrow_width},
					  $self->{b_arrow_height},
					  $self->{pen_color},
					  $colors);
	print $fh $b_arrow;
	$style .=
	    "marker-start: url(#" . $b_arrow_name . "); ";
    }

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
    $style .= ConvertSVG::cap_style_to_linecap($self->{cap_style});

    # end of style
    $style .= "\"";

    my $d = "d=\"" .
	"M $x1 $y1, " .
	"A $rx $ry, " .
	"0, " .
	"$large_arc_flag, " .
	"$sweep_flag, " .
	"$x3 $y3";

    if ($self->{sub_type} == 2) { # pie-wedge (closed)
	$d .= "L $center_x $center_y, L $x1 $y1\"";
    } else { # open ended arc
	$d .= "\"";
    }

    print $fh "<path $d $style";

    if ($#{$self->{animations}} >= 0) { # SVG + SMIL
	print $fh ">\n";
	for (my $i = 0; $i <= $#{$self->{animations}}; $i++) {
	    print $fh "\t";
	    my $smil = ConvertSMIL::smil($self->{animations}[$i]);
	    print $fh $smil;
	    print $fh "\n";
	}
	print $fh "</path>\n\n";
    } else { # SVG only
	print $fh " />\n\n";
    }
}


1;
