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
package Graphics::Fig::Ellipse;
our $VERSION = 'v1.0.4';

use strict;
use warnings;
use Carp;
use Math::Trig;
use Graphics::Fig::Color;
use Graphics::Fig::Matrix;
use Graphics::Fig::Parameters;

#
# RE_INT: regular expression matching an integer
#
my $RE_INT = "(?:(?:[-+]?)(?:[0123456789]+))";

#
# Graphics::Fig::Ellipse::generalToCanonical
#   ( $A, $B, $C, $D, $E, $F )
#
# Returns:
#   ( $a, $b, $xc, $yc, $rotation )
#
sub generalToCanonical {
    my ($A, $B, $C, $D, $E, $F) = @_;

    my $d = $B * $B - 4.0 * $A * $C;
    if ($d > - Graphics::Fig::Matrix::EPS) {
	croak("given points do not describe a circle or ellipse");
    }
    my $p  = 2.0 * ($A*$E*$E + $C*$D*$D - $B*$D*$E + $d*$F);
    my $q  = $A + $C;
    my $r  =  sqrt(($A - $C) * ($A - $C) + $B * $B);
    my $a  = -sqrt($p * ($q + $r)) / $d;
    my $b  = -sqrt($p * ($q - $r)) / $d;
    my $xc = (2*$C*$D - $B*$E) / $d;
    my $yc = (2*$A*$E - $B*$D) / $d;
    my $rotation;
    if (abs($B) < Graphics::Fig::Matrix::EPS) {
	if ($A <= $C) {
	    $rotation = 0;
	} else {
	    $rotation = pi / 2.0;
	}
    } else {
	$rotation = atan2(-($C - $A - $r) / $B, 1.0);
    }
    return ($a, $b, $xc, $yc, $rotation);
}

#
# Graphics::Fig::_convertCircleSubtype
#   $self:    class instance
#   $prefix:  error message prefix
#   $value:   {radius|diameter}
#   $context: parameter context
#
sub _convertCircleSubtype {
    my $self    = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value eq "radius") {
	return 3;
    }
    if ($value eq "diameter") {
	return 4;
    }
    if ($value =~ m/^$RE_INT$/) {
	if ($value != 3 && $value != 4) {
	    croak("${prefix}: ${value}: error: " .
	    	    "expected integer between 3 and 4");
	    return $value;
	}
    }
    croak("${prefix}: ${value}: error: expected {radius|diameter}");
}

#
# Graphics::Fig::_convertEllipseSubtype
#   $self:    class instance
#   $prefix:  error message prefix
#   $value:   {radius|diameter}
#   $context: parameter context
#
sub _convertEllipseSubtype {
    my $self    = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value eq "radii") {
	return 1;
    }
    if ($value eq "diameters") {
	return 2;
    }
    if ($value =~ m/^$RE_INT$/) {
	if ($value != 1 && $value != 2) {
	    croak("${prefix}: ${value}: error: " .
	    	    "expected integer between 1 and 2");
	    return $value;
	}
    }
    croak("${prefix}: ${value}: error: expected {radii|diameters}");
}

my @EllipseCommonParameters = (
    \%Graphics::Fig::Parameters::UnitsParameter,	# must be first
    \%Graphics::Fig::Parameters::PositionParameter,	# must be second
    \%Graphics::Fig::Parameters::CenterParameter,
    \%Graphics::Fig::Parameters::ColorParameter,
    \%Graphics::Fig::Parameters::DepthParameter,
     @Graphics::Fig::Parameters::FillParameters,
     @Graphics::Fig::Parameters::LineParameters,
    \%Graphics::Fig::Parameters::PointsParameter,
    \%Graphics::Fig::Parameters::RotationParameter,
);

#
# Circle Parameters
#
my %CircleParameterTemplate = (
    positional	=> {
	"."	=> [ "d" ],
	"@"	=> [ "points" ],
    },
    named	=> [
	@EllipseCommonParameters,
	{
	    name		=> "subtype",
	    convert		=> \&_convertCircleSubtype,
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
    ],
);

#
# Ellipse Parameters
#
my %EllipseParameterTemplate = (
    positional	=> {
	".."	=> [ "a", "b" ],
	"..."	=> [ "a", "b", "rotation" ],
	"@"	=> [ "points" ],
    },
    named	=> [
	@EllipseCommonParameters,
	{
	    name		=> "subtype",
	    convert		=> \&_convertEllipseSubtype,
	},
	{
	    name		=> "a",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
	{
	    name		=> "b",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
    ],
);


#
# Graphics::Fig::Ellipse::circle constructor
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: circle parameters
#
sub circle {
    my $proto  = shift;
    my $fig    = shift;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "circle",
					 \%CircleParameterTemplate,
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
	subtype		=> undef,
	center		=> undef,
	a		=> undef,
	b		=> undef,
	rotation	=> undef,
	lineStyle	=> $parameters{"lineStyle"},
	lineThickness	=> $parameters{"lineThickness"},
	penColor	=> $parameters{"penColor"},
	fillColor	=> $parameters{"fillColor"},
	depth		=> $parameters{"depth"},
	areaFill	=> $parameters{"areaFill"},
	styleVal	=> $parameters{"styleVal"},
    };

    #
    # If "r" or "d" given, set $r to radius and $dr to "r" or "d",
    # respectively.
    #
    my $r;
    my $dr;
    if (defined($parameters{"r"})) {
	if (defined($parameters{"d"})) {
	    croak("circle: error: r and d cannot be given together");
	}
	$r = $parameters{"r"};
	$dr = "r";

    } elsif (defined($parameters{"d"})) {
	$r = $parameters{"d"} / 2.0;
	$dr = "d";
    }

    #
    # Set subtype.
    #
    if (defined($parameters{"subtype"})) {
	${$self}{"subtype"} = $parameters{"subtype"};
    } elsif (defined($dr) && $dr eq "d") {
	${$self}{"subtype"} = 4;
    } else {
	${$self}{"subtype"} = 3;
    }

    #
    # Find circle from points.
    #
    if (defined(my $points = $parameters{"points"})) {
	#
	# Diameter or radius cannot be given with points.
	#
	if (defined($r)) {
	    croak("circle: ${dr} and points cannot be given together");
	}

	#
	# One point
	#
	if (@{$points} == 1) {
	    #
	    # Find the center.
	    #
	    if (defined($parameters{"center"})) {
		${$self}{"center"} = $parameters{"center"};
	    } else {
		${$self}{"center"} = $parameters{"position"};
	    }

	    #
	    # Find radius as the length of the vector relative to center.
	    #
	    my $dx = ${$points}[0][0] - ${$self}{"center"}[0];
	    my $dy = ${$points}[0][1] - ${$self}{"center"}[1];
	    my $a = sqrt($dx*$dx + $dy*$dy);
	    ${$self}{"a"} = $a;
	    ${$self}{"b"} = $a;
	    # rotation set below

	#
	# Three points: calc circle from three arbitrary points.
	#
	} elsif (@{$points} == 3) {
	    if (defined($parameters{"center"})) {
		croak("circle: error: center may not be given with " .
		      "three points");
	    }
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
	    # Convert to canonical form.  Returned rotation is
	    # always zero -- ignore it.
	    #
	    my ($a, $b, $xc, $yc, $dummy_rotation) =
	    	&generalToCanonical(1, 0, 1, $D, $E, $F);
	    die "$a != $b" unless $a == $b;
	    die "rotation = $dummy_rotation" unless $dummy_rotation == 0.0;
	    ${$self}{"center"} = [ $xc, $yc ];
	    ${$self}{"a"} = $a;
	    ${$self}{"b"} = $a;
	    # rotation set below

	} else {
	    croak("circle: error: expected either 1 or 3 points");
	}

	#
	# Find the rotation.
	#
	die unless ref(${$self}{"center"}) eq "ARRAY";
	if (defined($parameters{"rotation"})) {
	    ${$self}{"rotation"} = $parameters{"rotation"};
	} else {
	    my $dx = ${$points}[0][0] - ${$self}{"center"}[0];
	    my $dy = ${$points}[0][1] - ${$self}{"center"}[1];
	    ${$self}{"rotation"} = atan2(-$dy, $dx);
	}

    } else {
	#
	# Make sure r or d was given.
	#
	if (!defined($r)) {
	    croak("circle: error: expected r, d or points");
	}

	#
	# Find the center.
	#
	if (defined($parameters{"center"})) {
	    ${$self}{"center"} = $parameters{"center"};
	} else {
	    ${$self}{"center"} = $parameters{"position"};
	}

	#
	# Set the axes.
	#
	${$self}{"a"} = $r;
	${$self}{"b"} = $r;

	#
	# Find the rotation.
	#
	if (defined($parameters{"rotation"})) {
	    ${$self}{"rotation"} = $parameters{"rotation"};
	} else {
	    ${$self}{"rotation"} = 0;
	}
    }

    my $class = ref($proto) || $proto;
    bless($self, $class);
    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Ellipse::ellipse constructor
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: ellipse parameters
#
sub ellipse {
    my $proto  = shift;
    my $fig    = shift;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "ellipse",
					 \%EllipseParameterTemplate,
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
	subtype		=> undef,
	center		=> undef,
	a		=> undef,
	b		=> undef,
	rotation	=> undef,
	lineStyle	=> $parameters{"lineStyle"},
	lineThickness	=> $parameters{"lineThickness"},
	penColor	=> $parameters{"penColor"},
	fillColor	=> $parameters{"fillColor"},
	depth		=> $parameters{"depth"},
	areaFill	=> $parameters{"areaFill"},
	styleVal	=> $parameters{"styleVal"},
    };

    #
    # Find the subtype.
    #
    if (defined($parameters{"subtype"})) {
	${$self}{"subtype"} = $parameters{"subtype"};
    } else {
	${$self}{"subtype"} = 1;
    }

    #
    # Find ellipse from points.
    #
    if (defined(my $points = $parameters{"points"})) {
	if (defined($parameters{"a"}) || defined($parameters{"b"})) {
	    croak("ellipse: axes and points cannot be given together");
	}

	#
	# Two points: calculate ellipse from 2 points, center and rotation.
	# Requires (x1^2 - x2^2)(y1^2 - y2^2) < 0 after rotating the major
	# axis to an x or y axis.
	#
	if (@{$points} == 2) {
	    #
	    # Find the center.
	    #
	    my ($xc, $yc);
	    if (defined($parameters{"center"})) {
		( $xc, $yc ) = @{$parameters{"center"}};
	    } else {
		( $xc, $yc ) = @{$parameters{"position"}};
	    }
	    ${$self}{"center"} = [ $xc, $yc ];

	    #
	    # Translate the points to center.
	    #
	    my $x1 = ${$points}[0][0] - $xc;
	    my $y1 = ${$points}[0][1] - $yc;
	    my $x2 = ${$points}[1][0] - $xc;
	    my $y2 = ${$points}[1][1] - $yc;

	    #
	    # Find the rotation.  If not given, calculate it from the
	    # first point.
	    #
	    my $rotation;
	    if (!defined($rotation = $parameters{"rotation"})) {
		$rotation = atan2(-$y1, $x1);
	    }
	    ${$self}{"rotation"} = $rotation;

	    #
	    # Rotate the ellipse clockwise to place major axis along
	    # the x-axis.
	    #
	    my $c = cos($rotation);
	    my $s = sin($rotation);
	    ( $x1, $y1 ) = ( $c * $x1 - $s * $y1, $s * $x1 + $c * $y1 );
	    ( $x2, $y2 ) = ( $c * $x2 - $s * $y2, $s * $x2 + $c * $y2 );

	    # Let A = 1.  Solve for C and F:
	    #   C y1^2 + F == -x1^2
	    #   C y2^2 + F == -x2^2
	    #
	    my @M = (
		[ $y1*$y1, 1, -$x1*$x1 ],
		[ $y2*$y2, 1, -$x2*$x2 ],
	    );
	    my $d = Graphics::Fig::Matrix::reduce(\@M);
	    if (abs($d) < Graphics::Fig::Matrix::EPS) {
		croak("ellipse: error: singular matrix");
	    }
	    my $C = $M[0][2];
	    my $F = $M[1][2];
	    my ($a, $b, $dummy_xc, $dummy_yc, $dummy_rotation) =
	    	&generalToCanonical(1, 0, $C, 0.0, 0.0, $F);
	    die unless abs($dummy_xc) < Graphics::Fig::Matrix::EPS;
	    die unless abs($dummy_yc) < Graphics::Fig::Matrix::EPS;

	    #
	    # Swap $a and $b if the minor diagonal is larger than the
	    # major diagonal, i.e. dummy_rotation is not zero.
	    #
	    if (1.0 > $C) {
		($a, $b) = ($b, $a);
	    }
	    ${$self}{"a"}        = $a;
	    ${$self}{"b"}        = $b;
	    ${$self}{"rotation"} = $rotation;

	#
	# Three points: calculate ellipse from 3 arbitrary points and center.
	#
	} elsif (@{$points} == 3) {
	    if (defined($parameters{"rotation"})) {
		croak("ellipse: error: rotation may not be given " .
		      "with 3 points");
	    }

	    #
	    # Find the center.
	    #
	    my ($xc, $yc);
	    if (defined($parameters{"center"})) {
		( $xc, $yc ) = @{$parameters{"center"}};
	    } else {
		( $xc, $yc ) = @{$parameters{"position"}};
	    }
	    ${$self}{"center"} = [ $xc, $yc ];

	    #
	    # Find the three vectors relative to center.
	    #
	    my $x1 = ${$points}[0][0] - $xc;
	    my $y1 = ${$points}[0][1] - $yc;
	    my $x2 = ${$points}[1][0] - $xc;
	    my $y2 = ${$points}[1][1] - $yc;
	    my $x3 = ${$points}[2][0] - $xc;
	    my $y3 = ${$points}[2][1] - $yc;

	    #
	    # Let A = 1.  Solve for B, C and F:
	    #   B x1 y1 + C y1^2 + F == -x1^2
	    #   B x2 y2 + C y2^2 + F == -x2^2
	    #   B x3 y1 + C y3^2 + F == -x3^2
	    #
	    my @M = (
		[ $x1*$y1, $y1*$y1, 1, -$x1*$x1 ],
		[ $x2*$y2, $y2*$y2, 1, -$x2*$x2 ],
		[ $x3*$y3, $y3*$y3, 1, -$x3*$x3 ],
	    );
	    my $d = Graphics::Fig::Matrix::reduce(\@M);
	    if (abs($d) < Graphics::Fig::Matrix::EPS) {
		croak("ellipse: error: singular matrix");
	    }
	    my $B = $M[0][3];
	    my $C = $M[1][3];
	    my $F = $M[2][3];
	    my ($a, $b, $dummy_xc, $dummy_yc, $rotation) =
	    	&generalToCanonical(1, $B, $C, 0.0, 0.0, $F);
	    die unless abs($dummy_xc) < Graphics::Fig::Matrix::EPS;
	    die unless abs($dummy_yc) < Graphics::Fig::Matrix::EPS;

	    ${$self}{"a"}        = $a;
	    ${$self}{"b"}        = $b;
	    ${$self}{"rotation"} = $rotation;

	} elsif (@{$points} == 5) {
	    if (defined($parameters{"center"})) {
		croak("ellipse: error: center may not be given " .
		      "with 3 points");
	    }
	    if (defined($parameters{"rotation"})) {
		croak("ellipse: error: rotation may not be given " .
		      "with 3 points");
	    }

	    #
	    # Find the vectors relative to the figure origin.
	    #
	    my $x1 = ${$points}[0][0];
	    my $y1 = ${$points}[0][1];
	    my $x2 = ${$points}[1][0];
	    my $y2 = ${$points}[1][1];
	    my $x3 = ${$points}[2][0];
	    my $y3 = ${$points}[2][1];
	    my $x4 = ${$points}[3][0];
	    my $y4 = ${$points}[3][1];
	    my $x5 = ${$points}[4][0];
	    my $y5 = ${$points}[4][1];

	    #
	    # Let A = 1.  Solve for B, C, D, E and F:
	    #   
	    #   B x1 y1 + C y1^2 + D x1 + E y1 + F == -x1^2
	    #   B x2 y2 + C y2^2 + D x2 + E y2 + F == -x2^2
	    #   B x3 y3 + C y3^2 + D x3 + E y3 + F == -x3^2
	    #   B x4 y4 + C y4^2 + D x4 + E y4 + F == -x4^2
	    #   B x5 y5 + C y5^2 + D x5 + E y5 + F == -x5^2
	    #
	    my @M = (
		[ $x1*$y1, $y1*$y1, $x1, $y1, 1, -$x1*$x1 ],
		[ $x2*$y2, $y2*$y2, $x2, $y2, 1, -$x2*$x2 ],
		[ $x3*$y3, $y3*$y3, $x3, $y3, 1, -$x3*$x3 ],
		[ $x4*$y4, $y4*$y4, $x4, $y4, 1, -$x4*$x4 ],
		[ $x5*$y5, $y5*$y5, $x5, $y5, 1, -$x5*$x5 ],
	    );
	    my $d = Graphics::Fig::Matrix::reduce(\@M);
	    if (abs($d) < Graphics::Fig::Matrix::EPS) {
		croak("ellipse: error: singular matrix");
	    }
	    my $B = $M[0][5];
	    my $C = $M[1][5];
	    my $D = $M[2][5];
	    my $E = $M[3][5];
	    my $F = $M[4][5];

	    #
	    # Convert to canonical form.
	    #
	    my ($a, $b, $xc, $yc, $rotation) =
	    	&generalToCanonical(1, $B, $C, $D, $E, $F);

	    ${$self}{"a"}        = $a;
	    ${$self}{"b"}        = $b;
	    ${$self}{"center"}	 = [ $xc, $yc ];
	    ${$self}{"rotation"} = $rotation;

	} else {
	    croak("ellipse: error: expected either 2, 3 or 5 points");
	}


    } else {
	if (!defined($parameters{"a"}) || !defined($parameters{"b"})) {
	    croak("ellipse: error: expected (a, b) or points");
	}

	#
	# Find the center.
	#
	my ($xc, $yc);
	if (defined($parameters{"center"})) {
	    ( $xc, $yc ) = @{$parameters{"center"}};
	} else {
	    ( $xc, $yc ) = @{$parameters{"position"}};
	}
	${$self}{"center"} = [ $xc, $yc ];

	#
	# Set axes.
	#
	${$self}{"a"} = $parameters{"a"};
	${$self}{"b"} = $parameters{"b"};

	#
	# Find rotation.
	#
	if (defined($parameters{"rotation"})) {
	    ${$self}{"rotation"} = $parameters{"rotation"};
	} else {
	    ${$self}{"rotation"} = 0.0;
	}
    }

    my $class = ref($proto) || $proto;
    bless($self, $class);
    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Ellipse::translate
#   $self:       object
#   $parameters: reference to parameter hash
#
sub translate {
    my $self       = shift;
    my $parameters = shift;

    ( ${$self}{"center"} ) = Graphics::Fig::Parameters::translatePoints(
    		$parameters, ${$self}{"center"});

    return 1;
}

#
# Graphics::Fig::Ellipse::rotate
#   $self:       object
#   $parameters: reference to parameter hash
#
sub rotate {
    my $self       = shift;
    my $parameters = shift;
    my $rotation = ${$parameters}{"rotation"};

    ( ${$self}{"center"} ) = Graphics::Fig::Parameters::rotatePoints(
    		$parameters, ${$self}{"center"});
    ${$self}{"rotation"} += $rotation;

    return 1;
}

#
# Graphics::Fig::Ellipse::scale
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
    # Simple case: scale proportionally.  Rotation does not change.
    #
    if ($u == $v) {
	${$self}{"a"} *= $u;
	${$self}{"b"} *= $v;

    #
    # General case: calculate new a, b, and rotation from general form.
    # It's not sufficient to simply scale a and b by the projection on
    # the rotation because when the ellipse is distorted, the position
    # of the axes shifts along the perimeter.  Note that subtype circle
    # becomes an ellipse in "print" if necessary.
    #
    } else {
	my $a = ${$self}{"a"};
	my $b = ${$self}{"b"};
	my $c = cos(${$self}{"rotation"});
	my $s = sin(${$self}{"rotation"});
	my $A = ($a*$a*$s*$s + $b*$b*$c*$c)      / ($u*$u);
	my $B = 2.0 * ($b*$b - $a*$a) * -$s * $c / ($u*$v);
	my $C = ($a*$a*$c*$c + $b*$b*$s*$s)      / ($v*$v);
	my $F = -$a*$a*$b*$b;
	my @R = &generalToCanonical($A, $B, $C, 0.0, 0.0, $F);
	${$self}{"a"} = $R[0];
	${$self}{"b"} = $R[1];
	${$self}{"rotation"} = $R[4];
    }
    ( ${$self}{"center"} ) = Graphics::Fig::Parameters::scalePoints(
    		$parameters, ${$self}{"center"});
}

#
# Graphics::Fig::Polyline return [[xmin, ymin], [xmax, ymax]]
#   $self:       object
#   $parameters: getbbox parameters
#
sub getbbox {
    my $self       = shift;
    my $parameters = shift;

    my $center   = ${$self}{"center"};
    my $a        = ${$self}{"a"};
    my $b        = ${$self}{"b"};
    my $rotation = ${$self}{"rotation"};
    my $xc = ${$center}[0];
    my $yc = ${$center}[1];
    my $c  = cos($rotation);
    my $s  = sin($rotation);
    my $dx = sqrt($a*$a*$c*$c + $b*$b*$s*$s);
    my $dy = sqrt($b*$b*$c*$c + $a*$a*$s*$s);
    return Graphics::Fig::Parameters::getbboxFromPoints(
    	[ $xc + $dx, $yc ],
	[ $xc, $yc + $dy ],
	[ $xc - $dx, $yc ],
	[ $xc, $yc - $dy ]);
}

#
# Graphics::Fig::Ellipse::print
#   $self:       object
#   $fh:         referece to output file handle
#   $parameters: save parameters
#
sub print {
    my $self       = shift;
    my $fh         = shift;
    my $parameters = shift;

    my $figPerInch = Graphics::Fig::_figPerInch($parameters);

    #
    # If a != b after converting to fig units and the subtype is
    # a circle, change it to an ellipse.
    #
    my $subtype = ${$self}{"subtype"};
    die unless defined(${$self}{"subtype"});
    my $scaled_a = sprintf("%.0f", ${$self}{"a"} * $figPerInch);
    my $scaled_b = sprintf("%.0f", ${$self}{"b"} * $figPerInch);
    if ($scaled_a != $scaled_b) {
	if ($subtype == 3) {
	    $subtype = 1;
	} elsif ($subtype == 4) {
	    $subtype = 2;
	}
    }

    #
    # Calculate start and end points.
    #
    my $dx =  ${$self}{"a"} * cos(${$self}{"rotation"});
    my $dy = -${$self}{"a"} * sin(${$self}{"rotation"});
    my @start;
    if ($subtype & 1) {
	@start = @{${$self}{"center"}};
    } else {
	@start = ( ${${$self}{"center"}}[0] - $dx,
	           ${${$self}{"center"}}[1] - $dy );
    }
    my @end = ( ${${$self}{"center"}}[0] + $dx,
                ${${$self}{"center"}}[1] + $dy );

    #
    # Print
    #
    printf $fh ("1 %d %d %.0f %d %d %d -1 %d %.3f 1 %.4f " .
                "%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f\n",
           $subtype,
           ${$self}{"lineStyle"},
           ${$self}{"lineThickness"} * 80.0,
           ${$self}{"penColor"},
           ${$self}{"fillColor"},
           ${$self}{"depth"},
           ${$self}{"areaFill"},
           ${$self}{"styleVal"} * 80.0,
           ${$self}{"rotation"},
           ${$self}{"center"}[0] * $figPerInch,
           ${$self}{"center"}[1] * $figPerInch,
           $scaled_a,
           $scaled_b,
	   $start[0] * $figPerInch,
	   $start[1] * $figPerInch,
	   $end[0]   * $figPerInch,
	   $end[1]   * $figPerInch);
}

1;
