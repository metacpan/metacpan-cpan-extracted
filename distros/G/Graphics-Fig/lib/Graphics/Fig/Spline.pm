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
package Graphics::Fig::Spline;
our $VERSION = 'v1.0.8';

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

#
# Graphics::Fig::Spline::validateControlPoint
#
sub validateControlPoint {
    my $prefix = shift;
    my $value  = shift;

    if (!($value =~ m/^\s*($RE_REAL)/)) {
	croak("${prefix}: expected number");
    }
    if ($value < -1.0 || $value > 1.0) {
	croak("${prefix}: control point must be in -1.0 .. +1.0");
    }
    return 1;
}

#
# Graphics::Fig::Spline::convertShapeFactors
#   $fig:    fig object
#   $prefix: error message prefix
#   $value:  control point array
#
sub convertShapeFactors {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if (ref($value) eq "") {
	&validateControlPoint($prefix, $value);
	return $value;
    }
    if (ref($value) ne "ARRAY") {
	croak("${prefix}: error: expected number or array");
    }
    foreach my $element (@{$value}) {
	&validateControlPoint($prefix, $element);
    }
    return $value;
}

my @SplineCommonParameters = (
    \%Graphics::Fig::Parameters::UnitsParameter,	# must be first
    \%Graphics::Fig::Parameters::PositionParameter,	# must be second
    \%Graphics::Fig::Parameters::ColorParameter,
    \%Graphics::Fig::Parameters::DepthParameter,
     @Graphics::Fig::Parameters::LineParameters,
     @Graphics::Fig::Parameters::FillParameters,
    \%Graphics::Fig::Parameters::CapStyleParameter,
     @Graphics::Fig::Parameters::ArrowParameters,
    \%Graphics::Fig::Parameters::PointsParameter,
    {
	name	=> "splineSubtype",
	convert	=> \&Graphics::Fig::Parameters::convertSplineSubtype,
	aliases	=> [ "subtype" ],
    },
    {
	name	=> "shapeFactors",
	convert	=> \&convertShapeFactors,
	aliases => [ "shapeFactor" ],
    },
);

#
# Spline Parameters
#
my %SplineParameterTemplate = (
    positional	=> {
	"@"	=> [ "points" ],
    },
    named	=> [
	 @SplineCommonParameters,
    ],
);

#
# Splineto Parameters
#
my %SplinetoParameterTemplate = (
    positional	=> {
	".."	=> [ "distance", "heading" ],
	"@"	=> [ "points" ],
    },
    named	=> [
	@SplineCommonParameters,
	{
	    name		=> "distance",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
	{
	    name		=> "heading",
	    convert		=> \&Graphics::Fig::Parameters::convertAngle,
	},
	{
	    name		=> "new",
	    convert		=> \&Graphics::Fig::Parameters::convertBool,
	}
    ],
);

#
# Graphics::Fig::Spline::new: base constructor
#   $proto:      prototype
#   $parameters: ref to parameter hash
#
sub new {
    my $proto       = shift;
    my $parameters  = shift;

    my $self = {
	subtype		=> ${$parameters}{"splineSubtype"},
	lineStyle	=> ${$parameters}{"lineStyle"},
	lineThickness	=> ${$parameters}{"lineThickness"},
	penColor	=> ${$parameters}{"penColor"},
	fillColor	=> ${$parameters}{"fillColor"},
	depth		=> ${$parameters}{"depth"},
	areaFill	=> ${$parameters}{"areaFill"},
	styleVal	=> ${$parameters}{"styleVal"},
	capStyle	=> 0,
	fArrow		=> undef,
	bArrow		=> undef,
	points		=> [],
	shapeFactors	=> [],
    };

    my $class = ref($proto) || $proto;
    bless($self, $class);
    return $self;
}

#
# Graphics::Fig::Spline::addPoints: add points and shapeFactors
#   $self:       object
#   $parameters: reference to parameter hash
#   $newPoints:  reference to array of points to add
#
sub addPoints {
    my $self       = shift;
    my $prefix     = shift;
    my $parameters = shift;
    my $newPoints  = shift;

    #
    # Add the new points.
    #
    push(@{${$self}{"points"}}, @{$newPoints});

    #
    # Add the new shape factors.
    #
    my $subtype = ${$self}{"subtype"};
    if (defined(my $shapeFactors = ${$parameters}{"shapeFactors"})) {
	if ($subtype != 4 && $subtype != 5) {
	    croak("${prefix}: shapeFactors may be given only with xspline");
	}
	my $m = scalar(@{$newPoints});

	#
	# If the shapeFactor(s) parameter is a scalar, apply it to
	# each point.
	#
	if (ref($shapeFactors) eq "") {
	    for (my $i = 0; $i < $m; ++$i) {
		push(@{${$self}{"shapeFactors"}}, $shapeFactors);
	    }
	#
	# Otherwise, the length of the shapeFactor vector must be the
	# same as length of the new point vector.
	#
	} else {
	    my $n = scalar(@{$shapeFactors});
	    if ($n != $m) {
		croak("${prefix}: expected ${m} control points; found ${n}");
	    }
	    push(@{${$self}{"shapeFactors"}}, @{$shapeFactors});
	}

    #
    # For approximated and interpolated splines, set the shape
    # factors to 1 and -1, respectively.
    #
    } else {
	if ($subtype == 4 || $subtype == 5) {
	    croak("${prefix}: xspline requires shapeFactors parameter");
	}
	for (my $i = 0; $i < scalar(@{$newPoints}); ++$i) {
	    push(@{${$self}{"shapeFactors"}}, $subtype < 2 ? 1.0 : -1.0);
	}
    }
}

#
# Graphics::Fig::Spline::spline constructor
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: spline parameters
#
sub spline {
    my $proto  = shift;
    my $fig    = shift;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "spline",
					 \%SplineParameterTemplate,
			      		 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    #
    # Make sure that at least three points were given.
    #
    my $temp;
    if (!defined($temp = $parameters{"points"}) || scalar(@{$temp} < 3)) {
	croak("spline: error: at least three points must be given");
    }
    my @newPoints = @{$temp};

    #
    # Build object.
    #
    my $self = $proto->new(\%parameters);
    ${$self}{"capStyle"} = $parameters{"capStyle"};
    &addPoints($self, "spline", \%parameters, \@newPoints);
    Graphics::Fig::Parameters::copyArrowParameters($self, \%parameters);

    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Spline::splineto
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: polygon parameters
#
sub splineto {
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
	Graphics::Fig::Parameters::parse($fig, "splineto",
					 \%SplinetoParameterTemplate,
			      		 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    #
    # Check parameters and get the new points.
    #
    my @newPoints;
    if (!defined($parameters{"points"})) {
	if (!defined($parameters{"distance"})) {
	    croak("splineto error: expected distance and heading, or points");
	}
	if (!defined($parameters{"heading"})) {
	    croak("splineto error: expected distance and heading, or points");
	}
	push(@newPoints, [
	    $parameters{"position"}[0] +
		$parameters{"distance"} * cos($parameters{"heading"}),
	    $parameters{"position"}[1] -
		$parameters{"distance"} * sin($parameters{"heading"})
	]);

    } else {
	if (defined($parameters{"distance"})) {
	    croak("splineto error: distance cannot be given with points");
	}
	if (defined($parameters{"heading"})) {
	    croak("splineto error: heading cannot be given with points");
	}
	if (scalar(@{$parameters{"points"}}) == 0) {
	    croak("splineto error: expected at least one point");
	}
	@newPoints = @{$parameters{"points"}};
    }

    #
    # If we have an open splineto object, get the object, curPoints and
    # finalPoint.
    #
    my $curPoints;
    my $curShapeFactors;
    my $finalPoint;
    if (defined($self = ${$tos}{"openSplineto"})) {
	$curPoints        = ${$self}{"points"};
	$curShapeFactors  = ${$self}{"shapeFactors"};
	$finalPoint = ${$curPoints}[$#{$curPoints}];
    }

    #
    # If we don't have an open splineto object, or if any parameter has
    # changed relative to the existing object, construct a new object.
    #
    my $position = $parameters{"position"};
    if (!defined($self) || !defined($finalPoint) ||
	$parameters{"new"} ||
	${$position}[0] 		!= ${$finalPoint}[0] 		||
	${$position}[1] 		!= ${$finalPoint}[1] 		||
	${$self}{"subtype"}		!= $parameters{"splineSubtype"}	||
	${$self}{"lineStyle"}		!= $parameters{"lineStyle"}	||
	${$self}{"lineThickness"}	!= $parameters{"lineThickness"} ||
	${$self}{"penColor"}		!= $parameters{"penColor"}	||
	${$self}{"fillColor"}		!= $parameters{"fillColor"}	||
	${$self}{"depth"}		!= $parameters{"depth"}		||
	${$self}{"areaFill"}		!= $parameters{"areaFill"}	||
	${$self}{"styleVal"}		!= $parameters{"styleVal"} 	||
	${$self}{"capStyle"} 		!= $parameters{"capStyle"} 	||
	Graphics::Fig::Parameters::compareArrowParameters($self,
			\%parameters) != 0) {

	$self = $proto->new(\%parameters);
	${$self}{"capStyle"} = $parameters{"capStyle"};
	${$self}{"points"}   = $parameters{"points"};
	Graphics::Fig::Parameters::copyArrowParameters($self, \%parameters);
	$curPoints = [];
	$curShapeFactors = [];
	${$self}{"points"} = $curPoints;
	${$self}{"shapeFactors"} = $curShapeFactors;
	push(@{${$tos}{"objects"}}, $self);
	${$tos}{"openSplineto"} = $self;
	unshift(@newPoints, $position);
    }

    #
    # Add the new points and set position to the final point.
    #
    &addPoints($self, "splineto", \%parameters, \@newPoints);
    ${$tos}{"options"}{"position"} = $newPoints[$#newPoints];

    return $self;
}

#
# Graphics::Fig::Spline::translate
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
# Graphics::Fig::Spline::rotate
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
# Graphics::Fig::Spline::scale
#   $self:       object
#   $parameters: reference to parameter hash
#
sub scale {
    my $self       = shift;
    my $parameters = shift;

    @{${$self}{"points"}} = Graphics::Fig::Parameters::scalePoints(
    		$parameters, @{${$self}{"points"}});
}

#
# Graphics::Fig::Spline::getbox: return [[xmin, ymin], [xmax, ymax]]
#   $self:       object
#   $parameters: getbbox parameters
#
sub getbbox {
    my $self       = shift;
    my $parameters = shift;

    return Graphics::Fig::Parameters::getbboxFromPoints(@{${$self}{"points"}});
}

#
# Graphics::Fig::Spline::print
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
    # If only two points were given, format as a polyline.
    #
    if (@{${$self}{"points"}} == 2) {
	printf $fh ("2 1 %d %.0f %d %d %d -1 %d %.3f 0 %d 0 %d %d %d\n",
	       ${$self}{"lineStyle"},
	       ${$self}{"lineThickness"} * 80.0,
	       ${$self}{"penColor"},
	       ${$self}{"fillColor"},
	       ${$self}{"depth"},
	       ${$self}{"areaFill"},
	       ${$self}{"styleVal"} * 80.0,
	       ${$self}{"capStyle"},
	       defined(${$self}{"fArrow"}) ? 1 : 0,
	       defined(${$self}{"bArrow"}) ? 1 : 0,
	       scalar(@{${$self}{"points"}}));
	Graphics::Fig::Parameters::printArrowParameters($self, $fh,
							$parameters);
	foreach my $point (@{${$self}{"points"}}) {
	    printf $fh ("\t%.0f %.0f\n",
		    ${$point}[0] * $figPerInch,
		    ${$point}[1] * $figPerInch);
	}

    #
    # Otherwise, format as spline.
    #
    } else {
	printf $fh ("3 %d %d %.0f %d %d %d -1 %d %.3f %d %d %d %d\n",
	       $subtype,
	       ${$self}{"lineStyle"},
	       ${$self}{"lineThickness"} * 80.0,
	       ${$self}{"penColor"},
	       ${$self}{"fillColor"},
	       ${$self}{"depth"},
	       ${$self}{"areaFill"},
	       ${$self}{"styleVal"} * 80.0,
	       ${$self}{"capStyle"},
	       defined(${$self}{"fArrow"}) ? 1 : 0,
	       defined(${$self}{"bArrow"}) ? 1 : 0,
	       scalar(@{${$self}{"points"}}));
	Graphics::Fig::Parameters::printArrowParameters($self, $fh,
							$parameters);
	foreach my $point (@{${$self}{"points"}}) {
	    printf $fh ("\t%.0f %.0f\n",
		    ${$point}[0] * $figPerInch,
		    ${$point}[1] * $figPerInch);
	}
	foreach my $shapeFactors (@{${$self}{"shapeFactors"}}) {
	    printf $fh ("\t%f\n", $shapeFactors);
	}
    }
}

1;
