package Polyline;

=head1 NAME

Polyline - A XFig file animator class - Polyline object

=head1 DESCRIPTION

Polyline object - object code in FIG format: 2.
Here are all the attributes of this class:

B<sub_type, line_style, thickness, pen_color, fill_color, depth, pen_style,
area_fill, style_val, join_style, cap_style, radius, forward_arrow,
backward_arrow, npoints, f_arrow_type, f_arrow_style,
f_arrow_thickness, f_arrow_width, f_arrow_height, b_arrow_type, b_arrow_style,
b_arrow_thickness, b_arrow_width, b_arrow_height, xnpoints, ynpoints,
flipped, file, visibility, center_x, center_y>

=head1 FIG ATTRIBUTES

=over

=item sub_type

1: polyline;
2: box;
3: polygon;
4: arc-box;
5: imported-picture bounding-box.

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

=item join_style

0 = Miter (default);
1 = Bevel;
2 = Round.

=item cap_style

0 = Butt (default);
1 = Round;
2 = Projecting.

=item radius

1/80 inch, radius of arc-boxes

=item forward_arrow

0: no forward arrow;
1: on

=item backward_arrow

0: no backward arrow;
1: on

=item npoints

number of points in line

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

=item flipped

picture orientation:
0: normal;
1: flipped.

=item file

name of picture file to import

=back

=head1 ADDITONNAL ATTRIBUTES

=over

=item visibility

0: hidden;
1: shown

=item center_x, center_y

calculated center (Fig units)

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
    
    #$self->{object_code} = 2;
    $self->{sub_type} = shift;
    $self->{line_style} = shift;
    $self->{thickness} = shift;
    $self->{pen_color} = shift;
    $self->{fill_color} = shift;
    $self->{depth} = shift;
    $self->{pen_style} = shift;
    $self->{area_fill} = shift;
    $self->{style_val} = shift;
    $self->{join_style} = shift;
    $self->{cap_style} = shift;
    $self->{radius} = shift;
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
    
    # picture
    $self->{flipped} = shift;
    $self->{file} = shift;
    
    # points
    $self->{xnpoints} = shift;
    $self->{ynpoints} = shift;
    
    # reference to the FigFile
    $self->{fig_file} = shift;
    
    # object's visibility : 0=hidden 1=shown
    $self->{visibility} = 1;
    
    # calculated center
    $self->{center_x} = undef;
    $self->{center_y} = undef;

    # animations
    $self->{animations} = [];

    bless ($self, $class);
    return $self;
}


# methods
sub clone {
    my $self = shift;
    my $obj = new Polyline;

    foreach ('name','sub_type','line_style','thickness','pen_color',
	     'fill_color','depth','pen_style','area_fill','style_val',
	     'join_style','cap_style','radius','forward_arrow',
	     'backward_arrow','npoints','f_arrow_type','f_arrow_style',
	     'f_arrow_thickness','f_arrow_width','f_arrow_height',
	     'b_arrow_type','b_arrow_style','b_arrow_thickness',
	     'b_arrow_width','b_arrow_height','flipped','file','fig_file',
	     'visibility','center_x','center_y') {
	$obj->{$_} = $self->{$_};
    }

    $obj->{xnpoints} = [];
    push @{$obj->{xnpoints}}, @{$self->{xnpoints}};

    $obj->{ynpoints} = [];
    push @{$obj->{ynpoints}}, @{$self->{ynpoints}};

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
	"2 %d %d %d %d %d %d %d %d %.3f %d %d %d %d %d %d\n",
	@$self{'sub_type','line_style','thickness','pen_color','fill_color',
	       'depth','pen_style','area_fill','style_val','join_style',
	       'cap_style','radius','forward_arrow','backward_arrow',
	       'npoints'};
    
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
    
    if ($self->{sub_type} == 5) {
	printf $fh "\t%d %s\n", @$self{'flipped','file'};	
    }
    
    for (0..$self->{npoints}-1) {
	printf $fh "\t" if (($_ % 6) == 0);
	printf $fh " %d %d", $self->{xnpoints}[$_], $self->{ynpoints}[$_];
	printf $fh "\n" if (($_ % 6) == 5);
    }
    printf $fh "\n" if (($self->{npoints} % 6) != 0);
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
    my @anim = (12, $self->{name}, shift, shift, shift, shift, shift);
    $anim[6] = '' if (!(defined $anim[6]));
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub rotate {
    my $self = shift;
    my @anim = (22, $self->{name}, shift, shift, shift, shift, shift, shift);
    if (!((defined $anim[5]) && (defined $anim[6]))) {
	$anim[5] = $self->{center_x};
	$anim[6] = $self->{center_y};
    }
    $anim[7] = '' if (!(defined $anim[7]));
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub scale {
    my $self = shift;
    my @anim = (32, $self->{name}, shift, shift, shift, shift, shift);
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

    my $style = "style=\"";

    if ($self->{sub_type} == 1) { # polyline

	if ($self->{npoints} == 1) { # one point -> square in SVG

	    $style .= "stroke-width: 0; ";

	    # pen_color
	    $style .=
		"fill: " .
		ConvertSVG::pen_fill_colors_to_rgb($self->{pen_color},
						   $colors);

	    # end of style
	    $style .= "\"";

	    # thickness
	    my $thickness = ConvertSVG::thickness_to_value($self->{thickness});

	    # top, left
	    my $x = "x=\"" .
		int($self->{xnpoints}[0] - ($thickness / 2)) .
		"\"";
	    my $y = "y=\"" .
		int($self->{ynpoints}[0] - ($thickness / 2)) .
		"\"";

	    # width, height
	    my $width = "width=\"" . $thickness . "\"";
	    my $height = "height=\"" . $thickness . "\"";

	    print $fh "<rect $x $y $width $height $style />\n";

	} else { # two points at least

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

	    
	    # join_style
	    $style .= ConvertSVG::join_style_to_linejoin($self->{join_style}) . "; ";
	    # cap_style
	    $style .= ConvertSVG::cap_style_to_linecap($self->{cap_style});
	    
	    # end of style
	    $style .= "\"";
	    
	    # points
	    my $points = "points=\"";
	    for (0 .. $self->{npoints}-1) {
		$points .= $self->{xnpoints}[$_] . " " . $self->{ynpoints}[$_];
		if ($_ < $self->{npoints}-1) { $points .= ", "; }
	    }
	    $points .= "\"";
	    
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

    } elsif ($self->{sub_type} == 2) { # box

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
	# join_style
	$style .= ConvertSVG::join_style_to_linejoin($self->{join_style}) . "; ";
	# cap_style
	$style .= ConvertSVG::cap_style_to_linecap($self->{cap_style});

	# end of style
	$style .= "\"";

	my $top = ConvertSVG::min($self->{ynpoints}[0],
				  $self->{ynpoints}[1],
				  $self->{ynpoints}[2],
				  $self->{ynpoints}[3]);
	my $left = ConvertSVG::min($self->{xnpoints}[0],
				   $self->{xnpoints}[1],
				   $self->{xnpoints}[2],
				   $self->{xnpoints}[3]);
	my $bottom = ConvertSVG::max($self->{ynpoints}[0],
				     $self->{ynpoints}[1],
				     $self->{ynpoints}[2],
				     $self->{ynpoints}[3]);
	my $right = ConvertSVG::max($self->{xnpoints}[0],
				    $self->{xnpoints}[1],
				    $self->{xnpoints}[2],
				    $self->{xnpoints}[3]);

	my $x = "x=\"" . $left . "\"";
	my $y = "y=\"" . $top . "\"";

	my $width = "width=\"" . ($right - $left) . "\"";
	my $height = "height=\"" . ($bottom - $top) . "\"";

	print $fh "<rect $x $y $width $height $style";

	if ($#{$self->{animations}} >= 0) { # SVG + SMIL
	    print $fh ">\n";
	    for (my $i = 0; $i <= $#{$self->{animations}}; $i++) {
		print $fh "\t";
		my $smil = ConvertSMIL::smil($self->{animations}[$i]);
		print $fh $smil;
		print $fh "\n";
	    }
	    print $fh "</rect>\n\n";
	} else { # SVG only
	    print $fh " />\n\n";
	}

    } elsif ($self->{sub_type} == 3) { # polygon

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
	# join_style
	$style .= ConvertSVG::join_style_to_linejoin($self->{join_style}) . "; ";
	# cap_style
	$style .= ConvertSVG::cap_style_to_linecap($self->{cap_style});

	# end of style
	$style .= "\"";

	# points
	my $points = "points=\"";
	for (0 .. $self->{npoints}-1) {
	    $points .= $self->{xnpoints}[$_];
	    $points .= " ";
	    $points .= $self->{ynpoints}[$_];
	    if ($_ < $self->{npoints}-1) { $points .= ", "; }
	}
	$points .= "\"";

	print $fh "<polygon $points $style";

	if ($#{$self->{animations}} >= 0) { # SVG + SMIL
	    print $fh ">\n";
	    for (my $i = 0; $i <= $#{$self->{animations}}; $i++) {
		print $fh "\t";
		my $smil = ConvertSMIL::smil($self->{animations}[$i]);
		print $fh $smil;
		print $fh "\n";
	    }
	    print $fh "</polygon>\n\n";
	} else { # SVG only
	    print $fh " />\n\n";
	}

    } elsif ($self->{sub_type} == 4) { # arc-box

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
	# join_style
	$style .= ConvertSVG::join_style_to_linejoin($self->{join_style}) . "; ";
	# cap_style
	$style .= ConvertSVG::cap_style_to_linecap($self->{cap_style});

	# end of style
	$style .= "\"";

	my $top = ConvertSVG::min($self->{ynpoints}[0],
				  $self->{ynpoints}[1],
				  $self->{ynpoints}[2],
				  $self->{ynpoints}[3]);
	my $left = ConvertSVG::min($self->{xnpoints}[0],
				   $self->{xnpoints}[1],
				   $self->{xnpoints}[2],
				   $self->{xnpoints}[3]);
	my $bottom = ConvertSVG::max($self->{ynpoints}[0],
				     $self->{ynpoints}[1],
				     $self->{ynpoints}[2],
				     $self->{ynpoints}[3]);
	my $right = ConvertSVG::max($self->{xnpoints}[0],
				    $self->{xnpoints}[1],
				    $self->{xnpoints}[2],
				    $self->{xnpoints}[3]);

	my $x = "x=\"" . $left . "\"";
	my $y = "y=\"" . $top . "\"";

	my $width = "width=\"" . ($right - $left) . "\"";
	my $height = "height=\"" . ($bottom - $top) . "\"";

	my $rx = "rx=\"" . $self->{radius} * 15 . "\"";
	my $ry = "ry=\"" . $self->{radius} * 15 . "\"";

	print $fh "<rect $x $y $width $height $rx $ry $style";

	if ($#{$self->{animations}} >= 0) { # SVG + SMIL
	    print $fh ">\n";
	    for (my $i = 0; $i <= $#{$self->{animations}}; $i++) {
		print $fh "\t";
		my $smil = ConvertSMIL::smil($self->{animations}[$i]);
		print $fh $smil;
		print $fh "\n";
	    }
	    print $fh "</rect>\n\n";
	} else { # SVG only
	    print $fh " />\n\n";
	}

    } elsif ($self->{sub_type} == 5) { # imported-picture bounding-box

	# end of style
	$style .= "\"";

	my $top = ConvertSVG::min($self->{ynpoints}[0],
				  $self->{ynpoints}[1],
				  $self->{ynpoints}[2],
				  $self->{ynpoints}[3]);
	my $left = ConvertSVG::min($self->{xnpoints}[0],
				   $self->{xnpoints}[1],
				   $self->{xnpoints}[2],
				   $self->{xnpoints}[3]);
	my $bottom = ConvertSVG::max($self->{ynpoints}[0],
				     $self->{ynpoints}[1],
				     $self->{ynpoints}[2],
				     $self->{ynpoints}[3]);
	my $right = ConvertSVG::max($self->{xnpoints}[0],
				    $self->{xnpoints}[1],
				    $self->{xnpoints}[2],
				    $self->{xnpoints}[3]);

	my $x = "x=\"" . $left . "\"";
	my $y = "y=\"" . $top . "\"";

	my $width = "width=\"" . ($right - $left) . "\"";
	my $height = "height=\"" . ($bottom - $top) . "\"";

	# file
	my $xlink = "xlink:href=\"" . @$self{'file'} . "\"";

	# flipped
	my $transform = "";
	if ($self->{flipped} == 1) {
	    $transform =
		"transform=\"" .
		"translate(" .
		($self->{xnpoints}[2] - $self->{xnpoints}[0]) .
		", 0), " .
		"rotate(90, " .
		$self->{xnpoints}[0] . ", " .
		$self->{ynpoints}[0] . ")\"";
	}

	print $fh "<image $xlink $x $y $width $height $transform";

	if ($#{$self->{animations}} >= 0) { # SVG + SMIL
	    print $fh ">\n";
	    for (my $i = 0; $i <= $#{$self->{animations}}; $i++) {
		print $fh "\t";
		my $smil = ConvertSMIL::smil($self->{animations}[$i]);
		print $fh $smil;
		print $fh "\n";
	    }
	    print $fh "</image>\n\n";
	} else { # SVG only
	    print $fh " />\n\n";
	}
    }
}


1;
