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
package Graphics::Fig::Polyline;
our $VERSION = 'v1.0.7';

use strict;
use warnings;
use Carp;
use Math::Trig;
use Image::Info qw(image_info);
use Graphics::Fig::Color;
use Graphics::Fig::Parameters;

#
# RE_REAL regular expression matching a floating point number
#
my $RE_REAL = "(?:(?i)(?:[-+]?)(?:(?=[.]?[0123456789])(?:[0123456789]*)" .
	      "(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[-+]?)" .
	      "(?:[0123456789]+))|))";

my $DEFAULT_RESOLUTION = 100.0;		# dpi

#
# _parseResolution: parse resolution string
#   $value: resolution
#   $state: state structure
#
#   Input may be any of (in increasing preference):
#       xres / yres			(form 1)
#       xyres unit			(form 2)
#       xres / yres unit		(form 3)
#
# Return:
#    If the input string is valid, this function updates the
#    state structure and returns 1.  On error, it returns undef.
#
sub _parseResolution {
    my $value = shift;
    my $state = shift;

    #
    # Match against pattern.
    #
    my $pattern = "\\s*($RE_REAL)" .
		  "(\\s*[/xX,]?\\s*($RE_REAL))?" .
		  "(\\s*(dpi|dpcm|dpm))?\\s*";
    if (defined($value) && $value =~ m/^${pattern}$/) {
	my $x = $1;
	my $y = $3;
	my $dpi;

	#
	# If unit given, convert to dpi.
	#
	if (defined($5)) {
	    if ($5 eq "dpcm") {
		$dpi = 2.54;
	    } elsif ($5 eq "dpm") {
		$dpi = 0.0254;
	    } else { # "dpi"
		$dpi = 1.0;
	    }
	}
	#
	# Form 1
	#
	if (!defined($dpi) && defined($y)) {
	    if ($state->{"best_form"} < 1) {
		$state->{"x_resolution"} = $x * $DEFAULT_RESOLUTION;
		$state->{"y_resolution"} = $y * $DEFAULT_RESOLUTION;
		$state->{"best_form"} = 1;
	    }
	    return 1;
	}
	#
	# Form 2
	#
	if (defined($dpi) && !defined($y)) {
	    if ($state->{"best_form"} < 2) {
		$state->{"x_resolution"} = $x * $dpi;
		$state->{"y_resolution"} = $x * $dpi; # y same as x
		$state->{"best_form"} = 2;
	    }
	    return 1;
	}
	#
	# Form 3
	#
	if (defined($dpi) &&  defined($y)) {
	    if ($state->{"best_form"} < 3) {
		$state->{"x_resolution"} = $x * $dpi;
		$state->{"y_resolution"} = $y * $dpi;
		$state->{"best_form"} = 3;
	    }
	    return 1
	}
    }
    return undef;
}

#
# _convertResolution: convert image resolution
#   $value: resolution
#   $fromImage: true if parsing from Image::Info; false if parameter
#
sub _convertResolution {
    my $value     = shift;
    my $fromImage = shift;

    #
    # Init state
    #
    my $state = {
	x_resolution 	=> $DEFAULT_RESOLUTION,
	y_resolution 	=> $DEFAULT_RESOLUTION,
	best_form	=> 0,
    };

    #
    # Resolution returned from image_info can either be a string or
    # a reference to an array of strings, each in one of the forms
    # described above in _parseResolution.  For example, the resolution
    # may be returned as: [ "300 dpi", "1/1" ].  We take the best form
    # offered.  If the resolution was given explicitly as a parameter
    # to Graphics::Fig, it must be a single valid string.
    #
    if ($fromImage && ref($value) eq "ARRAY") {
	foreach my $temp (@{$value}) {
	    &_parseResolution($temp, $state);
	}
    } else {
	if (!&_parseResolution($value, $state) && !$fromImage) {
	    croak("picture: error: ${value}: invalid resolution");
	}
    }
    return [ $state->{"x_resolution"}, $state->{"y_resolution"} ];
}

#
# Graphics::Fig::Polyline::convertResolution
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   angle (degrees)
#   $context: parameter context
#
sub convertResolution {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    return &_convertResolution($value, 0);
}

my @PolylineCommonParameters = (
    \%Graphics::Fig::Parameters::UnitsParameter,	# must be first
    \%Graphics::Fig::Parameters::PositionParameter,	# must be second
    \%Graphics::Fig::Parameters::ColorParameter,
    \%Graphics::Fig::Parameters::DepthParameter,
     @Graphics::Fig::Parameters::FillParameters,
    \%Graphics::Fig::Parameters::JoinStyleParameter,
     @Graphics::Fig::Parameters::LineParameters,
    \%Graphics::Fig::Parameters::PointsParameter,
);

#
# Polyline Parameters
#
my %PolylineParameterTemplate = (
    positional	=> {
	"@"	=> [ "points" ],
    },
    named	=> [
	 @PolylineCommonParameters,
	 @Graphics::Fig::Parameters::ArrowParameters,
	\%Graphics::Fig::Parameters::CapStyleParameter,
    ],
);

#
# Lineto Parameters
#
my %LinetoParameterTemplate = (
    positional	=> {
	".."	=> [ "distance", "heading" ],
	"@"	=> [ "points" ],
    },
    named	=> [
	 @PolylineCommonParameters,
	 @Graphics::Fig::Parameters::ArrowParameters,
	\%Graphics::Fig::Parameters::CapStyleParameter,
	{
	    name		=> "distance",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
	{
	    name		=> "heading",
	    convert		=> \&Graphics::Fig::Parameters::convertAngle,
	},
	{
	    name		=> "detachedLineto",
	    convert		=> \&Graphics::Fig::Parameters::convertBool,
	    aliases		=> [ "new" ],
	}
    ],
);

#
# Box Parameters
#
my %BoxParameterTemplate = (
    positional	=> {
	".."	=> [ "width", "height" ],
	"@"	=> [ "points" ],
    },
    named	=> [
	 @PolylineCommonParameters,
	\%Graphics::Fig::Parameters::CenterParameter,
	\%Graphics::Fig::Parameters::CornerRadiusParameter,
	{
	    name		=> "width",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
	{
	    name		=> "height",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
    ],
);

#
# Polygon Parameters
#
my %PolygonParameterTemplate = (
    positional	=> {
	".."	=> [ "n", "r" ],
	"@"	=> [ "points" ],
    },
    named	=> [
	 @PolylineCommonParameters,
	\%Graphics::Fig::Parameters::CenterParameter,
	\%Graphics::Fig::Parameters::RotationParameter,
	{
	    name		=> "n",
	    convert		=> \&Graphics::Fig::Parameters::convertInt,
	},
	{
	    name		=> "r",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	    aliases		=> [ "radius" ],
	},
    ],
);

#
# Picture Parameters
#
my %PictureParameterTemplate = (
    positional	=> {
	""	=> [ ],
	"."	=> [ "filename" ],
	".."	=> [ "filename", "width" ],
	"..."	=> [ "filename", "width", "height" ],
	".@"	=> [ "filename", "points" ],
    },
    named	=> [
	 @PolylineCommonParameters,
	\%Graphics::Fig::Parameters::CenterParameter,
	{
	    name		=> "filename",
	},
	{
	    name		=> "width",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
	{
	    name		=> "height",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
	{
	    name		=> "resolution",
	    convert		=> \&convertResolution,
	},
    ],
);

#
# Graphics::Fig::Polyline::new: base constructor
#   $proto:      prototype
#   $parameters: ref to parameter hash
#
sub new {
    my $proto       = shift;
    my $subtype     = shift;
    my $parameters  = shift;

    my $self = {
	subtype		=> $subtype,
	lineStyle	=> ${$parameters}{"lineStyle"},
	lineThickness	=> ${$parameters}{"lineThickness"},
	penColor	=> ${$parameters}{"penColor"},
	fillColor	=> ${$parameters}{"fillColor"},
	depth		=> ${$parameters}{"depth"},
	areaFill	=> ${$parameters}{"areaFill"},
	styleVal	=> ${$parameters}{"styleVal"},
	joinStyle	=> ${$parameters}{"joinStyle"},
	capStyle	=> 0,
	cornerRadius	=> 0,
	fArrow		=> undef,
	bArrow		=> undef,
	points		=> [],
    };

    my $class = ref($proto) || $proto;
    bless($self, $class);
    return $self;
}

#
# Graphics::Fig::Polyline::polyline constructor
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: polyline parameters
#
sub polyline {
    my $proto  = shift;
    my $fig    = shift;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "polyline",
					 \%PolylineParameterTemplate,
			      		 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    #
    # Make sure that at least two points were given.
    #
    my $temp;
    if (!defined($temp = $parameters{"points"}) || scalar(@{$temp} < 2)) {
	croak("polyline: error: at least two points must be given");
    }

    #
    # Set remaining parameters.
    #
    my $self = $proto->new(1, \%parameters);
    ${$self}{"capStyle"} = $parameters{"capStyle"};
    ${$self}{"points"}   = $parameters{"points"};
    Graphics::Fig::Parameters::copyArrowParameters($self, \%parameters);

    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Polyline::lineto
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: polygon parameters
#
sub lineto {
    my $proto  = shift;
    my $fig    = shift;
    my $self;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "lineto",
					 \%LinetoParameterTemplate,
			      		 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    #
    # Check parameters and get the new points.
    #
    my $newPoints = $parameters{"points"};
    if (!defined($newPoints)) {
	if (!defined($parameters{"distance"})) {
	    croak("lineto error: expected distance and heading, or points");
	}
	if (!defined($parameters{"heading"})) {
	    croak("lineto error: expected distance and heading, or points");
	}
	$newPoints = [[
	    $parameters{"position"}[0] +
		$parameters{"distance"} * cos($parameters{"heading"}),
	    $parameters{"position"}[1] -
		$parameters{"distance"} * sin($parameters{"heading"})
	]];

    } else {
	if (defined($parameters{"distance"})) {
	    croak("lineto error: distance cannot be given with points");
	}
	if (defined($parameters{"heading"})) {
	    croak("lineto error: heading cannot be given with points");
	}
	if (scalar(@{$newPoints}) == 0) {
	    croak("lineto error: expected at least one point");
	}
    }

    #
    # If we have an open lineto object, get the object, curPoints and
    # finalPoint.
    #
    my $curPoints;
    my $finalPoint;
    if (defined($self = ${$tos}{"openLineto"})) {
	$curPoints = ${$self}{"points"};
	$finalPoint = ${$curPoints}[$#{$curPoints}];
    }

    #
    # If we don't have an open lineto object, or if any parameter has
    # changed from the existing object, construct a new object.
    #
    my $position = $parameters{"position"};
    if (!defined($self) || !defined($finalPoint) ||
	$parameters{"detachedLineto"} ||
	${$position}[0] 		!= ${$finalPoint}[0] 		||
	${$position}[1] 		!= ${$finalPoint}[1] 		||
	${$self}{"lineStyle"}		!= $parameters{"lineStyle"}	||
	${$self}{"lineThickness"}	!= $parameters{"lineThickness"} ||
	${$self}{"penColor"}		!= $parameters{"penColor"}	||
	${$self}{"fillColor"}		!= $parameters{"fillColor"}	||
	${$self}{"depth"}		!= $parameters{"depth"}		||
	${$self}{"areaFill"}		!= $parameters{"areaFill"}	||
	${$self}{"styleVal"}		!= $parameters{"styleVal"} 	||
	${$self}{"joinStyle"}		!= $parameters{"joinStyle"} 	||
	${$self}{"capStyle"} 		!= $parameters{"capStyle"} 	||
	Graphics::Fig::Parameters::compareArrowParameters($self,
			\%parameters) != 0) {

	$self = $proto->new(1, \%parameters);
	${$self}{"capStyle"} = $parameters{"capStyle"};
	${$self}{"points"}   = $parameters{"points"};
	Graphics::Fig::Parameters::copyArrowParameters($self, \%parameters);
	$curPoints = [ $position ];
	${$self}{"points"}  = $curPoints;
	push(@{${$tos}{"objects"}}, $self);
	${$tos}{"openLineto"} = $self;
    }

    #
    # Add the new points and set position to the final point.
    #
    push(@{$curPoints}, @{$newPoints});
    ${$tos}{"options"}{"position"} = ${$newPoints}[$#{$newPoints}];

    return $self;
}

#
# Graphics::Fig::Polyline::box constructor
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: box parameters
#
sub box {
    my $proto  = shift;
    my $fig    = shift;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "box",
					 \%BoxParameterTemplate,
			      		 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    #
    # Construct the object.
    #
    my $self;
    my $cornerRadius = $parameters{"cornerRadius"};
    if (defined($cornerRadius) && $cornerRadius != 0) {
	$self = $proto->new(4, \%parameters);
	${$self}{"cornerRadius"} = $cornerRadius;
    } else {
	$self = $proto->new(2, \%parameters);
    }

    #
    # Construct the box from two corners.
    #
    my $temp;
    if (defined($temp = $parameters{"points"})) {
	my ($x1, $y1, $x2, $y2);

	if (defined($parameters{"width"})) {
	    croak("box: error: width not allowed with points");
	}
	if (defined($parameters{"height"})) {
	    croak("box: error: height not allowed with points");
	}
	if (defined($parameters{"center"})) {
	    croak("box: error: center not allowed with points");
	}
	if (scalar(@{$temp}) == 1) {
	    ($x1, $y1) = @{$parameters{"position"}};
	    ($x2, $y2) = @{${$temp}[0]};
	} elsif (scalar(@{$temp}) == 2) {
	    ($x1, $y1) = @{${$temp}[0]};
	    ($x2, $y2) = @{${$temp}[1]};
	} else {
	    croak("box: error: expected 1 or 2 points");
	}
	${$self}{"points"} = [
	    [ $x1, $y1 ], [ $x2, $y1 ], [ $x2, $y2 ], [ $x1, $y2 ], [ $x1, $y1 ]
	];

    } elsif (defined(my $width  = $parameters{"width"}) &&
             defined(my $height = $parameters{"height"})) {
	my ($xc, $yc);
	if (defined($parameters{"center"})) {
	    ($xc, $yc) = @{$parameters{"center"}};
	} else {
	    ($xc, $yc) = @{$parameters{"position"}};
	}
	my $dx = $width  / 2.0;
	my $dy = $height / 2.0;
	${$self}{"points"} = [
	    [ $xc - $dx, $yc - $dy ],
	    [ $xc + $dx, $yc - $dy ],
	    [ $xc + $dx, $yc + $dy ],
	    [ $xc - $dx, $yc + $dy ],
	    [ $xc - $dx, $yc - $dy ]
	];

    } else {
	croak("box: error: expected width and height or 1 or 2 points");
    }
    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Polyline::polygon constructor
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: polygon parameters
#
sub polygon {
    my $proto  = shift;
    my $fig    = shift;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "polygon",
					 \%PolygonParameterTemplate,
			      		 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    #
    # Construct the object.
    #
    my $self = $proto->new(3, \%parameters);

    #
    # Regular Polygon
    #
    my $n;
    if (defined($n = $parameters{"n"})) {
	my $center;
	my $rotation = 0.0;
	my $firstPoint;
	my $basePoint;	# first with center at origin

	#
	# Minimum n is 3.
	#
        if ($n < 3) {
	    croak("polygon: error: n must be at least 3");
	}

	#
	# Find the center.
	#
	if (defined($parameters{"center"})) {
	    $center = $parameters{"center"};
	} else {
	    $center = $parameters{"position"};
	}

	#
	# Get the first point.
	#
	if (defined($parameters{"points"})) {
	    my $points = $parameters{"points"};
	    if (scalar(@{$points}) != 1) {
		croak("polygon: error: only one point allowed with n");
	    }
	    $firstPoint = ${$points}[0];
	    $basePoint = [ ${$firstPoint}[0] - ${$center}[0],
	                   ${$firstPoint}[1] - ${$center}[1] ];
	    if (defined($parameters{"r"})) {
		croak("polygon: error: r not allowed with points");
	    }
	    if (defined($parameters{"rotation"})) {
		croak("polygon: error: rotation not allowed with points");
	    }
	} else {
	    my $r;
	    if (!defined($r = $parameters{"r"})) {
		croak("polygon: error: r parameter required");
	    }
	    if (defined($parameters{"rotation"})) {
		$rotation = $parameters{"rotation"};
	    }
	    $basePoint = [ $r * cos($rotation), -$r * sin($rotation) ];
	    $firstPoint = [ ${$basePoint}[0] + ${$center}[0],
	                    ${$basePoint}[1] + ${$center}[1] ];
	}
	push(@{${$self}{"points"}}, $firstPoint);
	for (my $i = 1; $i < $n; ++$i) {
	    my $c = cos(2 * pi * $i / $n);
	    my $s = sin(2 * pi * $i / $n);
	    my $point = [
		 $c * ${$basePoint}[0] + $s * ${$basePoint}[1] + ${$center}[0],
	        -$s * ${$basePoint}[0] + $c * ${$basePoint}[1] + ${$center}[1]
	    ];
	    push(@{${$self}{"points"}}, $point);
	}

    #
    # Polygon from Points
    #
    } else {
	my $points = $parameters{"points"};
	if (scalar(@{$points}) < 3) {
	    croak("polygon: error: expected n or at least 3 points");
	}
	if (defined($parameters{"r"})) {
	    croak("polygon: error: r not allowed with points");
	}
	if (defined($parameters{"rotation"})) {
	    croak("polygon: error: rotation not allowed with points");
	}
	@{${$self}{"points"}} = @{$points};
    }

    #
    # Duplicate the first point.
    #
    {
	my $points = ${$self}{"points"};
	push(@{$points}, ${$points}[0]);
    }
    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Polyline::picture constructor
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: picture parameters
#
sub picture {
    my $proto  = shift;
    my $fig    = shift;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "pictures",
					 \%PictureParameterTemplate,
			      		 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    #
    # Make sure the filename was given.
    #
    my $filename   = $parameters{"filename"};
    if (!defined($filename)) {
	croak("picture: error: filename must be given");
    }
    if ($filename =~ m/\n/) {
	croak("picture: error: invalid filename");
    }

    #
    # Construct the object.
    #
    my $self = $proto->new(5, \%parameters);
    ${$self}{"filename"} = $filename;
    ${$self}{"flipped"}  = 0;

    #
    # Construct the bounding box from two corners.
    #
    my $temp;
    if (defined($temp = $parameters{"points"})) {
	my ($x1, $y1, $x2, $y2);

	if (defined($parameters{"width"})) {
	    croak("picture: error: width not allowed with points");
	}
	if (defined($parameters{"height"})) {
	    croak("picture: error: height not allowed with points");
	}
	if (defined($parameters{"center"})) {
	    croak("picture: error: center not allowed with points");
	}
	if (scalar(@{$temp}) == 1) {
	    ($x1, $y1) = @{$parameters{"position"}};
	    ($x2, $y2) = @{${$temp}[0]};
	} elsif (scalar(@{$temp}) == 2) {
	    ($x1, $y1) = @{${$temp}[0]};
	    ($x2, $y2) = @{${$temp}[1]};
	} else {
	    croak("picture: error: expected 1 or 2 points");
	}
	${$self}{"points"} = [
	    [ $x1, $y1 ], [ $x2, $y1 ], [ $x2, $y2 ], [ $x1, $y2 ], [ $x1, $y1 ]
	];

    } else {
	#
	# Find the center.
	#
	my ($xc, $yc);
	if (defined($parameters{"center"})) {
	    ( $xc, $yc ) = @{$parameters{"center"}};
	} else {
	    ( $xc, $yc ) = @{$parameters{"position"}};
	}

	#
	# Find width and height.  If the size is not completely specified,
	# compute the missing width and height from the image properties.
	#
	my $width      = $parameters{"width"};
	my $height     = $parameters{"height"};
	my $resolution = $parameters{"resolution"};
	if (!defined($width) || !defined($height)) {
	    my $info = image_info($filename);
	    if (my $error = ${$info}{"error"}) {
		croak("picture: error: ${error}");
	    }
	    if (!defined($resolution)) {
		$resolution = &_convertResolution(${$info}{"resolution"}, 1);
	    }
	    die "picture: internal error" unless ref($resolution) eq "ARRAY";
	    my $nWidth  = ${$info}{"width"};
	    my $nHeight = ${$info}{"height"};
	    if (!defined($nWidth)  || $nWidth <= 0.0 ||
		!defined($nHeight) || $nHeight <= 0.0) {
		croak("picture: error: cannot determine image size");
	    }
	    $nWidth  /= ${$resolution}[0];
	    $nHeight /= ${$resolution}[1];
	    if (defined($width)) {
		$height = $nHeight * $width / $nWidth;
	    } elsif (defined($height)) {
		$width = $nWidth * $height / $nHeight;
	    } else {
		$width  = $nWidth;
		$height = $nHeight;
	    }
	}
	my $dx = $width  / 2.0;
	my $dy = $height / 2.0;
	${$self}{"points"} = [
	    [ $xc - $dx, $yc - $dy ],
	    [ $xc + $dx, $yc - $dy ],
	    [ $xc + $dx, $yc + $dy ],
	    [ $xc - $dx, $yc + $dy ],
	    [ $xc - $dx, $yc - $dy ]
	];
    }

    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Polyline::translate
#   $self:       object
#   $parameters: reference to parameter hash
#
sub translate {
    my $self       = shift;
    my $parameters = shift;

    @{${$self}{"points"}} = Graphics::Fig::Parameters::translatePoints(
    		$parameters, @{${$self}{"points"}});

    return 1;
}

#
# Graphics::Fig::Polyline::rotate
#   $self:       object
#   $parameters: reference to parameter hash
#
sub rotate {
    my $self       = shift;
    my $parameters = shift;
    my $rotation = ${$parameters}{"rotation"};

    @{${$self}{"points"}} = Graphics::Fig::Parameters::rotatePoints(
    		$parameters, @{${$self}{"points"}});

    # Change box and arc-box to polygon if rotated to a non right angle.
    my $subtype = ${$self}{"subtype"};
    if (sin($rotation) * cos($rotation) != 0 &&
        ($subtype == 2 || $subtype == 4)) {
	${$self}{"subtype"} = 3;
    }

    return 1;
}

#
# Graphics::Fig::Polyline::scale
#   $self:       object
#   $parameters: reference to parameter hash
#
sub scale {
    my $self       = shift;
    my $parameters = shift;

    @{${$self}{"points"}} = Graphics::Fig::Parameters::scalePoints(
    		$parameters, @{${$self}{"points"}});

    my $subtype = ${$self}{"subtype"};
    if ($subtype == 5) {
	my $scale = ${$parameters}{"scale"};
	if (${$scale}[0] * ${$scale}[1] < 0) {
	    ${$self}{"flipped"} ^= 1;
	}
    }
}

#
# Graphics::Fig::Polyline return [[xmin, ymin], [xmax, ymax]]
#   $self:       object
#   $parameters: getbbox parameters
#
sub getbbox {
    my $self       = shift;
    my $parameters = shift;

    return Graphics::Fig::Parameters::getbboxFromPoints(@{${$self}{"points"}});
}

#
# Graphics::Fig::Polyline::print
#   $self:       object
#   $fh:         reference to output file handle
#   $parameters: save parameters
#
sub print {
    my $self       = shift;
    my $fh         = shift;
    my $parameters = shift;

    my $figPerInch = Graphics::Fig::_figPerInch($parameters);
    my $subtype = ${$self}{"subtype"};

    #
    # Print
    #
    printf $fh ("2 %d %d %.0f %d %d %d -1 %d %.3f %d %d %.0f %d %d %d\n",
           $subtype,
           ${$self}{"lineStyle"},
           ${$self}{"lineThickness"} * 80.0,
           ${$self}{"penColor"},
           ${$self}{"fillColor"},
           ${$self}{"depth"},
           ${$self}{"areaFill"},
           ${$self}{"styleVal"} * 80.0,
           ${$self}{"joinStyle"},
           ${$self}{"capStyle"},
           ${$self}{"cornerRadius"} * 80.0,
	   defined(${$self}{"fArrow"}) ? 1 : 0,
	   defined(${$self}{"bArrow"}) ? 1 : 0,
	   scalar(@{${$self}{"points"}}));
    Graphics::Fig::Parameters::printArrowParameters($self, $fh, $parameters);
    if ($subtype == 5) {
	printf $fh ("    %d %s\n", ${$self}{"flipped"}, ${$self}{"filename"});
    }
    foreach my $point (@{${$self}{"points"}}) {
	printf $fh ("\t%.0f %.0f\n",
		${$point}[0] * $figPerInch,
		${$point}[1] * $figPerInch);
    }
}

1;
