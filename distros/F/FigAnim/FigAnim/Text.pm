package Text;

=head1 NAME

Text - A XFig file animator class - Text object

=head1 DESCRIPTION

Text object - object code in FIG format: 4.
Here are all the attributes of this class:

B<sub_type, pen_color, depth, pen_style, font, font_size, angle, font_flags,
height, length, x, y, text, visibility, center_x, center_y>

=head1 FIG ATTRIBUTES

=over

=item sub_type

0: Left justified;
1: Center justified;
2: Right justified.

=item pen_color

-1..31: FIG colors;
32..543 (512 total): user colors.

=item depth

0 ... 999: larger value means object is deeper than (under)
objects with smaller depth

=item pen_style

unused

=item font

For font_flags bit 2 = 0 (LaTeX fonts):
0: Default font;
1: Roman;
2: Bold;
3: Italic;
4: Sans Serif;
5: Typewriter.

For font_flags bit 2 = 1 (PostScript fonts):
-1: Default font;
0: Times Roman;
1: Times Italic;
2: Times Bold;
3: Times Bold Italic;
4: AvantGarde Book;
5: AvantGarde Book Oblique;
6: AvantGarde Demi;
7: AvantGarde Demi Oblique;
8: Bookman Light;
9: Bookman Light Italic;
10: Bookman Demi;
11: Bookman Demi Italic;
12: Courier;
13: Courier Oblique;
14: Courier Bold;
15: Courier Bold Oblique;
16: Helvetica;
17: Helvetica Oblique;
18: Helvetica Bold;
19: Helvetica Bold Oblique;
20: Helvetica Narrow;
21: Helvetica Narrow Oblique;
22: Helvetica Narrow Bold;
23: Helvetica Narrow Bold Oblique;
24: New Century Schoolbook Roman;
25: New Century Schoolbook Italic;
26: New Century Schoolbook Bold;
27: New Century Schoolbook Bold Italic;
28: Palatino Roman;
29: Palatino Italic;
30: Palatino Bold;
31: Palatino Bold Italic;
32: Symbol;
33: Zapf Chancery Medium Italic;
34: Zapf Dingbats.

=item font_size

font size in points

=item angle

radians, the angle of the text

=item font_flags

bit0: Rigid text (text doesn't scale when scaling compound objects);
bit1: Special text (for LaTeX);
bit2: PostScript font (otherwise LaTeX font is used);
bit3: Hidden text.

=item height, length

Fig units

=item x, y

Fig units, coordinate of the origin of the string.
If sub_type = 0, it is the lower left corner of the string.
If sub_type = 1, it is the lower center.
Otherwise it is the lower right corner of the string.

=item text

ASCII characters;
starts after a blank character following the last number and
ends before the sequence '\001'.  This sequence is not part of the string.
Characters above octal 177 are represented by \xxx where xxx is the
octal value.  This permits fig files to be edited with 7-bit editors and sent
by e-mail without data loss. Note that the string may contain '\n'.

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

# constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    
    $self->{name} = shift; # object's name in comment
    
    #$self->{object_code} = 4;
    $self->{sub_type} = shift;
    $self->{pen_color} = shift;
    $self->{depth} = shift;
    $self->{pen_style} = shift;
    $self->{font} = shift;
    $self->{font_size} = shift;
    $self->{angle} = shift;
    $self->{font_flags} = shift;
    $self->{height} = shift;
    $self->{length} = shift;
    $self->{x} = shift;
    $self->{y} = shift;
    $self->{text} = shift;
    
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
    my $obj = new Text;
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
    
    printf $fh "4 %d %d %d %d %d %g %.4f %d %g %g %d %d %s\\001\n",
	@$self{'sub_type','pen_color','depth','pen_style','font','font_size',
	       'angle','font_flags','height','length','x','y','text'};
}

sub calculateCenter {
    my $self = shift;
    if ($self->{sub_type} == 0) {
	$self->{center_x} = $self->{x} + sprintf("%.0f", $self->{length} / 2);
    } elsif ($self->{sub_type} == 1) {
	$self->{center_x} = $self->{x};
    } else {
	$self->{center_x} = $self->{x} - sprintf("%.0f", $self->{length} / 2);
    }
    $self->{center_y} = $self->{y} + sprintf("%.0f", $self->{height} / 2);
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

sub translate {
    my $self = shift;
    my @anim = (14, $self->{name}, shift, shift, shift, shift, shift);
    $anim[6] = '' if (!(defined $anim[6]));
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub rotate {
    my $self = shift;
    my @anim = (24, $self->{name}, shift, shift, shift, shift, shift, shift);
    if (!((defined $anim[5]) && (defined $anim[6]))) {
	$anim[5] = $self->{center_x};
	$anim[6] = $self->{center_y};
    }
    $anim[7] = '' if (!(defined $anim[7]));
    push @{$self->{fig_file}->{animations}}, \@anim;
}

sub scale {
    my $self = shift;
    my @anim = (34, $self->{name}, shift, shift, shift, shift, shift);
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

    # sub_type
    if ($self->{sub_type} == 0) { $style .= "text-anchor: start; "; }
    elsif ($self->{sub_type} == 1) { $style .= "text-anchor: middle; "; }
    elsif($self->{sub_type} == 2) { $style .= "text-anchor: end; "; }

    # color
    $style .=
	"fill: " .
	ConvertSVG::pen_fill_colors_to_rgb($self->{pen_color}, $colors) .
	"; ";

    # font_size
    $style .= "font-size: " . ($self->{font_size} * 12) . "; ";

    # font 
    $style .= ConvertSVG::font_flags_to_font($self->{font_flags},
					     $self->{font});

    # end of style
    $style .= "\"";

    # x
    my $x = "x=\"" . $self->{x} . "\"";

    # y
    my $y = "y=\"" . $self->{y} . "\"";

    # angle
    my $angle = ConvertSVG::rad_to_deg($self->{angle});
    my $transform = "";
    if ($angle != 0) {
	$transform =
	    "transform=\"rotate($angle, " .
	    $self->{x} . ", " .
	    $self->{y} .
	    ")\"";
    }

    my $text = $self->{text};

    print $fh "<text $x $y $style $transform>\n";

    for (my $i = 0; $i <  length($text); $i++) {
	my $char = substr($text, $i, 1);

	if ($char eq "&") {
	    $char = "&amp;";
	} elsif ($char eq "<") {
	    $char = "&lt;";
	} elsif ($char eq ">") {
	    $char = "&gt;";
	}

	my $char_code = substr($text, $i, 4);
	if ($char_code =~ m/\\\d{3}/) {
	    $char = substr($char_code, 1, 3);

	    $char =
		substr($char, 0, 1)*8*8 +
		substr($char, 1, 1)*8 +
		substr($char, 2, 1);

	    $char = sprintf("\&\#%03u;", $char);

	    $i += 3;
	}

	print $fh $char;
    }

    print $fh "\n";

    if ($#{$self->{animations}} >= 0) { # SVG + SMIL
	for (my $i = 0; $i <= $#{$self->{animations}}; $i++) {
	    print $fh "\t";
	    my $smil = ConvertSMIL::smil($self->{animations}[$i]);
	    print $fh $smil;
	    print $fh "\n";
	}
    }

    print $fh "</text>\n\n"
}




1;
