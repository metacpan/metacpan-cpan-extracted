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
package Graphics::Fig::Arc;
our $VERSION = 'v1.0.8';

use strict;
use warnings;
use utf8;
use Carp;
use Math::Trig;
use Graphics::Fig::Color;
use Graphics::Fig::Ellipse;
use Graphics::Fig::Matrix;
use Graphics::Fig::Parameters;
use Graphics::Fig::Arc;

#
# RE_INT: regular expression matching an integer
#
my $RE_INT = '(?:(?:[-+]?)(?:[0123456789]+))';

#
# Graphics::Fig::Arc::convertSubtype
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   direction parameter
#   $context: parameter context
#
sub convertSubtype {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $result;
    my $temp;

    $value =~ y/[A-Z]/[a-z]/;
    if ($value eq "open") {
	return 1;
    }
    if ($value eq "pie" || $value eq "pie-wedge" || $value eq "closed") {
	return 2;
    }
    if (!($value =~ s/^\s*($RE_INT)//)) {
	croak("${prefix}: ${value}: error: expected open or pie");
    }
    if ($value != 1 && $value != 2) {
	croak("${prefix}: ${value}: error: expected 1 or 2");
    }
    return $value;
}

#
# Graphics::Fig::Arc::convertDirection
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   direction parameter
#   $context: parameter context
#
sub convertDirection {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;
    my $result;
    my $temp;

    $value =~ y/[A-Z]/[a-z]/;
    if ($value eq "clockwise" || $value eq "cw") {
	return 0;
    }
    if ($value eq "counterclockwise" || $value eq "ccw") {
	return 1;
    }
    if (!($value =~ s/^\s*($RE_INT)//)) {
	croak("${prefix}: ${value}: error: expected clockwise or " .
			                   "counterclockwise");
    }
    if ($value != 0 && $value != 1) {
	croak("${prefix}: ${value}: error: expected 0 or 1");
    }
    return $value;
}

#
# Arc Parameters
#
my %ArcParameterTemplate = (
    positional	=> {
	"."	=> [ "r" ],
	".."	=> [ "r", "angle" ],
	"@"	=> [ "points" ],
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::PositionParameter,	# must be second
	 @Graphics::Fig::Parameters::ArrowParameters,
	\%Graphics::Fig::Parameters::CapStyleParameter,
	\%Graphics::Fig::Parameters::CenterParameter,
	\%Graphics::Fig::Parameters::ColorParameter,
	\%Graphics::Fig::Parameters::DepthParameter,
	 @Graphics::Fig::Parameters::FillParameters,
	 @Graphics::Fig::Parameters::LineParameters,
	\%Graphics::Fig::Parameters::PointsParameter,
	\%Graphics::Fig::Parameters::RotationParameter,
	{
	    name		=> "subtype",
	    convert		=> \&convertSubtype,
	    default		=> 1
	},
	{
	    name		=> "d",
	    aliases		=> [ "diameter" ],
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
	{
	    name		=> "r",
	    aliases		=> [ "radius" ],
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
	{
	    name		=> "direction",
	    convert		=> \&convertDirection,
	},
	{
	    name		=> "controlAngle",
	    convert		=> \&Graphics::Fig::Parameters::convertAngle,
	},
	{
	    name		=> "angle",
	    aliases		=> [ "Θ" ],
	    convert		=> \&Graphics::Fig::Parameters::convertAngle,
	},
    ],
);

#
# Arcto Parameters
#
my %ArctoParameterTemplate = (
    positional	=> {
	".."	=> [ "distance", "heading" ],
	"..."	=> [ "distance", "heading", "angle" ],
	"@"	=> [ "points" ],
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::PositionParameter,	# must be second
	 @Graphics::Fig::Parameters::ArrowParameters,
	\%Graphics::Fig::Parameters::CapStyleParameter,
	\%Graphics::Fig::Parameters::CenterParameter,
	\%Graphics::Fig::Parameters::ColorParameter,
	\%Graphics::Fig::Parameters::DepthParameter,
	 @Graphics::Fig::Parameters::FillParameters,
	 @Graphics::Fig::Parameters::LineParameters,
	\%Graphics::Fig::Parameters::PointsParameter,
	{
	    name		=> "distance",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
	{
	    name		=> "heading",
	    convert		=> \&Graphics::Fig::Parameters::convertAngle,
	},
	{
	    name		=> "subtype",
	    convert		=> \&convertSubtype,
	    default		=> 1
	},
	{
	    name		=> "direction",
	    convert		=> \&convertDirection,
	},
	{
	    name		=> "controlAngle",
	    convert		=> \&Graphics::Fig::Parameters::convertAngle,
	},
	{
	    name		=> "angle",
	    aliases		=> [ "Θ", ],
	    convert		=> \&Graphics::Fig::Parameters::convertAngle,
	},
    ],
);

#
# Graphics::Fig::Arg::normalizeAngle: normalize angle to [-2 pi .. 2 pi ]
# 		with sign consistent with direction
# $angle:     angle
# $direction: 1:CCW 0:CW
#
sub normalizeAngle {
    my $angle     = shift;
    my $direction = shift;

    if (abs($angle) > pi) {
	$angle = atan2(sin($angle), cos($angle));
    }
    die "arc: internal error 1" unless ($angle >= - pi && $angle <= pi);
    if ($direction && $angle < 0) {
	$angle += 2 * pi;
    } elsif (!$direction && $angle > 0) {
	$angle -= 2 * pi;
    }
    return $angle;
}

#
# Graphics::Fig::Arc::calcAngleParameters: find angles from parameters
#   $parameters: reference to parameter hash
#
#   The returned angle is in the range [-2 pi .. 2 pi] given the width
#   of the arc, where positive values indicate a counterclockwise arc and
#   negative values indicate a clockwise arc.  The returned controlAngle
#   is lower in magnitude and follows the sign of angle.
#
# Return:
#   ( angle, controlAngle )
#
sub calcAngleParameters {
    my $parameters = shift;
    my $angle        = ${$parameters}{"angle"};
    my $controlAngle = ${$parameters}{"controlAngle"};
    my $direction    = ${$parameters}{"direction"};

    #
    # If the direction wasn't given, take it from the sign of angle.
    # If angle wasn't given, take it from the sign of controlAngle.
    # If controlAngle wasn't given, default to counterclockwise.
    #
    if (!defined($direction)) {
	if (defined($angle)) {
	    $direction = $angle >= 0;
	} elsif (defined($controlAngle)) {
	    $direction = $controlAngle >= 0;
	} else {
	    $direction = 1;
	}
    }

    #
    # Normalize angle.  If not given, default it to pi/2 or -pi/2
    # depending on direction.
    #
    if (defined($angle)) {
	$angle = &normalizeAngle($angle, $direction);

    } else {
	if ($direction) {
	    $angle =   pi / 2;
	} else {
	    $angle = - pi / 2;
	}
    }

    #
    # Normalize controlAngle and test that it's within the arc.  If not
    # given, default it to $angle / 2.
    #
    if (defined($controlAngle)) {
	$controlAngle = &normalizeAngle($controlAngle, $direction);
	if (abs($controlAngle) >= abs($angle)) {
	    croak("arc: error: controlAngle is outside of arc");
	}
    } else {
	$controlAngle = $angle / 2;
    }

    die "arc: internal error 2" if $angle * $controlAngle < 0;
    die "arc: internal error 3" if abs($controlAngle) > abs($angle);
    die "arc: internal error 4" if $controlAngle * $angle < 0;

    return ( $angle, $controlAngle );
}

#
# Graphics::Fig::Arc::calcAnglesFromPoints: find angles from three points
#   $points: [ [ x1, y1 ], [ x2, y2 ], [ x3, y3 ] ]
#
#   The returned angle is in the range [-2 pi .. 2 pi] given the width
#   of the arc, where positive values indicate a counterclockwise arc and
#   negative values indicate a clockwise arc.  The returned controlAngle
#   is lower in magnitude and follows the sign of angle.
#
# Return:
#   ( angle, controlAngle )
#
sub calcAnglesFromPoints {
    my $points = shift;

    #
    # Let A = 1.  Solve for D, E and F:
    #	D x1 + E y1 + F == -(x1^2 + y1^2)
    #	D x2 + E y2 + F == -(x2^2 + y2^2)
    #	D x3 + E y3 + F == -(x3^2 + y3^2)
    #
    my $x1 = ${$points}[0][0];
    my $y1 = ${$points}[0][1];
    my $x2 = ${$points}[1][0];
    my $y2 = ${$points}[1][1];
    my $x3 = ${$points}[2][0];
    my $y3 = ${$points}[2][1];
    my @M = (
	[ $x1, $y1, 1, -($x1*$x1 + $y1*$y1) ],
	[ $x2, $y2, 1, -($x2*$x2 + $y2*$y2) ],
	[ $x3, $y3, 1, -($x3*$x3 + $y3*$y3) ],
    );
    my $d = Graphics::Fig::Matrix::reduce(\@M);
    if (abs($d) < Graphics::Fig::Matrix::EPS) {
	croak("arc: error: singular matrix");
    }
    my $D = $M[0][3];
    my $E = $M[1][3];
    my $F = $M[2][3];

    #
    # Find the arc direction by finding the sign of the the z component
    # of the cross product of point2-point1 and point3-point1.
    #
    my $z = $x1 * ($y2 - $y3) + $x2 * ($y3 - $y1) + $x3 * ($y1 - $y2);
    my $direction = ($z < 0);

    #
    # Find center and radius and compute angles.
    #
    my ($x, $y);
    my ($r, $b, $xc, $yc, $dummy_rotation) =
	Graphics::Fig::Ellipse::generalToCanonical(1, 0, 1, $D, $E, $F);
    die "arc: internal error 6: $r != $b" unless $r == $b;
    my $c =  ($x1 - $xc) / $r;
    my $s = -($y1 - $yc) / $r;
    $x = $c * ($x2 - $xc) - $s * ($y2 - $yc);
    $y = $s * ($x2 - $xc) + $c * ($y2 - $yc);
    my $controlAngle = &normalizeAngle(atan2(-$y, $x), $direction);
    $x = $c * ($x3 - $xc) - $s * ($y3 - $yc);
    $y = $s * ($x3 - $xc) + $c * ($y3 - $yc);
    my $angle = &normalizeAngle(atan2(-$y, $x), $direction);;

    die "arc: internal error 7" if abs($controlAngle) > abs($angle);
    die "arc: internal error 8" if $controlAngle * $angle < 0;

    return ( $angle, $controlAngle );
}

#
# Graphics::Fig::Arc::findPoint2: return the center and point2
#   $self: object
#
# Return: ([ xc, yc ], [ x2, y2 ])
#
sub findPoint2 {
    my $self = shift;

    #
    # Get points and angles.
    #
    my $point1       = ${$self}{"point1"};
    my $point3       = ${$self}{"point3"};
    my $angle        = ${$self}{"angle"};
    my $controlAngle = ${$self}{"controlAngle"};
    my $x1 = ${$point1}[0];
    my $y1 = ${$point1}[1];
    my $x3 = ${$point3}[0];
    my $y3 = ${$point3}[1];

    #
    # Find the center.
    #
    my $half_cot = cot($angle / 2) / 2;
    my $xc = $x1 + ($x3 - $x1) / 2 + ($y3 - $y1) * $half_cot;
    my $yc = $y1 + ($y3 - $y1) / 2 - ($x3 - $x1) * $half_cot;

    #
    # Find point 2.
    #
    my $c  = cos($controlAngle);
    my $s  = sin($controlAngle);
    my $x  = $x1 - $xc;
    my $y  = $y1 - $yc;
    my $x2 = $xc +  $c * $x + $s * $y;
    my $y2 = $yc + -$s * $x + $c * $y;

    return ([ $xc, $yc ], [ $x2, $y2 ]);
}

#
# Graphics::Fig::Arc::arc constructor
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: arc parameters
#
sub arc {
    my $proto  = shift;
    my $fig    = shift;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "arc",
					 \%ArcParameterTemplate,
			      		 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    #
    # Construct the object.  Undefined parameters are set below.
    #
    my $self = {
	subtype		=> $parameters{"subtype"},
	lineStyle	=> $parameters{"lineStyle"},
	lineThickness	=> $parameters{"lineThickness"},
	penColor	=> $parameters{"penColor"},
	fillColor	=> $parameters{"fillColor"},
	depth		=> $parameters{"depth"},
	areaFill	=> $parameters{"areaFill"},
	styleVal	=> $parameters{"styleVal"},
	capStyle	=> $parameters{"capStyle"},
	point1		=> undef,
	point3		=> undef,
	angle		=> undef,
	controlAngle	=> undef,
    };
    Graphics::Fig::Parameters::copyArrowParameters($self, \%parameters);

    #
    # If "r" or "d" given, set $r to radius.
    #
    my $r;
    if (defined($parameters{"r"})) {
	if (defined($parameters{"d"})) {
	    croak("arc: error: r and d cannot be given together");
	}
	$r = $parameters{"r"};

    } elsif (defined($parameters{"d"})) {
	$r = $parameters{"d"} / 2.0;
    }

    my $points = $parameters{"points"};
    if (!defined($points)) {
	if (!defined($r)) {
	    croak("arc: error: r, d or points parameter required");
	}
	my ($angle, $controlAngle) = &calcAngleParameters(\%parameters);
	my ($xc, $yc);
	if (defined($parameters{"center"})) {
	    ($xc, $yc) = @{$parameters{"center"}};
	} else {
	    ($xc, $yc) = @{$parameters{"position"}};
	}
	my $rotation;
	if (!defined($rotation = $parameters{"rotation"})) {
	    $rotation = 0;
	}
	${$self}{"point1"} = [ $xc + $r *  cos($rotation),
			       $yc + $r * -sin($rotation) ];
	${$self}{"point3"} = [ $xc + $r *  cos($rotation + $angle),
			       $yc + $r * -sin($rotation + $angle) ];
	${$self}{"angle"} = $angle;
	${$self}{"controlAngle"} = $controlAngle;

    } elsif (scalar(@{$points}) == 1) {
	my ($xc, $yc, $x3, $y3);

	if (defined($parameters{"d"})) {
	    croak("arc: error: d cannot be given with two points");
	}
	if (defined($parameters{"r"})) {
	    croak("arc: error: r cannot be given with two points");
	}
	if (defined($parameters{"rotation"})) {
	    croak("arc: error: radius required with point and rotation");
	}
	if (defined($parameters{"center"})) {
	    ($xc, $yc) = @{$parameters{"center"}};
	} else {
	    ($xc, $yc) = @{$parameters{"position"}};
	}
	my ($angle, $controlAngle) = &calcAngleParameters(\%parameters);
	my $x = ${$points}[0][0] - $xc;
	my $y = ${$points}[0][1] - $yc;
	my $c = cos($angle);
	my $s = sin($angle);
	$x3 = $xc + $c * $x + $s * $y;
	$y3 = $yc - $s * $x + $c * $y;
	${$self}{"point1"}       = ${$points}[0];
	${$self}{"point3"}       = [ $x3, $y3 ];
	${$self}{"angle"}        = $angle;
	${$self}{"controlAngle"} = $controlAngle;

    } elsif (scalar(@{$points}) == 2) {
	if (defined($parameters{"d"})) {
	    croak("arc: error: d cannot be given with two points");
	}
	if (defined($parameters{"r"})) {
	    croak("arc: error: r cannot be given with two points");
	}
	if (defined($parameters{"center"})) {
	    croak("arc: error: center cannot be given with two points");
	}
	if (defined($parameters{"rotation"})) {
	    croak("arc: error: rotation cannot be given with two points");
	}
	my ($angle, $controlAngle) = &calcAngleParameters(\%parameters);
	${$self}{"point1"}       = ${$points}[0];
	${$self}{"point3"}       = ${$points}[1];
	${$self}{"angle"}        = $angle;
	${$self}{"controlAngle"} = $controlAngle;

    } elsif (scalar(@{$points}) == 3) {
	if (defined($parameters{"d"})) {
	    croak("arc: error: d cannot be given with three points");
	}
	if (defined($parameters{"r"})) {
	    croak("arc: error: r cannot be given with three points");
	}
	if (defined($parameters{"direction"})) {
	    croak("arc: error: direction cannot be given with three points");
	}
	if (defined($parameters{"controlAngle"})) {
	    croak("arc: error: controlAngle cannot be given with three points");
	}
	if (defined($parameters{"angle"})) {
	    croak("arc: error: angle cannot be given with three points");
	}
	my ( $angle, $controlAngle ) = &calcAnglesFromPoints($points);
	${$self}{"point1"}       = ${$points}[0];
	${$self}{"point3"}       = ${$points}[2];
	${$self}{"angle"}        = $angle;
	${$self}{"controlAngle"} = $controlAngle;

    } else {
	    croak("arc: error: expected between zero and three points");
    }
    my $class = ref($proto) || $proto;
    bless($self, $class);
    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Arc::arcto constructor
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: arc parameters
#
sub arcto {
    my $proto  = shift;
    my $fig    = shift;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "arcto",
					 \%ArctoParameterTemplate,
			      		 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    #
    # Construct the object.  Undefined parameters are set below.
    #
    my $self = {
	subtype		=> $parameters{"subtype"},
	lineStyle	=> $parameters{"lineStyle"},
	lineThickness	=> $parameters{"lineThickness"},
	penColor	=> $parameters{"penColor"},
	fillColor	=> $parameters{"fillColor"},
	depth		=> $parameters{"depth"},
	areaFill	=> $parameters{"areaFill"},
	styleVal	=> $parameters{"styleVal"},
	capStyle	=> $parameters{"capStyle"},
	point1		=> undef,
	point3		=> undef,
	angle		=> undef,
	controlAngle	=> undef,
    };
    Graphics::Fig::Parameters::copyArrowParameters($self, \%parameters);

    my $points = $parameters{"points"};
    if (!defined($points)) {
	my ($x3, $y3, $angle, $controlAngle);
	if (defined($parameters{"distance"}) ||
	    defined($parameters{"heading"})) {
	    if (defined($parameters{"center"})) {
		croak("arcto: error: center cannot be given with distance " .
			"and heading");
	    }
	    if (!defined($parameters{"distance"})) {
		croak("arcto: error: distance must be given with heading");
	    }
	    if (!defined($parameters{"heading"})) {
		croak("arcto: error: heading must be given with distance");
	    }
	    ($angle, $controlAngle) = &calcAngleParameters(\%parameters);
	    $x3  = $parameters{"position"}[0]
	         + $parameters{"distance"} * cos($parameters{"heading"});
	    $y3  = $parameters{"position"}[1]
	         - $parameters{"distance"} * sin($parameters{"heading"});

	} else {
	    if (!defined($parameters{"center"})) {
		croak("arcto: error: expected distance and heading, center " .
		      "or points");
	    }
	    if (defined($parameters{"distance"})) {
		croak("arcto: error: distance cannot be given with center");
	    }
	    if (defined($parameters{"heading"})) {
		croak("arcto: error: heading cannot be given with center");
	    }
	    my ($xc, $yc) = @{$parameters{"center"}};
	    ($angle, $controlAngle) = &calcAngleParameters(\%parameters);
	    my $x = $parameters{"position"}[0] - $xc;
	    my $y = $parameters{"position"}[1] - $yc;
	    my $c = cos($angle);
	    my $s = sin($angle);
	    $x3 = $xc + $c * $x + $s * $y;
	    $y3 = $yc - $s * $x + $c * $y;
	}
	${$self}{"point1"}       = $parameters{"position"};
	${$self}{"point3"}       = [ $x3, $y3 ];
	${$self}{"angle"}        = $angle;
	${$self}{"controlAngle"} = $controlAngle;

    } elsif (scalar(@{$points} == 1)) {
	if (defined($parameters{"center"})) {
	    croak("arcto: error: center cannot be given with points");
	}
	if (defined($parameters{"distance"})) {
	    croak("arcto: error: distance cannot be given with points");
	}
	if (defined($parameters{"heading"})) {
	    croak("arcto: error: heading cannot be given with points");
	}
	my ($angle, $controlAngle) = &calcAngleParameters(\%parameters);
	${$self}{"point1"}       = $parameters{"position"};
	${$self}{"point3"}       = $parameters{"points"}[0];
	${$self}{"angle"}        = $angle;
	${$self}{"controlAngle"} = $controlAngle;

    } elsif (scalar(@{$points} == 2)) {
	if (defined($parameters{"angle"})) {
	    croak("arcto: error: angle cannot be given with two points");
	}
	if (defined($parameters{"center"})) {
	    croak("arcto: error: center cannot be given with points");
	}
	if (defined($parameters{"controlAngle"})) {
	    croak("arcto: error: controlAngle cannot be given with two points");
	}
	if (defined($parameters{"direction"})) {
	    croak("arcto: error: direction cannot be given with two points");
	}
	if (defined($parameters{"distance"})) {
	    croak("arcto: error: distance cannot be given with points");
	}
	if (defined($parameters{"heading"})) {
	    croak("arcto: error: heading cannot be given with points");
	}
	my ( $angle, $controlAngle ) = &calcAnglesFromPoints([
	    $parameters{"position"}, ${$points}[0], ${$points}[1] ]);
	${$self}{"point1"}       = $parameters{"position"};
	${$self}{"point3"}       = ${$points}[1];
	${$self}{"angle"}        = $angle;
	${$self}{"controlAngle"} = $controlAngle;

    } else {
	croak("arcto: error: expected point");
    }
    ${$tos}{"options"}{"position"} = ${$self}{"point3"};

    my $class = ref($proto) || $proto;
    bless($self, $class);
    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Arc::translate
#   $self:       object
#   $parameters: reference to parameter hash
#
sub translate {
    my $self       = shift;
    my $parameters = shift;

    ( ${$self}{"point1"}, ${$self}{"point3"} ) =
	Graphics::Fig::Parameters::translatePoints(
    		$parameters, ${$self}{"point1"}, ${$self}{"point3"} );

    return 1;
}

#
# Graphics::Fig::Arc::rotate
#   $self:       object
#   $parameters: reference to parameter hash
#
sub rotate {
    my $self       = shift;
    my $parameters = shift;
    my $rotation = ${$parameters}{"rotation"};

    ( ${$self}{"point1"}, ${$self}{"point3"} ) =
	 Graphics::Fig::Parameters::rotatePoints(
    		$parameters, ${$self}{"point1"}, ${$self}{"point3"} );

    return 1;
}

#
# Graphics::Fig::Arc::scale
#   $self:       object
#   $parameters: reference to parameter hash
#
sub scale {
    my $self       = shift;
    my $parameters = shift;
    my $scale = ${$parameters}{"scale"};
    die unless defined($scale);
    my $u = ${$scale}[0];
    my $v = ${$scale}[1];

    #
    # Simple case: scale proportionally.
    #
    if (abs($u) == abs($v)) {
	( ${$self}{"point1"}, ${$self}{"point3"} ) =
	     Graphics::Fig::Parameters::scalePoints(
		    $parameters, ${$self}{"point1"}, ${$self}{"point3"} );

	#
	# If mirrored, invert the direction.
	#
	if ($u * $v < 0) {
	    ${$self}{"angle"} *= -1;
	    ${$self}{"controlAngle"} *= -1;
	}

    #
    # General case: find a new arc that passes through the three scaled
    # points.
    #
    } else {
	my $point1 = ${$self}{"point1"};
	my $point3 = ${$self}{"point3"};
	my ( $old_center, $point2 ) = &findPoint2($self);
	my @newPoints = Graphics::Fig::Parameters::scalePoints($parameters,
		            			$point1, $point2, $point3 );
	my ( $angle, $controlAngle ) = &calcAnglesFromPoints(\@newPoints);

	${$self}{"point1"}       = $newPoints[0];
	${$self}{"point3"}       = $newPoints[2];
	${$self}{"angle"}        = $angle;
	${$self}{"controlAngle"} = $controlAngle;
    }
}

#
# Graphics::Fig::Arc::crosses_axis: return positive if a CCW arc
#		intersects the given axis (helper for getbbox)
#   $point1: first point
#   $point3: final point
#   $axis:   axis
#
sub crosses_axis {
    my $point1 = shift;
    my $point3 = shift;
    my $axis   = shift;
    my $x1 = ${$point1}[0];
    my $y1 = ${$point1}[1];
    my $x3 = ${$point3}[0];
    my $y3 = ${$point3}[1];
    my $x  = ${$axis}[0];
    my $y  = ${$axis}[1];

    # Find z component of cross product of (point1 - axis) and (point2 - axis).
    return $x1 * $y3 - $x3 * $y1 + ($y1 - $y3) * $x + ($x3 - $x1) * $y;
}

#
# Graphics::Fig::Arc::getbbox: return [[xmin, ymin], [xmax, ymax]]
#   $self:       object
#   $parameters: getbbox parameters
#
sub getbbox {
    my $self       = shift;
    my $parameters = shift;

    my $point1 = ${$self}{"point1"};
    my $point3 = ${$self}{"point3"};
    my $angle  = ${$self}{"angle"};
    my $x1 = ${$point1}[0];
    my $y1 = ${$point1}[1];
    my $x3 = ${$point3}[0];
    my $y3 = ${$point3}[1];

    #
    # Find the center and radius.
    #
    my $half_cot = cot($angle / 2) / 2;
    my $xc = $x1 + ($x3 - $x1) / 2 + ($y3 - $y1) * $half_cot;
    my $yc = $y1 + ($y3 - $y1) / 2 - ($x3 - $x1) * $half_cot;
    my $dx = $x1 - $xc;
    my $dy = $y1 - $yc;
    my $r = sqrt($dx * $dx + $dy * $dy);

    #
    # First, find the bounding box of the endpoints.  Then for each
    # axis the arc crosses, expand the box as needed.
    #
    my $bbox = Graphics::Fig::Parameters::getbboxFromPoints($point1, $point3);
    if (&crosses_axis($point1, $point3, [ $xc - $r, $yc ]) * $angle > 0) {
	if ($xc - $r < ${$bbox}[0][0]) {
	    ${$bbox}[0][0] = $xc - $r;
	}
    }
    if (&crosses_axis($point1, $point3, [ $xc, $yc - $r ]) * $angle > 0) {
	if ($yc - $r < ${$bbox}[0][1]) {
	    ${$bbox}[0][1] = $yc - $r;
	}
    }
    if (&crosses_axis($point1, $point3, [ $xc + $r,  $yc ]) * $angle > 0) {
	if ($xc + $r > ${$bbox}[1][0]) {
	    ${$bbox}[1][0] = $xc + $r;
	}
    }
    if (&crosses_axis($point1, $point3, [ $xc, $yc + $r ]) * $angle > 0) {
	if ($yc + $r > ${$bbox}[1][1]) {
	    ${$bbox}[1][1] = $yc + $r;
	}
    }
    return $bbox;
}

#
# Graphics::Fig::Arc::print
#   $self:       object
#   $fh:         reference to output file handle
#   $parameters: save parameters
#
sub print {
    my $self       = shift;
    my $fh         = shift;
    my $parameters = shift;

    my $figPerInch = Graphics::Fig::_figPerInch($parameters);
    my $subtype   = ${$self}{"subtype"};
    my $direction = ${$self}{"angle"} >= 0;
    my $point1    = ${$self}{"point1"};
    my ( $center, $point2 ) = &findPoint2($self);
    my $point3 = ${$self}{"point3"};

    #
    # Print
    #
    printf $fh ("5 %d %d %.0f %d %d %d -1 %d %.3f %d %d %d %d ".
                "%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f\n",
           $subtype,
           ${$self}{"lineStyle"},
           ${$self}{"lineThickness"} * 80.0,
           ${$self}{"penColor"},
           ${$self}{"fillColor"},
           ${$self}{"depth"},
           ${$self}{"areaFill"},
           ${$self}{"styleVal"} * 80.0,
           ${$self}{"capStyle"},
           $direction,
	   defined(${$self}{"fArrow"}) ? 1 : 0,
	   defined(${$self}{"bArrow"}) ? 1 : 0,
	   ${$center}[0] * $figPerInch, ${$center}[1] * $figPerInch,
	   ${$point1}[0] * $figPerInch, ${$point1}[1] * $figPerInch,
	   ${$point2}[0] * $figPerInch, ${$point2}[1] * $figPerInch,
	   ${$point3}[0] * $figPerInch, ${$point3}[1] * $figPerInch);
    Graphics::Fig::Parameters::printArrowParameters($self, $fh, $parameters);
}

1;
