package ConvertSMIL;

# SMIL tags generator

use strict;
use warnings;


sub smil {
    if ($_[0][0] == 1) {
	return changeThickness($_[0][1], # from
			       $_[0][2], # to
			       $_[0][3], # begin
			       $_[0][4]); # dur

    } elsif (($_[0][0] >= 11) && ($_[0][0] <= 16)) {
	return translate($_[0][1], $_[0][2], # begin, dur
			 $_[0][3], $_[0][4], # x, y
			 $_[0][5]); # unit

    } elsif (($_[0][0] >= 21) && ($_[0][0] <= 26)) {
	return rotate($_[0][1], $_[0][2], # begin, dur
		      $_[0][3], # angle
		      $_[0][4], $_[0][5], # x, y
		      $_[0][6]); # unit

    } elsif (($_[0][0] >= 31) && ($_[0][0] <= 36)) {
	return scale($_[0][1], $_[0][2], # begin, dur
		     $_[0][3], # factor
		     $_[0][4], $_[0][5]); # x, y

    } elsif ($_[0][0] == 2) {
	return changeFillIntensity($_[0][1], $_[0][2], # begin, dur
				   $_[0][3], $_[0][4], # from, to
				   $_[0][5], $_[0][6]); # color, colors

    } elsif ($_[0][0] == 0) {
	return setAttributeValue($_[0][1], $_[0][2], # begin, dur
				 $_[0][3], $_[0][4]); # attribute, value

    } else {
	return "";
    }
}


sub setAttributeValue {
    my ($begin, $dur, $attribute, $value, $colors) = @_;

    my $attributeType;
    my $attributeName;
    my $to;

    if ($attribute eq "visibility") {
	$attributeType = "CSS";
	$attributeName = "visibility";
	if ($value == 0) { $to = "hidden"; }
	else { $to = "visible"; }

    } elsif ($attribute eq "pen_color")  {
	$attributeType = "CSS";
	$attributeName = "stroke";
	$to = ConvertSVG::pen_fill_colors_to_rgb($value, $colors);

    } elsif ($attribute eq "fill_color")  {
	$attributeType = "CSS";
	$attributeName = "fill";
	$to = ConvertSVG::pen_fill_colors_to_rgb($value, $colors);

    } else {
	# error
    }

    if ($attributeName) {
	return
	    "<set attributeName=\"" . $attributeName . "\" " .
	    "attributeType=\"" . $attributeType . "\" " .
	    "to=\"" . $to . "\" " .
	    "begin=\"" . $begin . "s\" " .
	    "dur=\"0s\" " .
	    "fill=\"freeze\" " .
	    "/>";
    } else {
	# error
	return "";
    }
}

sub changeThickness {
    my ($from, $to, $begin, $dur) = @_;
    return
	"<animate attributeName=\"stroke-width\" attributeType=\"CSS\" " .
	"from=\"" . ConvertSVG::thickness_to_value($from) . "\" " . 
	"to=\"" . ConvertSVG::thickness_to_value($to) . "\" " .
	"begin=\"" . $begin . "s\" " .
	"dur=\"" . $dur . "s\" " .
	"fill=\"freeze\" " .
	"/>";
}

sub changeFillIntensity {
    my ($begin, $dur, $from, $to, $color, $colors) = @_;

    $from = ConvertSVG::area_fill_to_fill($from, $color, $colors);
    $to = ConvertSVG::area_fill_to_fill($to, $color, $colors);

    $from =~ s/fill: //;
    $to =~ s/fill: //;

    return
	"<animateColor attributeName=\"fill\" attributeType=\"CSS\" " .
	"begin=\"" . $begin . "s\" " .
	"dur=\"" . $dur . "s\" " .
	"from=\"" . $from . "\" " .
	"to=\"" . $to . "\" " .
	"fill=\"freeze\" " .
	"/>";
}

sub translate {
    my ($begin, $dur, $x, $y, $unit) = @_;

    if ($unit eq 'in') {
	$x = 1200 * $x;
	$y = 1200 * $y;
    } elsif ($unit eq 'cm') {
	$x = 450 * $x;
	$y = 450 * $y;
    } elsif ($unit eq 'px') {
	$x = 15 * $x;
	$y = 15 * $y;
    }

    return
	"<animateTransform attributeType=\"XML\" " .
	"attributeName=\"transform\" type=\"translate\" " .
	"from=\"0 0\" " .
	"to=\"" . $x . " " . $y . "\" " .
	"begin=\"" . $begin . "s\" " .
	"dur=\"" . $dur . "s\" " .
	"fill=\"freeze\" " .
	"additive=\"sum\" " .
	"/>";
}

sub rotate {
    my ($begin, $dur, $angle, $x, $y, $unit) = @_;

    if ($unit eq 'in') {
	$x = 1200 * $x;
	$y = 1200 * $y;
    } elsif ($unit eq 'cm') {
	$x = 450 * $x;
	$y = 450 * $y;
    } elsif ($unit eq 'px') {
	$x = 15 * $x;
	$y = 15 * $y;
    }

    return
	"<animateTransform attributeType=\"XML\" " .
	"attributeName=\"transform\" type=\"rotate\" " .
	"from=\"0 " . $x . " " . $y . "\" " .
	"to=\"" . $angle . " " .$x . " " . $y . "\" " .
	"begin=\"" . $begin . "s\" " .
	"dur=\"" . $dur . "s\" " .
	"fill=\"freeze\" " .
	"additive=\"sum\" " .
	"/>";
}

sub scale {
    my ($begin, $dur, $factor, $x, $y) = @_;

    return
	translate($begin, $dur, -$x*($factor-1), -$y*($factor-1), '') .
	"<animateTransform attributeType=\"XML\" " .
	"attributeName=\"transform\" type=\"scale\" " .
	"from=\"1 1\" " .
	"to=\"" . $factor . " " . $factor . "\" " .
	"begin=\"" . $begin . "s\" " .
	"dur=\"" . $dur . "s\" " .
	"fill=\"freeze\" " .
	"additive=\"sum\" " .
	"/>";
}


1;
