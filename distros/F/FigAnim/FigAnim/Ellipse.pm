package Ellipse;

=head1 NAME

Ellipse - A XFig file animator class - Ellipse object

=head1 DESCRIPTION

Ellipse object - object code in FIG format: 1.
Here are all the attributes of this class:

B<sub_type, line_style, thickness, pen_color, fill_color, depth, pen_style,
area_fill, style_val, direction, angle, center_x, center_y, radius_x, radius_y,
start_x, start_y, end_x, end_y>

=head1 FIG ATTRIBUTES

=over

=item sub_type

1: ellipse defined by radii;
2: ellipse defined by diameters;
3: circle defined by radius;
4: circle defined by diameter.

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

=item direction

always 1

=item angle

radians, the angle of the x-axis

=item center_x, center_y

Fig units

=item radius_x, radius_y

Fig units

=item start_x, start_y

Fig units; the 1st point entered

=item end_x, end_y

Fig units; the last point entered

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
    
    #$self->{object_code} = 1;
    $self->{sub_type} = shift;
    $self->{line_style} = shift;
    $self->{thickness} = shift;
    $self->{pen_color} = shift;
    $self->{fill_color} = shift;
    $self->{depth} = shift;
    $self->{pen_style} = shift;
    $self->{area_fill} = shift;
    $self->{style_val} = shift;
    $self->{direction} = shift;
    $self->{angle} = shift;
    $self->{center_x} = shift;
    $self->{center_y} = shift;
    $self->{radius_x} = shift;
    $self->{radius_y} = shift;
    $self->{start_x} = shift;
    $self->{start_y} = shift;
    $self->{end_x} = shift;
    $self->{end_y} = shift;
    
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
    my $obj = new Ellipse;
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
	"1 %d %d %d %d %d %d %d %d %.3f %d %.4f %d %d %d %d %d %d %d %d\n",
	@$self{'sub_type','line_style','thickness','pen_color','fill_color',
	       'depth','pen_style','area_fill','style_val','direction','angle',
	       'center_x','center_y','radius_x','radius_y','start_x','start_y',
	       'end_x','end_y'};
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
    my @anim = (11, $self->{name}, shift, shift, shift, shift, shift);
    $anim[6] = '' if (!(defined $anim[6]));
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub rotate {
    my $self = shift;
    my @anim = (21, $self->{name}, shift, shift, shift, shift, shift, shift);
    if (!((defined $anim[5]) && (defined $anim[6]))) {
	$anim[5] = $self->{center_x};
	$anim[6] = $self->{center_y};
    }
    $anim[7] = '' if (!(defined $anim[7]));
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub scale {
    my $self = shift;
    my @anim = (31, $self->{name}, shift, shift, shift, shift, shift);
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
					    $colors);

    # end of style
    $style .= "\"";

    # direction

    # angle

    # center_x
    my $cx = "cx=\"" . $self->{center_x} . "\"";

    # center_y
    my $cy = "cy=\"" . $self->{center_y} . "\"";

    if (($self->{'sub_type'} == 1) ||
	($self->{'sub_type'} == 2)) { # ellipse

	# radius_x
	my $rx = "rx=\"" . $self->{radius_x} . "\"";

	# radius_y
	my $ry = "ry=\"" . $self->{radius_y} . "\"";

	# angle
	my $angle = ConvertSVG::rad_to_deg($self->{angle});
	my $transform = "";
	if ($angle != 0) {
	    $transform =
		"transform=\"rotate($angle, " .
		$self->{center_x} . ", " .
		$self->{center_y} .
		")\"";
	}

	print $fh "<ellipse $cx $cy $rx $ry $style $transform";

    } elsif (($self->{'sub_type'} == 3) ||
	     ($self->{'sub_type'} == 4)) { # circle

	# radius
	my $r = "r=\"" . $self->{radius_x} . "\"";;

	print $fh "<circle $cx $cy $r $style";
    }

    if ($#{$self->{animations}} >= 0) { # SVG + SMIL
	print $fh ">\n";
	for (my $i = 0; $i <= $#{$self->{animations}}; $i++) {
	    print $fh "\t";
	    my $smil = ConvertSMIL::smil($self->{animations}[$i]);
	    print $fh $smil;
	    print $fh "\n";
	}

	if (($self->{'sub_type'} == 1) ||
	    ($self->{'sub_type'} == 2)) { # ellipse
	    print $fh "</ellipse>\n\n";
	} elsif (($self->{'sub_type'} == 3) ||
		 ($self->{'sub_type'} == 4)) { # circle
	    print $fh "</circle>\n\n";
	}

    } else { # SVG only
	print $fh " />\n\n";
    }

}



1;
