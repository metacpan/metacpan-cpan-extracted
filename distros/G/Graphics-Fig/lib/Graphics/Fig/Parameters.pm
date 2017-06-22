#
# XFig Drawing Library
#
# Copyright (c) 2017 D Scott Guthridge <scott_guthridge@rompromity.net>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the Artistic License as published by the Perl Foundation, either
# version 2.0 of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the Artistic License for more details.
# 
# You should have received a copy of the Artistic License along with this
# program.  If not, see <http://www.perlfoundation.org/artistic_license_2_0>.
#
package Graphics::Fig::Parameters;
our $VERSION = 'v1.0.2';

use strict;
use warnings;
use Carp;
use Math::Trig qw(deg2rad);
use Regexp::Common qw /number/;

my %ArrowStyles = (
    "stick"				=> [  0, 0 ],
    "triangle"				=> [  1, 0 ],
    "filled-triangle"			=> [  1, 1 ],
    "indented"				=> [  2, 0 ],
    "filled-indented"			=> [  2, 1 ],
    "pointed"				=> [  3, 0 ],
    "filled-pointed"			=> [  3, 1 ],
    "diamond"				=> [  4, 0 ],
    "filled-diamond"			=> [  4, 1 ],
    "circle"				=> [  5, 0 ],
    "filled-circle"			=> [  5, 1 ],
    "goblet"				=> [  6, 0 ],
    "filled-goblet"			=> [  6, 1 ],
    "square"				=> [  7, 0 ],
    "filled-square"			=> [  7, 1 ],
    "reverse-triangle"			=> [  8, 0 ],
    "filled-reverse-triangle"		=> [  8, 1 ],
    "left-indented"			=> [  9, 0 ],
    "right-indented"			=> [  9, 0 ],
    "half-triangle"			=> [ 10, 0 ],
    "filled-half-triangle"		=> [ 10, 1 ],
    "half-indented"			=> [ 11, 0 ],
    "filled-half-indented"		=> [ 11, 1 ],
    "half-pointed"			=> [ 12, 0 ],
    "filled-half-pointed"		=> [ 12, 1 ],
    "y"					=> [ 13, 0 ],
    "t"					=> [ 13, 1 ],
    "goal"				=> [ 14, 0 ],
    "gallows"				=> [ 14, 1 ],
);

my %CapStyles = (
    "butt"				=>  0,
    "round"				=>  1,
    "projecting"			=>  2,
);

my %AreaFills = (
    "not-filled"			=> -1,
    "black"				=>  0,
    "full"				=> 20,
    "saturated"				=> 20,
    "white"				=> 40,
    "left-diagonal-30"			=> 41,
    "right-diagonal-30"			=> 42,
    "crosshatch-30"			=> 43,
    "left-diagonal-45"			=> 44,
    "right-diagonal-45"			=> 45,
    "crosshatch-45"			=> 46,
    "horizontal-bricks"			=> 47,
    "vertical-bricks"			=> 48,
    "horizontal-lines"			=> 49,
    "vertical-lines"			=> 50,
    "crosshatch"			=> 51,
    "horizontal-right-shingles"		=> 52,
    "horizontal-left-shingles"		=> 53,
    "vertical-descending-shingles"	=> 54,
    "vertical-ascending-shingles"	=> 55,
    "fish-scales"			=> 56,
    "small-fish-scales"			=> 57,
    "circles"				=> 58,
    "hexagons"				=> 59,
    "octagons"				=> 60,
    "horizontal-tire-treads"		=> 61,
    "vertical-tire-treads"		=> 62,
);

my %FontNames = (
    # LaTeX fonts
    "default"					=> [ 0,  0 ],
    "roman"					=> [ 0,  1 ],
    "bold"					=> [ 0,  2 ],
    "italic"					=> [ 0,  3 ],
    "sans serif"				=> [ 0,  4 ],
    "typewriter"				=> [ 0,  5 ],

    # PostScript fonts
    "postscript default"			=> [ 4, -1 ],
    "times roman"				=> [ 4,  0 ],
    "times italic"				=> [ 4,  1 ],
    "times bold"				=> [ 4,  2 ],
    "times bold italic"				=> [ 4,  3 ],
    "avantgarde book"				=> [ 4,  4 ],
    "avantgarde book oblique"			=> [ 4,  5 ],
    "avantgarde demi"				=> [ 4,  6 ],
    "avantgarde demi oblique"			=> [ 4,  7 ],
    "bookman light"				=> [ 4,  8 ],
    "bookman light italic"			=> [ 4,  9 ],
    "bookman demi"				=> [ 4, 10 ],
    "bookman demi italic"			=> [ 4, 11 ],
    "courier"					=> [ 4, 12 ],
    "courier oblique"				=> [ 4, 13 ],
    "courier bold"				=> [ 4, 14 ],
    "courier bold oblique"			=> [ 4, 15 ],
    "helvetica"					=> [ 4, 16 ],
    "helvetica oblique"				=> [ 4, 17 ],
    "helvetica bold"				=> [ 4, 18 ],
    "helvetica bold oblique"			=> [ 4, 19 ],
    "helvetica narrow"				=> [ 4, 20 ],
    "helvetica narrow oblique"			=> [ 4, 21 ],
    "helvetica narrow bold"			=> [ 4, 22 ],
    "helvetica narrow bold oblique"		=> [ 4, 23 ],
    "new century schoolbook roman"		=> [ 4, 24 ],
    "new century schoolbook italic"		=> [ 4, 25 ],
    "new century schoolbook bold"		=> [ 4, 26 ],
    "new century schoolbook bold italic"	=> [ 4, 27 ],
    "palatino roman"				=> [ 4, 28 ],
    "palatino italic"				=> [ 4, 29 ],
    "palatino bold"				=> [ 4, 30 ],
    "palatino bold italic"			=> [ 4, 31 ],
    "symbol"					=> [ 4, 32 ],
    "zapf chancery medium italic"		=> [ 4, 33 ],
    "zapf dingbats"				=> [ 4, 34 ],
);

my %JoinStyles = (
    "miter"				=>  0,
    "round"				=>  1,
    "bevel"				=>  2,
);

my %LineStyles = (
    "default"				=> -1,
    "solid"   				=>  0,
    "dashed"  				=>  1,
    "dotted"  				=>  2,
    "dash-dotted"			=>  3,
    "dash-double-dotted"		=>  4,
    "dash-triple-dotted"		=>  5,
);

my %PaperSizes = (
    "Letter"				=> 1,
    "Legal"				=> 1,
    "Ledger"				=> 1,
    "Tabloid"				=> 1,
    "A"					=> 1,
    "B"					=> 1,
    "C"					=> 1,
    "D"					=> 1,
    "E"					=> 1,
    "A4"				=> 1,
    "A3"				=> 1,
    "A2"				=> 1,
    "A1"				=> 1,
    "A0"				=> 1,
    "B5"				=> 1,
);

my %Units = (
    ft					=> [ 12.0,         "Inches" ],
    foot				=> [ 12.0,         "Inches" ],
    feet				=> [ 12.0,         "Inches" ],
    in					=> [ 1.0,          "Inches" ],
    inch				=> [ 1.0,          "Inches" ],
    inches				=> [ 1.0,          "Inches" ],
    mil					=> [ 0.001,        "Inches" ],
    pt					=> [ 1.0 / 80.0,   "Inches" ],
    point				=> [ 1.0 / 80.0,   "Inches" ],
    m					=> [ 1.0 / 0.0254, "Metric" ],
    meter				=> [ 1.0 / 0.0254, "Metric" ],
    metre				=> [ 1.0 / 0.0254, "Metric" ],
    dam					=> [ 1.0 / 0.254,  "Metric" ],
    dekameter				=> [ 1.0 / 0.254,  "Metric" ],
    dekametre				=> [ 1.0 / 0.254,  "Metric" ],
    cm					=> [ 1.0 / 2.54,   "Metric" ],
    centimeter				=> [ 1.0 / 2.54,   "Metric" ],
    centimetre				=> [ 1.0 / 2.54,   "Metric" ],
    mm					=> [ 1.0 / 25.4,   "Metric" ],
    millimeter				=> [ 1.0 / 25.4,   "Metric" ],
    millimetre				=> [ 1.0 / 25.4,   "Metric" ],
    fig					=> [ 1.0 / 1200.0, "Inches" ],
);


#
# Graphics::Fig::Parameters::convertAngle
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   angle (degrees)
#   $context: parameter context
#
sub convertAngle {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $result;
    my $temp;

    if (!($value =~ m/^\s*($RE{num}{real})/)) {
	croak("${prefix}: error: ${value}: expected angle");
    }
    return deg2rad($value);
}

#
# Graphics::Fig::Parameters::convertAreaFill
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   fill style
#   $context: parameter context
#
sub convertAreaFill {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $temp;

    if ($value =~ /^\d+$/) {
	return $value;
    }
    $value = lc($value);
    if (defined($temp = $AreaFills{$value})) {
	return $temp;
    }
    if ($value =~ m/^shade(\d+)$/) {
	my $val = $1;
	if ($val < 1 || $val > 19) {
	    croak("${prefix}: error: $value: fill shade value must be " .
	          "between 1 and 19");
	}
	return $val;
    }
    if ($value =~ m/^tint(\d+)$/) {
	my $val = $1;
	if ($val < 1 || $val > 19) {
	    croak("${prefix}: error: $value: fill tint value must be " .
	          "between 1 and 19");
	}
	return 20 + $val;
    }
    croak("${prefix}: error: ${value}: expected area fill style");
}

#
# Graphics::Fig::Parameters::convertArrowMode
#   $fig:    fig object
#   $prefix: error message prefix
#   $value:  arrow mode
#   $context: parameter context
#
sub convertArrowMode {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value eq "none") {
	return 0;
    }
    if ($value eq "forw" || $value eq "forward") {
	return 1;
    }
    if ($value eq "back" || $value eq "backward") {
	return 2;
    }
    if ($value eq "both") {
	return 3;
    }
    croak("${prefix}: error: ${value}: expected {none|forw|back|both}");
}

#
# Graphics::Fig::Parameters::convertArrowStyle
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   arrow type
#   $context: parameter context
#
sub convertArrowStyle {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $temp;

    if (ref($value) eq "ARRAY" && scalar(@{$value}) == 2) {
	return $value;
    }
    if (defined($temp = $ArrowStyles{$value})) {
	return $temp;
    }
    croak("${prefix}: error: ${value}: expected arrow style or [m, n]");
}

#
# Graphics::Fig::Parameters::convertBool
#   $fig:    fig object
#   $prefix: error message prefix
#   $value:  parameter value
#   $context: parameter context
#
sub convertBool {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value eq "false" || $value eq "0") {
	return 0;
    }
    if ($value eq "true"  || $value eq "1") {
	return 1;
    }
    croak("${prefix}: error: ${value}: expected {true|false}");
}

#
# Graphics::Fig::Parameters::convertCapStyle
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   cap style
#   $context: parameter context
#
sub convertCapStyle {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $temp;

    if ($value =~ m/^\d+$/) {
	return $value;
    }
    $value = lc($value);
    if (defined($temp = $CapStyles{$value})) {
	return $temp;
    }
    croak("${prefix}: error: ${value}: expected {butt|round|projecting}");
}

#
# Graphics::Fig::Parameters::convertColor
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   color name
#   $context: parameter context
#
sub convertColor {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    my $rv = eval {
	return ${$fig}{"colors"}->convert($value);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("${prefix}: $@");
    }
    return $rv;
}

#
# Graphics::Fig::Parameters::convertDepth
#   $fig:    fig object
#   $prefix: error message prefix
#   $value:  object depth
#   $context: parameter context
#
sub convertDepth {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if (!($value =~ m/^$RE{num}{int}$/) || $value < 0 || $value > 999) {
	croak("${prefix}: error: ${value}: expected integer from 0 to 999");
    }
    return $value;
}

#
# Graphics::Fig::Parameters::convertExportOptions
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   angle (degrees)
#   $context: parameter context
#
sub convertExportOptions {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if (ref($value) ne "ARRAY") {
	croak("${prefix}: error: expected reference to array of scalars");
    }
    foreach my $item (@{$value}) {
	if (ref($value) ne "") {
	    croak("${prefix}: error: expected reference to array of scalars");
	}
    }
    return $value;
}

#
# Graphics::Fig::Parameters::convertFontFlags
#   $fig:     fig object
#   $prefix:  error message prefix
#   $value:   font flags list
#   $context: parameter context
#
sub convertFontFlags {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $flags   = 0;

    if (defined(${$context}{"fontFlags"})) {
	$flags = ${$context}{"fontFlags"};
    }
    $value =~ y/[A-Z]/[a-z]/;
    while ($value =~ s/^\s*([-+]?)\s*([a-z]+)//) {
	my $op   = $1;
	my $flag = $2;
	my $mask;

	if ($flag eq "rigid") {
	    $mask = 1;
	} elsif ($flag eq "special") {
	    $mask = 2;
	} elsif ($flag eq "postscript") {
	    $mask = 4;
	} elsif ($flag eq "hidden") {
	    $mask = 8;
	} else {
	    croak("${prefix}: error: ${value}: unknown font flag (${flag})");
	}
	if ($op eq "-") {
	    $flags &= ~$mask;
	} else {
	    $flags |=  $mask;
	}
    }
    $value =~ s/\s//;
    if ($value ne "") {
	croak("${prefix}: error: invalid font flags");
    }
    return $flags;
}

#
# Graphics::Fig::Parameters::convertFontName
#   $fig:     fig object
#   $prefix:  error message prefix
#   $value:   font name
#   $context: parameter context
#
sub convertFontName {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $temp;

    $value =~ y/[A-Z]/[a-z]/;
    if (!(defined($temp = $FontNames{$value}))) {
	croak("${prefix}: error: ${value}: unknown font name");
    }
    return $temp;
}

#
# Graphics::Fig::Parameters::convertFontSize
#   $fig:     fig object
#   $prefix:  error message prefix
#   $value:   font size in points (1/72th of an inch)
#   $context: parameter context
#
sub convertFontSize {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $temp;

    if (!($value =~ s/^\s*($RE{num}{real})//) && $value <= 0) {
	croak("${prefix}: error: ${value}: invalid font size");
    }
    return $value + 0;
}

#
# Graphics::Fig::Parameters::convertInt
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   integer
#   $context: parameter context
#
sub convertInt {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $result;
    my $temp;

    if (!($value =~ m/^\s*($RE{num}{int})/)) {
	croak("${prefix}: error: ${value}: expected integer");
    }
    return $value;
}
 
#
# Graphics::Fig::Parameters::convertJoinStyle
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   join sytle
#   $context: parameter context
#
sub convertJoinStyle {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $temp;

    if ($value =~ m/^\d+$/) {
	return $value;
    }
    $value = lc($value);
    if (defined($temp = $JoinStyles{$value})) {
	return $temp;
    }
    croak("${prefix}: error: ${value}: expected {miter|round|bevel}");
}

#
# Graphics::Fig::Parameters::convertLength
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   number with optional unit
#   $context: parameter context
#
sub convertLength {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $result;
    my $temp;

    if (!($value =~ s/^\s*($RE{num}{real})//)) {
	croak("${prefix}: error: ${value}: invalid number");
    }
    $result = $1;
    $value =~ s/^\s*//;
    if ($value eq "") {
	$result *= ${$context}{"units"}[0];
    } elsif (defined($temp = $Units{$value})) {
	$result *= ${$temp}[0];
    } else {
	croak("${prefix}: error: ${value}: unrecognized unit");
    }
    return $result;
}

#
# Graphics::Fig::Parameters::convertLineStyle:
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   line style
#   $context: parameter context
#
sub convertLineStyle {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $temp;

    if ($value =~ /^\d+$/) {
	return $value;
    }
    $value = lc($value);
    if (defined($temp = $LineStyles{$value})) {
	return $temp;
    }
    croak("${prefix}: error: ${value}: unknown line style");
}

#
# Graphics::Fig::Parameters::convertMultiplePage: page setup for printing
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   optional number followed by unit
#   $context: parameter context
#
sub convertMultiplePage {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value =~ m/^Single$/i) {
	return "Single";
    }
    if ($value =~ m/^Multiple$/i) {
	return "Multiple";
    }
    croak("${prefix}: error: ${value}: expected Single or Multiple");
}

#
# Graphics::Fig::Parameters::convertOrientation: orientation for printing
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   optional number followed by unit
#   $context: parameter context
#
sub convertOrientation {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value =~ m/^Landscape$/i) {
	return "Landscape";
    }
    if ($value =~ m/^Portrait$/i) {
	return "Portrait";
    }
    croak("${prefix}: error: ${value}: expected Landscape or Portrait");
}

#
# Graphics::Fig::Parameters::convertPageJustification: printing justification
# printing
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   optional number followed by unit
#   $context: parameter context
#
sub convertPageJustification {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value =~ m/^Center$/i) {
	return "Center";
    }
    if ($value =~ m/^Flush\s*left$/i) {
	return "Flush left";
    }
    croak("${prefix}: error: ${value}: expected \"Center\" or \"Flush left\"");
}

#
# Graphics::Fig::Parameters::convertPaperSize: paper size for printing
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   optional number followed by unit
#   $context: parameter context
#
sub convertPaperSize {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    $value =~ s/(.)(.*)/\u$1\L$2/;
    if (defined($PaperSizes{$value})) {
	return $value;
    }
    croak("${prefix}: error: ${value}: unknown paper size");
}

#
# Graphics::Fig::Parameters::convertPoint
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   reference to an [x, y] point
#   $context: parameter context
#
sub convertPoint {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if (ref($value) ne "ARRAY" || scalar(@{$value}) != 2 ||
        !defined(${$value}[0]) || !defined(${$value}[1])) {
	croak("${prefix}: error: expected [x, y] point");
    }
    my $x = &convertLength($fig, $prefix, ${$value}[0], $context);
    my $y = &convertLength($fig, $prefix, ${$value}[1], $context);
    return [ $x, $y ];
}

#
# Graphics::Fig::Parameters::convertPointList
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   reference to an [[x1, y1], [x2, y2], ...]  point list
#   $context: parameter context
#
sub convertPointList {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my @result;

    if (ref($value) ne "ARRAY") {
	croak("${prefix}: error: expected [[x1, y1], [x2, y2], ...] " .
	      "point list");
    }
    # allow a single [x1, y1] point
    if (scalar(@{$value}) == 2 &&
        ref(${$value}[0]) eq "" && ref(${$value}[1]) eq "") {
	push(@result, &convertPoint($fig, $prefix, $value, $context));

    } else {
	foreach my $point (@{$value}) {
	    push(@result, &convertPoint($fig, $prefix, $point, $context));
	}
    }
    return \@result;
}

#
# Graphics::Fig::Parameters::convertPositiveReal
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   optional number followed by unit
#   $context: parameter context
#
sub convertPositiveReal {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value =~ s/^($RE{num}{real})$// && $value > 0) {
	return $value;
    }
    croak("${prefix}: error: ${value}: expected positive number");
}

#
# Graphics::Fig::Parameters::convertScale
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   u or [ u, v ]
#   $context: parameter context
#
sub convertScale {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $u;
    my $v;

    if (ref($value) eq "ARRAY") {
	if (scalar(@{$value}) != 2 ||
	    !defined($u = ${$value}[0]) || !defined($v = ${$value}[1]) ||
	    !($u =~ m/^$RE{num}{real}/) || !($v =~ m/^\s*$RE{num}{real}/)) {
		croak("${prefix} error: expected scalar or [u, v] pair");
	}
    } else {
	if (!defined($value) || !ref($value) eq "" ||
	    !($value =~ m/$RE{num}{real}/)) {
	    croak("${prefix} error: expected scalar or [u, v] pair");
	}
	$u = $value;
	$v = $value;
    }
    return [ $u, $v ];
}

#
# Graphics::Fig::Spline::convertSplineSubtype
#   $fig:     fig object
#   $prefix:  error message prefix
#   $value:   subtype
#   $context: parameter context
#
sub convertSplineSubtype {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value eq "open-approximated") {
	return 0;
    }
    if ($value eq "closed-approximated") {
	return 1;
    }
    if ($value eq "open-interpolated") {
	return 2;
    }
    if ($value eq "closed-interpolated") {
	return 3;
    }
    if ($value eq "open-x") {
	return 4;
    }
    if ($value eq "closed-x") {
	return 5;
    }
    if ($value =~ m/^\s*($RE{num}{int})/) {
	if ($value < 0 || $value > 5) {
	    croak("${prefix}: error: ${value}: expected integer in 0..5");
	}
	return $value;
    }
    croak("${prefix}: error: ${value}: expected " .
    	  "{open|closed}-{approximated|interpolated|x}");
}

#
# Graphics::Fig::Parameters::convertText
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   optional number followed by unit
#   $context: parameter context
#
sub convertText {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $temp = $value;

    utf8::encode($temp);
    for (my $i = 0; $i < length($temp); ++$i) {
	my $n = ord(substr($temp, $i, 1));
	die if $n < 0 || $n > 255;
	if ($n < 32 || $n == 127) {
	    croak("${prefix}: error: ${value}: " .
	    	  "invalid character ${n} in string");
	}
    }
    return $value;
}

#
# Graphics::Fig::Parameters::convertTextJustification
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   "left", "center" or "right"
#   $context: parameter context
#
sub convertTextJustification {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    $value =~ y/[A-Z]/[a-z]/;
    if ($value eq "left") {
	return 0;
    }
    if ($value eq "center") {
	return 1;
    }
    if ($value eq "right") {
	return 2;
    }
    if (!($value =~ m/^$RE{num}{int}$/) || $value < 0 || $value > 2) {
	croak("${prefix}: error: ${value}: expected " .
	      "left|center|right");
    }
    return $value + 0;
}

#
# Graphics::Fig::Parameters::convertTransparentColor: for gif export
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   optional number followed by unit
#   $context: parameter context
#
sub convertTransparentColor {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value == -1 || $value == -2) {
	return $value;
    }
    my $rv = eval {
	return ${$fig}{"colors"}->convert($value);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("${prefix}: $@");
    }
    return $rv;
}

#
# Graphics::Fig::Parameters::convertUnits
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   optional number followed by unit
#   $context: parameter context
#
sub convertUnits {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $scalar  = 1.0;
    my $temp;

    if ($value =~ s/^\s*($RE{num}{real})//) {
	$scalar = $1;
    }
    $value =~ s/^\s*//;
    if (!defined($temp = $Units{$value})) {
	croak("${prefix}: error: ${value}: unknown unit");
    }
    $scalar *= ${$temp}[0];
    return [ $scalar, ${$temp}[1] ];
}

#
# Graphics::Fig::Parameters::getParameterSignature: positional parameters sig
#   @_: positional arguments
#
sub getParameterSignature {
    my $result = "";

    foreach my $arg (@_) {
	my $type = ref($arg);
	if ($type eq "") {
	    $result .= '.';
	} elsif ($type eq "SCALAR") {
	    $result .= '$';
	} elsif ($type eq "ARRAY") {
	    $result .= '@';
	} elsif ($type eq "HASH") {
	    $result .= '%';
	} elsif ($type eq "CODE") {
	    $result .= '&';
	} elsif ($type eq "REF") {
	    $result .= '\\';
	} elsif ($type eq "GLOB") {
	    $result .= '*';
	} elsif ($type eq "LVALUE") {	# like scalar when reading
	    $result .= '$';
	} else {
	    $result .= '?';
	}
    }
    return $result;
}


our @ArrowParameters = (
    {
	name		=> "arrowMode",
	convert		=> \&convertArrowMode,
	default		=> 0,
    },
    {
	name		=> "arrowStyle",
	convert		=> \&convertArrowStyle,
	default		=> [ 0, 0 ],
    },
    {
	name		=> "fArrowStyle",
	convert		=> \&convertArrowStyle,
    },
    {
	name		=> "bArrowStyle",
	convert		=> \&convertArrowStyle,
    },
    {
	name		=> "arrowThickness",
	convert		=> \&convertLength,
	default		=> 1.0 / 80.0,
    },
    {
	name		=> "fArrowThickness",
	convert		=> \&convertLength,
    },
    {
	name		=> "bArrowThickness",
	convert		=> \&convertLength,
    },
    {
	name		=> "arrowWidth",
	convert		=> \&convertLength,
	default		=> 60.0 / 1200.0,
    },
    {
	name		=> "fArrowWidth",
	convert		=> \&convertLength,
    },
    {
	name		=> "bArrowWidth",
	convert		=> \&convertLength,
    },
    {
	name		=> "arrowHeight",
	convert		=> \&convertLength,
	default		=> 120.0 / 1200.0,
    },
    {
	name		=> "fArrowHeight",
	convert		=> \&convertLength,
    },
    {
	name		=> "bArrowHeight",
	convert		=> \&convertLength,
    },
);

our %CapStyleParameter = (
    name		=> "capStyle",
    convert		=> \&convertCapStyle,
    default		=> 0,
);

our %CenterParameter = (
    name		=> "center",
    convert		=> \&convertPoint,
);

our %ColorParameter = (
    name		=> "penColor",
    aliases		=> [ "color" ],
    convert		=> \&convertColor,
    default		=> 0,
);

our %CornerRadiusParameter = (
    name		=> "cornerRadius",
    convert		=> \&convertLength,
);

our %DepthParameter = (
    name		=> "depth",
    convert		=> \&convertDepth,
    default		=> 50,
);

our %DetachedLinetoParameter = (
    name		=> "detachedLineto",
    convert		=> \&convertBool,
    default		=> 0,
);

our @ExportParameters = (
    {
	name		=> "exportFormat",
    },
    {
	name		=> "exportOptions",
	convert		=> \&convertExportOptions,
    },
);

our @FillParameters = (
    {
	name		=> "fillColor",
	convert		=> \&convertColor,
	default		=> 7,
    },
    {
	name		=> "areaFill",
	convert		=> \&convertAreaFill,
	default		=> -1,
    },
);

our %GridParameter = (
    name		=> "grid",
    convert		=> \&convertLength,
);

our %JoinStyleParameter = (
    name		=> "joinStyle",
    convert		=> \&convertJoinStyle,
    default		=> 0,
);

our @LineParameters = (
    {
	name		=> "lineStyle",
	convert		=> \&convertLineStyle,
	default 		=> 0,
    },
    {
	name		=> "lineThickness",
	convert		=> \&convertLength,
	default		=> 1.0 / 80.0,
    },
    {
	name		=> "styleVal",
	convert		=> \&convertLength,
	default		=> 0.075,
    },
);

our %OffsetParameter = (
    name		=> "offset",
    convert		=> \&convertPoint
);

our %PointParameter = (
    name		=> "point",
    convert		=> \&convertPoint,
);

our %PointsParameter = (
    name		=> "points",
    convert		=> \&convertPointList,
    aliases		=> [ "point" ],
);

our %PositionParameter = (
    name		=> "position",
    convert		=> \&convertPoint,
    default		=> [ 0.0, 0.0 ]
);

our %RotationParameter = (
    name		=> "rotation",
    convert		=> \&convertAngle,
);

our @SaveParameters = (
    {
	name		=> "orientation",
	convert		=> \&convertOrientation,
	default		=> "Landscape"
    },
    {
	name		=> "pageJustification",
	convert		=> \&convertPageJustification,
	default		=> "Center"
    },
    {
	name		=> "paperSize",
	convert		=> \&convertPaperSize,
	default		=> "Letter"
    },
    {
	name		=> "magnification",
	convert		=> \&convertPositiveReal,
	default		=> 100.0
    },
    {
	name		=> "multiplePage",
	convert		=> \&convertMultiplePage,
	default		=> "Single"
    },
    {
	name		=> "transparentColor",
	convert		=> \&convertTransparentColor,
	default		=> -2
    },
    {
	name		=> "comment",
	default		=> "",
    },
);

our %ScaleParameter = (
    name		=> "scale",
    convert		=> \&convertScale
);

our %SplineSubtypeParameter = (
    name		=> "splineSubtype",
    convert		=> \&convertSplineSubtype,
    default		=> 0,
);

our @TextParameters = (
    {
	name		=> "textJustification",
	convert		=> \&convertTextJustification,
	aliases		=> [ "justification" ],
	default		=> 0,
    },
    {
	name		=> "fontName",
	convert		=> \&convertFontName,
	aliases		=> [ "font" ],
	default		=> [ 0, 0 ],
    },
    {
	name		=> "fontSize",
	convert		=> \&convertFontSize,
	default		=> 12,
    },
    {
	name		=> "fontFlags",
	convert		=> \&convertFontFlags,
	default		=> 0,
    },
);

our %UnitsParameter = (
    name		=> "units",
    convert		=> \&convertUnits,
    default		=> [ 1.0, "Inches" ],
);

#
# Graphics::Fig::Parameters::parse
#   $fig       fig object
#   $context:  error message context
#   $arglist:  reference to caller's @_
#   $template: reference to option descriptor array
#   $defaults: optional ref to hash of default values
#   $result:   reference to result hash
#
sub parse {
    my $fig      = shift;
    my $context  = shift;
    my $template = shift;
    my $defaults = shift;
    my $result   = shift;

    my $positionalTemplate = ${$template}{"positional"};
    my $namedTemplate = ${$template}{"named"};
    if (!defined($namedTemplate)) {
	$namedTemplate = [];
    }

    #
    # If the last parameter is a reference to HASH, remove it as the
    # named namedParameters list.
    #
    my %namedParameters;
    {
	my $last = $#_;
	if ($last >= 0 && ref($_[$last]) eq "HASH") {
	    %namedParameters = %{pop(@_)};
	}
    }

    #
    # Validate the positional parameters and convert them into named
    # parameters.
    #
    my $signature = &getParameterSignature(@_);
    if ($signature ne "") {
	my $positionalParameterNames = ${$positionalTemplate}{$signature};
	if (!defined($positionalParameterNames)) {
	    croak("${context}: invalid parameter list");
	}
	for (my $i = 0; $i < scalar(@{$positionalParameterNames}); ++$i) {
	    my $name = ${$positionalParameterNames}[$i];

	    if (defined($namedParameters{$name})) {
		croak("${context}: error: parameter ${name}: specified in " .
		      "both positional and named lists");
	    }
	    $namedParameters{$name} = $_[$i];
	}
    }

    #
    # Go through the named parameter template in order.  If the parameter
    # is defined in %namedParameters, use it.  Otherwise, check if it's
    # defined in %{$defaults}.  Otherwise, test if a default value was
    # given in the template.  As we go, remove each parameter from the
    # named parameter hash.
    #
    foreach my $entry (@{$namedTemplate}) {
	my $name       = ${$entry}{"name"};
	my $aliases    = ${$entry}{"aliases"};
	my $convert    = ${$entry}{"convert"};
	my $default    = ${$entry}{"default"};
	my $subcontext = sprintf("%s: %s", $context, $name);
	my $pname;
	my $value;

	if (!defined($aliases)) {
	    $aliases = [];
	}
	foreach my $tempName ($name, @{$aliases}) {
	    my $tempValue = $namedParameters{$tempName};
	    if (defined($tempValue)) {
		if (defined($pname)) {
		    croak("${context}: error: " .
		          "cannot specify both ${pname} and ${tempName}");
		}
		$pname = $tempName;
		$value = $tempValue;
		delete $namedParameters{$pname};
	    }
	}
	if (defined($value)) {
	    if (defined($convert)) {
		${$result}{$name} = &{$convert}($fig, $subcontext,
						$value, $result);
	    } else {
		${$result}{$name} = $value;
	    }
	    next;
	}
	if (defined($defaults)) {
	    if (defined($value = ${$defaults}{$name})) {
		${$result}{$name} = $value;
		next;
	    }
	}
	if (defined($default)) {
	    ${$result}{$name} = $default;
	    next;
	}
    }

    #
    # If any named parameters remain, report the first as unknown.
    #
    foreach my $key (keys %namedParameters) {
	croak("${context}: unknown parameter: ${key}");
    }
    return 1;
}

#
# Graphics::Fig::Parameters::translatePoints: translate by offset
#   $parameters: parameter list (offset)
#   ( [ x, y ], ... )
#
sub translatePoints {
    my $parameters = shift;
    my $offset = ${$parameters}{"offset"};
    die unless defined($offset);
    die unless ref($offset) eq "ARRAY";
    my $dx = ${$offset}[0];
    my $dy = ${$offset}[1];
    my @result;

    foreach my $point (@_) {
	push(@result, [ ${$point}[0] + $dx, ${$point}[1] + $dy ]);
    }
    return @result;
}

#
# Graphics::Fig::Parameters::rotatePoints: rotate about center
#   $parameters: parameter list (center, rotation)
#   ( [ x, y ], ... )
#
sub rotatePoints {
    my $parameters = shift;
    my $rotation = ${$parameters}{"rotation"};
    my $center   = ${$parameters}{"center"};
    if (!defined($center)) {
	$center = ${$parameters}{"position"};
    }
    die unless defined($center);
    die unless defined($rotation);
    my $xc = ${$center}[0];
    my $yc = ${$center}[1];
    my $c  = cos($rotation);
    my $s  = sin($rotation);
    my @result;

    foreach my $point (@_) {
	my ($x, $y) = @{$point};
	$x -= $xc;
	$y -= $yc;
	( $x, $y ) = ( $c * $x + $s * $y, -$s * $x + $c * $y );
	$x += $xc;
	$y += $yc;
	push(@result, [ $x, $y ]);
    }
    return @result;
}

#
# Graphics::Fig::Parameters::scalePoints: scale about center
#   $parameters: parameter list (center, scale)
#   ( [ x, y ], ... )
#
sub scalePoints {
    my $parameters = shift;
    my $scale   = ${$parameters}{"scale"};
    my $center  = ${$parameters}{"center"};
    if (!defined($center)) {
	$center = ${$parameters}{"position"};
    }
    die unless defined($scale);
    die unless defined($center);
    my $xc = ${$center}[0];
    my $yc = ${$center}[1];
    my $u  = ${$scale}[0];
    my $v  = ${$scale}[1];
    my @result;

    foreach my $point (@_) {
	die unless ref($point) eq "ARRAY";
	my ($x, $y) = @{$point};
	$x = $xc + ($x - $xc) * $u;
	$y = $yc + ($y - $yc) * $v;
	push(@result, [ $x, $y ]);
    }
    return @result;
}

#
# Graphics::Fig::Parameters:getbboxFromPoints: find top-left bottom-right
#		from pts
#   @points
#
sub getbboxFromPoints {
    my ($x_min, $y_min, $x_max, $y_max);

    foreach my $point (@_) {
	if (!defined($x_min)) {
	    $x_min = ${$point}[0];
	    $y_min = ${$point}[1];
	    $x_max = ${$point}[0];
	    $y_max = ${$point}[1];
	    next;
	}
	if (${$point}[0] < $x_min) {
	    $x_min = ${$point}[0];
	}
	if (${$point}[1] < $y_min) {
	    $y_min = ${$point}[1];
	}
	if (${$point}[0] > $x_max) {
	    $x_max = ${$point}[0];
	}
	if (${$point}[1] > $y_max) {
	    $y_max = ${$point}[1];
	}
    }
    return [ [ $x_min, $y_min ], [ $x_max, $y_max ] ];
}

#
# Graphics::Fig::Parmeters::copyArrowParameters: set fArrow, bArrow in object
#   $object:     object to modify
#   $parameters: parameter list (center, scale)
#
sub copyArrowParameters {
    my $object     = shift;
    my $parameters = shift;

    my @prefixes = ( "f", "b" );
    my $arrowMode = ${$parameters}{"arrowMode"};
    for (my $i = 0; $i < 2; ++$i) {
	my $prefix = $prefixes[$i];
	my $value = undef;

	if ($arrowMode & (1 << $i)) {
	    my @R;
	    my $temp;
	    if (!defined($temp = ${$parameters}{"${prefix}ArrowStyle"})) {
		$temp = ${$parameters}{"arrowStyle"};
	    }
	    ( $R[0], $R[1] ) = @{$temp};
	    if (!defined($temp = ${$parameters}{"${prefix}ArrowThickness"})) {
		$temp = ${$parameters}{"arrowThickness"};
	    }
	    $R[2] = $temp;
	    if (!defined($temp = ${$parameters}{"${prefix}ArrowWidth"})) {
		$temp = ${$parameters}{"arrowWidth"};
	    }
	    $R[3] = $temp;
	    if (!defined($temp = ${$parameters}{"${prefix}ArrowHeight"})) {
		$temp = ${$parameters}{"arrowHeight"};
	    }
	    $R[4] = $temp;
	    $value = \@R;
	}
	${$object}{"${prefix}Arrow"} = $value;
    }
    1;
}

#
# Graphics::Fig::Parmeters::compareArrowParameters: compare arrow parameters
#   $object:     object to modify
#   $parameters: parameter list (center, scale)
#
sub compareArrowParameters {
    my $object     = shift;
    my $parameters = shift;
    my $result;

    my @prefixes = ( "f", "b" );
    my $arrowMode = ${$parameters}{"arrowMode"};
    for (my $i = 0; $i < 2; ++$i) {
	my $prefix = $prefixes[$i];
	my $value;

	if ($arrowMode & (1 << $i)) {
	    if (!defined($value = ${$object}{"${prefix}Arrow"})) {
		return -1;
	    }
	    my $temp;
	    if (!defined($temp = ${$parameters}{"${prefix}arrowStyle"})) {
		$temp = ${$parameters}{"arrowStyle"};
	    }
	    if (($result = (${$value}[0] <=> ${$temp}[0])) != 0) {
		return $result;
	    }
	    if (($result = (${$value}[1] <=> ${$temp}[1])) != 0) {
		return $result;
	    }
	    if (!defined($temp = ${$parameters}{"${prefix}arrowThickness"})) {
		$temp = ${$parameters}{"arrowThickness"};
	    }
	    if (($result = (${$value}[2] <=> $temp)) != 0) {
		return $result;
	    }
	    if (!defined($temp = ${$parameters}{"${prefix}arrowWidth"})) {
		$temp = ${$parameters}{"arrowWidth"};
	    }
	    if (($result = (${$value}[3] <=> $temp)) != 0) {
		return $result;
	    }
	    if (!defined($temp = ${$parameters}{"${prefix}arrowHeight"})) {
		$temp = ${$parameters}{"arrowHeight"};
	    }
	    if (($result = (${$value}[4] <=> $temp)) != 0) {
		return $result;
	    }

	} elsif (defined(${$object}{"${prefix}Arrow"})) {
	    return +1;
	}
    }
    return 0;
}

#
# Graphics::Fig::Parmeters::printArrowParameters
#   $object:     fig sub-object
#   $fh:         reference to file handle
#   $parameters: save parameters
#
sub printArrowParameters {
    my $object     = shift;		# fArrow, bArrow
    my $fh         = shift;
    my $parameters = shift;

    my $figPerInch = Graphics::Fig::_figPerInch($parameters);
    my ($fArrow, $bArrow);
    if (defined($fArrow = ${$object}{"fArrow"})) {
	my @A = @{$fArrow};
	printf $fh ("\t%d %d %.2f %.2f %.2f\n", 
		$A[0], $A[1], $A[2] * 80.0,
		$A[3] * $figPerInch, $A[4] * $figPerInch);
    }
    if (defined($bArrow = ${$object}{"bArrow"})) {
	my @A = @{$bArrow};
	printf $fh ("\t%d %d %.2f %.2f %.2f\n", 
		$A[0], $A[1], $A[2] * 80.0,
		$A[3] * $figPerInch, $A[4] * $figPerInch);
    }
}

1;
