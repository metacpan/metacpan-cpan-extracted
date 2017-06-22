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
package Graphics::Fig::Compound;
our $VERSION = 'v1.0.2';

use strict;
use warnings;
use utf8;
use Carp;
use POSIX qw(floor ceil);
use Regexp::Common qw /number/;
use Graphics::Fig::Parameters;

#
# Graphics::Fig::Compound::new
#   $proto:      class prototype
#   $fig:        Fig instance
#   $objects:    objects to group
#   $parameters: compound parameters
#
sub new {
    my $proto      = shift;
    my $fig        = shift;
    my $objects    = shift;
    my $parameters = shift;

    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];

    my $self = {
	grid    => ${$parameters}{"grid"},
	objects => $objects,
    };
    my $class = ref($proto) || $proto;
    bless($self, $class);
    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Compound::translate
#   $self:       object
#   $parameters: reference to parameter hash
#
sub translate {
    my $self       = shift;
    my $parameters = shift;

    foreach my $object (@{${$self}{"objects"}}) {
	$object->translate($parameters);
    }
    return 1;
}

#
# Graphics::Fig::Compound::rotate
#   $self:       object
#   $parameters: reference to parameter hash
#
sub rotate {
    my $self       = shift;
    my $parameters = shift;

    foreach my $object (@{${$self}{"objects"}}) {
	$object->rotate($parameters);
    }
    return 1;
}

#
# Graphics::Fig::Compound::scale
#   $self:       object
#   $parameters: reference to parameter hash
#
sub scale {
    my $self       = shift;
    my $parameters = shift;

    foreach my $object (@{${$self}{"objects"}}) {
	$object->scale($parameters);
    }
    return 1;
}

#
# Graphics::Fig::Compound::getbbox: return [[xmin, ymin], [xmax, ymax]]
#   $self:       object
#   $parameters: parameters to getbbox
#
sub getbbox {
    my $self       = shift;
    my $parameters = shift;

    my ($x_min, $y_min, $x_max, $y_max);

    #
    # Find the bounding box for all contained objects.
    #
    foreach my $object (@{${$self}{"objects"}}) {
	my $bbox = $object->getbbox();
	if (!defined($x_min)) {
	    $x_min = ${$bbox}[0][0];
	    $y_min = ${$bbox}[0][1];
	    $x_max = ${$bbox}[1][0];
	    $y_max = ${$bbox}[1][1];
	    next;
	}
	if (${$bbox}[0][0] < $x_min) {
	    $x_min = ${$bbox}[0][0];
	}
	if (${$bbox}[0][1] < $y_min) {
	    $y_min = ${$bbox}[0][1];
	}
	if (${$bbox}[1][0] > $x_max) {
	    $x_max = ${$bbox}[1][0];
	}
	if (${$bbox}[1][1] > $y_max) {
	    $y_max = ${$bbox}[1][1];
	}
    }

    #
    # If there are contained objects, snap the corners to the grid.
    #
    if (defined($x_min)) {
	my $grid;

	#
	# If grid is not given, default to 0.1 inches if imperial
	# or 0.25 cm if metric.
	#
	if (!defined($grid = ${$self}{"grid"})) {
	    if (${$parameters}{"units"}[1] eq "Metric") {
		$grid = 2.54 * 0.25;
	    } else {
		$grid = 0.1;
	    }
	}
	#
	# Snap the corners to the given grid.
	#
	if ($grid > 0) {
	    $x_min = $grid * floor($x_min / $grid);
	    $y_min = $grid * floor($y_min / $grid);
	    $x_max = $grid *  ceil($x_max / $grid);
	    $y_max = $grid *  ceil($y_max / $grid);
	}

    #
    # Otherwise, create an empty group at the current position.
    #
    } else {
	$x_min = ${$parameters}{"position"}[0];
	$y_min = ${$parameters}{"position"}[1];
	$x_max = ${$parameters}{"position"}[0];
	$y_max = ${$parameters}{"position"}[1];
    }
    return [ [ $x_min, $y_min ], [ $x_max, $y_max ] ];
}

#
# Graphics::Fig::Compound::print
#   $self:       object
#   $fh:         reference to output file handle
#   $parameters: save parameters
#
sub print {
    my $self       = shift;
    my $fh         = shift;
    my $parameters = shift;

    my $bbox = $self->getbbox($parameters);
    my $figPerInch = Graphics::Fig::_figPerInch($parameters);

    printf $fh ("6 %.0f %.0f %.0f %.0f\n",
	${$bbox}[0][0] * $figPerInch,
	${$bbox}[0][1] * $figPerInch,
	${$bbox}[1][0] * $figPerInch,
	${$bbox}[1][1] * $figPerInch);

    foreach my $object (@{${$self}{"objects"}}) {
	$object->print($fh, $parameters);
    }

    printf $fh ("-6\n");

    return 1;
}

1;
