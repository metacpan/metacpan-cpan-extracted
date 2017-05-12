package ConvertSVG;

# SVG styles and tags generator

use strict;
use warnings;


# returns the min of the values
sub min {
    my $min = $_[0];
    for (my $i = 0; $i < scalar @_; $i++) {
	if ($_[$i] < $min) { $min = $_[$i]; }
    }
    return $min;
}


# return the max of the values
sub max {
    my $max = $_[0];
    for (my $i = 0; $i < scalar @_; $i++) {
	if ($_[$i] > $max) { $max = $_[$i]; }
    }
    return $max;
}


# converts paper size into cm/in with viewBox
sub papersize_to_units {
    my ($papersize, $orientation, $magnification, $resolution) = @_;

    # removes spaces at the end of the string
    $papersize =~ s/\s*$//;

    my %paperdef =
	("Letter" => [8.5, 11, 'in'],
	 "Legal" => [8.5, 14, 'in'],
	 "Tabloid" => [11, 17, 'in'],
	 "A" => [8.5, 11, 'in'],
	 "B" => [11, 17, 'in'],
	 "C" => [17, 22, 'in'],
	 "D" => [22, 34, 'in'],
	 "E" => [34, 44, 'in'],
	 "A9" => [37, 52, 'mm'],
	 "A8" => [52, 74, 'mm'],
	 "A7" => [74, 105, 'mm'],
	 "A6" => [105, 148, 'mm'],
	 "A5" => [148, 210, 'mm'],
	 "A4" => [210, 297, 'mm'],
	 "A3" => [297, 420, 'mm'],
	 "A2" => [420, 594, 'mm'],
	 "A1" => [594, 841, 'mm'],
	 "A0" => [841, 1189, 'mm'],
	 "B10" => [32, 45, 'mm'],
	 "B9" => [45, 64, 'mm'],
	 "B8" => [64, 91, 'mm'],
	 "B7" => [91, 128, 'mm'],
	 "B6" => [128, 182, 'mm'],
	 "B5" => [182, 257, 'mm'],
	 "B4" => [257, 364, 'mm'],
	 "B3" => [364, 515, 'mm'],
	 "B2" => [515, 728, 'mm'],
	 "B1" => [728, 1030, 'mm'],
	 "B0" => [1030, 1456, 'mm']);

    my $width = $paperdef{$papersize}[0];
    my $height = $paperdef{$papersize}[1];
    my $unit = $paperdef{$papersize}[2];
    my $w = ($width * $magnification / 100) . $unit;
    my $h = ($height * $magnification / 100) . $unit;
    my $vb_w = $width * $resolution;
    my $vb_h = $height * $resolution;
    if ($unit eq 'mm') {
	$vb_w = int($vb_w / 25.4);
	$vb_h = int($vb_h / 25.4);
    }

    if ($orientation eq "Landscape") { # Landscape
	return "width=\"$h\" height=\"$w\" viewBox=\"0 0 $vb_h $vb_w\"";
    } else { # Portrait
	return "width=\"$w\" height=\"$h\" viewBox=\"0 0 $vb_w $vb_h\"";
    }
}

# converts FIG pen and fill colors into SVG value: #rrggbb
sub pen_fill_colors_to_rgb {
    my ($color, $colors) = @_;
    my %table =
	(-1 => "#000000", # Default
	 0 => "#000000", # Black
	 1 => "#0000ff", # Blue
	 2 => "#00ff00", # Green
	 3 => "#00ffff", # Cyan
	 4 => "#ff0000", # Red
	 5 => "#ff00ff", # Magenta
	 6 => "#ffff00", # Yellow
	 7 => "#ffffff", # White
	 8 => "#000090", # Blue4
	 9 => "#0000b0", # Blue3
	 10 => "#0000d0", # Blue2
	 11 => "#87ceff", # LtBlue
	 12 => "#009000", # Green4
	 13 => "#00b000", # Green3
	 14 => "#00d000", # Green2
	 15 => "#009090", # Cyan4
	 16 => "#00b0b0", # Cyan3
	 17 => "#00d0d0", # Cyan2
	 18 => "#900000", # Red4
	 19 => "#b00000", # Red3
	 20 => "#d00000", # Red2
	 21 => "#900090", # Magenta4
	 22 => "#b000b0", # Magenta3
	 23 => "#d000d0", # Magenta2
	 24 => "#803000", # Brown4
	 25 => "#a04000", # Brown3
	 26 => "#c06000", # Brown2
	 27 => "#ff8080", # Pink4
	 28 => "#ffa0a0", # Pink3
	 29 => "#ffc0c0", # Pink2
	 30 => "#ffe0e0", # Pink
	 31 => "#ffd700"); # Gold

    if ($color >= 32) { # user colors
	for (0 .. scalar(@$colors)-1) {
	    if (@$colors[$_]->{color_number} == $color) {
		return @$colors[$_]->{rgb};
	    }
	}
    } else {
	return $table{$color};
    }
}

# converts FIG area fill into SVG style: fill
sub area_fill_to_fill {
    my ($area_fill, $color, $colors) = @_;

    if ($color == 7) { # White
	if ($area_fill == -1) { # not filled
	    return "fill: none";
	} elsif ($area_fill == 0) { # black
	    return "fill: #000000";
	} elsif (($area_fill >= 1) && ($area_fill <= 19)) { # shades
	    my $c = int((255/20)*$area_fill);
	    $c = sprintf "%02x", $c;
	    return "fill: #" . $c . $c . $c;
	} elsif ($area_fill == 20) { # white
	    return "fill: #ffffff";
	} elsif (($area_fill >= 21) && ($area_fill <= 40)) { # not used
	    return "fill: none";
	} elsif (($area_fill >= 41) && ($area_fill <= 56)) { # patterns
	    return "fill: #ffffff";
	}

    } elsif (($color == 0) || ($color == -1)) { # Black or Default
	if ($area_fill == -1) { # not filled
	    return "fill: none";
	} elsif ($area_fill == 0) { # white
	    return "fill: #ffffff";
	} elsif (($area_fill >= 1) && ($area_fill <= 19)) { # shades
	    my $c = int((-255/20)*$area_fill + 255);
	    $c = sprintf "%02x", $c;
	    return "fill: #" . $c . $c . $c;
	} elsif ($area_fill == 20) { # black
	    return "fill: #000000";
	} elsif (($area_fill >= 21) && ($area_fill <= 40)) { # not used
	    return "fill: none";
	} elsif (($area_fill >= 41) && ($area_fill <= 56)) { # patterns
	    return "fill: #000000";
	}

    } else { # other colors
	if ($area_fill == -1) { # not filled
	    return "fill: none";
	} elsif ($area_fill == 0) { # black
	    return "fill: #000000";
	} elsif (($area_fill >= 1) && ($area_fill <= 19)) { # shades
	    my $c = pen_fill_colors_to_rgb($color, $colors);
	    my $r = hex(substr($c, 1, 2));
	    my $g = hex(substr($c, 3, 2));
	    my $b = hex(substr($c, 5, 2));
	    $r = int(($r/20)*$area_fill);
	    $g = int(($g/20)*$area_fill);
	    $b = int(($b/20)*$area_fill);
	    $r = sprintf "%02x", $r;
	    $g = sprintf "%02x", $g;
	    $b = sprintf "%02x", $b;
	    return "fill: #" . $r . $g . $b;
	} elsif ($area_fill == 20) { # full saturation
	    return "fill: " . pen_fill_colors_to_rgb($color, $colors);
	} elsif (($area_fill >= 21) && ($area_fill <= 39)) { # tints
	    my $c = pen_fill_colors_to_rgb($color, $colors);
	    my $r = hex(substr($c, 1, 2));
	    my $g = hex(substr($c, 3, 2));
	    my $b = hex(substr($c, 5, 2));
	    $r = int(((255-$r)/20)*$area_fill + (2*$r - 255));
	    $g = int(((255-$g)/20)*$area_fill + (2*$g - 255));
	    $b = int(((255-$b)/20)*$area_fill + (2*$b - 255));
	    $r = sprintf "%02x", $r;
	    $g = sprintf "%02x", $g;
	    $b = sprintf "%02x", $b;
	    return "fill: #" . $r . $g . $b;
	} elsif ($area_fill == 40) { # white
	    return "fill: #ffffff";
	} elsif (($area_fill >= 41) && ($area_fill <= 56)) { # patterns
	    return "fill: " . pen_fill_colors_to_rgb($color, $colors);
	}
    }
}

# converts FIG line styles into SVG styles: stroke, stroke-dasharray
sub line_style_to_stroke {
    my ($line_style, $style_val, $color, $colors) = @_;
    if ($line_style == -1) {
	return "stroke: black";

    } elsif ($line_style == 0) {
	return "stroke: " . pen_fill_colors_to_rgb($color, $colors);

    } elsif ($line_style == 1) {
	return
	    "stroke: " .
	    pen_fill_colors_to_rgb($color, $colors) .
	    "; " .
	    "stroke-dasharray: " .
	    thickness_to_value($style_val) . ", " .
	    thickness_to_value($style_val) . "; ";

    } elsif ($line_style == 2) {
	return
	    "stroke: " .
	    pen_fill_colors_to_rgb($color, $colors) .
	    "; " .
	    "stroke-dasharray: " .
	    1 . ", " .
	    thickness_to_value($style_val) . "; ";

    } elsif ($line_style == 3) {
	return
	    "stroke: " .
	    pen_fill_colors_to_rgb($color, $colors) .
	    "; " .
	    "stroke-dasharray: " .
	    thickness_to_value($style_val) . ", " .
	    thickness_to_value($style_val) / 2 . ", " .
	    1 . ", " .
	    thickness_to_value($style_val) / 2 . "; ";

    } elsif ($line_style == 4) {
	return
	    "stroke: " .
	    pen_fill_colors_to_rgb($color, $colors) .
	    "; " .
	    "stroke-dasharray: " .
	    thickness_to_value($style_val) . ", " .
	    thickness_to_value($style_val) / 2 . ", " .
	    1 . ", " .
	    thickness_to_value($style_val) / 2 . ", " .
	    1 . ", " .
	    thickness_to_value($style_val) / 2 . "; ";

    } elsif ($line_style == 5) {
	return
	    "stroke: " .
	    pen_fill_colors_to_rgb($color, $colors) .
	    "; " .
	    "stroke-dasharray: " .
	    thickness_to_value($style_val) . ", " .
	    thickness_to_value($style_val) / 2 . ", " .
	    1 . ", " .
	    thickness_to_value($style_val) / 2 . ", " .
	    1 . ", " .
	    thickness_to_value($style_val) / 2 . ", " .
	    1 . ", " .
	    thickness_to_value($style_val) / 2 . "; ";
    }
}

# converts FIG thickness into SVG value
sub thickness_to_value {
    my ($thickness) = @_;
    return $thickness * 15;
}

# converts FIG line thickness into SVG style: stroke-width
sub thickness_to_stroke {
    my ($thickness) = @_;
    return
	"stroke-width: " .
	thickness_to_value($thickness);
}

# converts FIG join_style into SVG style: stroke-linejoin
sub join_style_to_linejoin {
    my ($join_style) = @_;
    if ($join_style == 0) {
	return "stroke-linejoin: miter";
    } elsif ($join_style == 1) {
	return "stroke-linejoin: round";
    } elsif ($join_style == 2) {
	return "stroke-linejoin: bevel";
    }
}

# converts FIG cap_style into SVG style: stroke-linecap
sub cap_style_to_linecap {
    my ($cap_style) = @_;
    if ($cap_style == 0) {
	return "stroke-linecap: butt";
    } elsif ($cap_style == 1) {
	return "stroke-linecap: round";
    } elsif ($cap_style == 2) {
	return "stroke-linecap: square";
    }
}

# converts rad into deg
sub rad_to_deg {
    my ($rad) = @_;
    return -1 * (180 / 3.14) * $rad;
}

# converts FIG arrows into SVG markers+paths
sub arrows_to_markers {
    my ($arrow_name,
	$direction,
	$orientation,
	$arrow_type,
	$arrow_style,
	$arrow_thickness,
	$arrow_width,
	$arrow_height,
	$pen_color,
	$colors) = @_;

    my $width = int($arrow_height);
    my $height = int($arrow_width);

    my $thick = thickness_to_value($arrow_thickness);

    my $id = "id=\"$arrow_name";
    $id .= "\"";

    my $markerUnits = "markerUnits=\"userSpaceOnUse\"";
    my $orient = "orient=\"" . $orientation . "\"";

    my $markerWidth = "markerWidth=\"" . ($width+2*$thick) . "\"";
    my $markerHeight = "markerHeight=\"" . ($height+2*$thick) . "\"";

    my $refX = "";
    my $refY = "";

    if ($direction == 1) {
	$refX = "refX=\"" . ($thick+$width) . "\"";
    } else {
	$refX = "refX=\"" . $thick . "\"";
    }

    $refY = "refY=\"" . ($thick+$height/2) . "\"";

    my $marker =
	"<marker $id " .
	"$markerUnits " .
	"$orient " .
	"$markerWidth " . "$markerHeight " .
	"$refX " . "$refY " . ">\n";

    # converts FIG arrows into SVG paths

    my $d = "d=\"";
    my $style =	"style=\"";

    $style .=
	"stroke: " . pen_fill_colors_to_rgb($pen_color, $colors) .
	"; " .
	thickness_to_stroke($arrow_thickness) . "; ";

    if ($arrow_type == 0) {
	if ($direction == 1) {
	    $d .=
		"M " . $thick . " " . ($thick+$height) . ", " .
		"L " . ($thick+$width) . " " . int($thick+$height/2) . ", " .
		"L " . $thick . " " . $thick;
	} else {
	    $d .=
		"M " . ($thick+$width) . " " . $thick . ", " .
		"L " . $thick . " " . int($thick+$height/2) . ", " .
		"L " . ($thick+$width) . " " . ($thick+$height);
	}

    } elsif($arrow_type == 1) {
	if ($direction == 1) {
	    $d .=
		"M " . $thick . " " . ($thick+$height) . ", " .
		"L " . ($width+$thick) . " " . int($thick+$height/2) . ", " .
		"L " . $thick . " " . $thick . ", " .
		"Z";
	} else {
	    $d .=
		"M " . ($thick+$width) . " " . $thick . ", " .
		"L " . $thick . " " . int($thick+$height/2) . ", " .
		"L " . ($thick+$width) . " " . ($thick+$height) . ", " .
		"Z";
	}

    } elsif($arrow_type == 2) {
	if ($direction == 1) {
	    $d .=
		"M " . $thick . " " . ($thick+$height) . ", " .
		"L " . int($width+$thick) . " " . int($thick+$height/2) . ", " .
		"L " . $thick . " " . $thick . ", " .
		"L " . ($thick+$width/3) . " " . ($thick+$height/2) . ", " .
		"Z";
	} else {
	    $d .=
		"M " . ($thick+$width) . " " . $thick . ", " .
		"L " . $thick . " " . int($thick + $height/2) . ", " .
		"L " . ($thick+$width) . " " . ($thick+$height) . ", " .
		"L " . int($thick+2*$width/3) . " " . int($thick+$height/2) . ", " .
		"Z";
	}

    } elsif($arrow_type == 3) {
	if ($direction == 1) {
	    $d .=
		"M " . int($thick+$width/3) . " " . ($thick+$height) . ", " .
		"L " . int($width+$thick) . " " . int($thick+$height/2) . ", " .
		"L " . int($thick+$width/3) . " " . $thick . ", " .
		"L " . $thick . " " . int($thick+$height/2) . ", " .
		"Z";
	} else {
	    $d .=
		"M " . int($thick+2*$width/3) . " " . $thick . ", " .
		"L " . $thick . " " . int($thick+$height/2) . ", " .
		"L " . int($thick+2*$width/3) . " " . ($thick+$height) . ", " .
		"L " . ($thick+$width) . " " . int($thick+$height/2) . ", " .
		"Z";
	}
    }

    # fills arrow with pen color
    if ($arrow_type == 0) {
	$style .= "fill: none";
    } else {
	if ($arrow_style == 0) {
	    $style .= "fill: white";
	} else {
	    $style .=
		"fill: " .
		pen_fill_colors_to_rgb($pen_color, $colors);
	}
    }

    $d .= "\"";
    $style .= "\"";

    $marker .= "\t<path $d $style />\n";

    $marker .= "</marker>\n";

    return $marker;
}

# converts FIG font into SVG styles
sub font_flags_to_font {
    my ($font_flags, $font) = @_;

    my %postscript_fonts =
	(0 => "serif",
	 1 => "serif",
	 2 => "serif",
	 3 => "serif",
	 4 => "'Avant Garde'",
	 5 => "'Avant Garde'",
	 6 => "'Avant Garde'",
	 7 => "'Avant Garde'",
	 8 => "Bookman",
	 9 => "Bookman",
	 10 => "Bookman",
	 11 => "Bookman",
	 12 => "monospace",
	 13 => "monospace",
	 14 => "monospace",
	 15 => "monospace",
	 16 => "sans-serif",
	 17 => "sans-serif",
	 18 => "sans-serif",
	 19 => "sans-serif",
	 20 => "sans-serif",
	 21 => "sans-serif",
	 22 => "sans-serif",
	 23 => "sans-serif",
	 24 => "'new century schoolbook'",
	 25 => "'new century schoolbook'",
	 26 => "'new century schoolbook'",
	 27 => "'new century schoolbook'",
	 28 => "Palatino",
	 29 => "Palatino",
	 30 => "Palatino",
	 31 => "Palatino",
	 32 => "Symbol",
	 33 => "cursive",
	 34 => "cursive");

    my $font_flags_bit0 = $font_flags % 2;
    my $font_flags_bit1 = int($font_flags/2) % 2;
    my $font_flags_bit2 = int($font_flags/(2*2)) % 2;
    my $font_flags_bit3 = int($font_flags/(2*2*2)) % 2;

    my $svg_font = "";

    if ($font_flags_bit2 == 0) { # LaTeX fonts

	if ($font == 1) {
	    $svg_font = "font-family: serif; ";
	} elsif ($font == 2) {
	    $svg_font .= "font-weight: bold";
	} elsif ($font == 3) {
	    $svg_font .= "font-style: italic";
	} elsif ($font == 4) {
	    $svg_font .= "font-family: sans-serif";
	} elsif ($font == 5) {
	    $svg_font .= "font-family: monospace";
	}


    } else { # PostScript fonts

	if (($font >= 1) && ($font <= 34)) {
	    $svg_font = "font-family: " . $postscript_fonts{$font} . "; ";
	}

	# Italic
	if (($font == 1) ||
	    ($font == 3) ||
	    ($font == 9) ||
	    ($font == 11) ||
	    ($font == 25) ||
	    ($font == 27) ||
	    ($font == 29) ||
	    ($font == 31) ||
	    ($font == 33)) {
	    $svg_font .= "font-style: italic; ";
	}

	# Bold
	if (($font == 2) ||
	    ($font == 3) ||
	    ($font == 14) ||
	    ($font == 15) ||
	    ($font == 18) ||
	    ($font == 19) ||
	    ($font == 22) ||
	    ($font == 23) ||
	    ($font == 26) ||
	    ($font == 27) ||
	    ($font == 30) ||
	    ($font == 31)) {
	    $svg_font .= "font-weight: bold; ";
	}

	# Oblique
	if (($font == 5) ||
	    ($font == 7) ||
	    ($font == 13) ||
	    ($font == 15) ||
	    ($font == 17) ||
	    ($font == 19) ||
	    ($font == 21) ||
	    ($font == 23)) {
	    $svg_font .= "font-style: oblique; "; 
	}

	# Narrow
	if (($font == 20) ||
	    ($font == 21) ||
	    ($font == 22) ||
	    ($font == 23)) {
	    $svg_font .= "font-stretch: narrower; "; 
	}
    }

    return $svg_font;
}


# return
1;
