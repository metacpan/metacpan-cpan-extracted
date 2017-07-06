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
package Graphics::Fig::Text;
our $VERSION = 'v1.0.3';

use strict;
use warnings;
use Carp;
use Math::Trig;
use Image::Info qw(image_info);
use Graphics::Fig::Color;
use Graphics::Fig::Parameters;


#
# Text Parameters
#
my %TextParameterTemplate = (
    positional	=> {
	"."	=> [ "text" ],
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::PositionParameter,	# must be second
	\%Graphics::Fig::Parameters::ColorParameter,
	\%Graphics::Fig::Parameters::DepthParameter,
	\%Graphics::Fig::Parameters::RotationParameter,
	 @Graphics::Fig::Parameters::TextParameters,
	{
	    name	=> "text",
	    convert	=> \&Graphics::Fig::Parameters::convertText,
	},
    ],
);

#
# Graphics::Fig::Text::setTextSize: compute the length and height of text
#
sub setTextSize {
    my $self = shift;
    my $pointSize = ${$self}{"fontSize"};
    my $text = ${$self}{"text"};

    #
    # TODO: This calculation is only an approximation.  It should determine
    # the height and length of the text based on the given font and size.
    #
    my $height = $pointSize / 72.0;
    my $length = $height * length($text) / 2.0;
    ${$self}{"length"} = $length;
    ${$self}{"height"} = $height;
}

#
# Graphics::Fig::Text::text constructor
#   $proto:      prototype
#   $fig:        parent object
#   @parameters: spline parameters
#
sub text {
    my $proto  = shift;
    my $fig    = shift;
    my $text;
    my $rotation;

    #
    # Parse parameters.
    #
    my %parameters;
    my $stack = ${$fig}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($fig, "spline",
					 \%TextParameterTemplate,
			      		 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    if (!defined($text = $parameters{"text"})) {
	croak("text: no text string given");
    }
    if (!defined($rotation = $parameters{"rotation"})) {
	$rotation = 0;
    }

    #
    # Construct the object.
    #
    my $self = {
	justification	=> $parameters{"textJustification"},
	penColor	=> $parameters{"penColor"},
	depth		=> $parameters{"depth"},
	fontName	=> $parameters{"fontName"}[1],
	fontSize	=> $parameters{"fontSize"},
	fontFlags	=> $parameters{"fontName"}[0],
	rotation	=> $rotation,
	length		=> undef,
	height		=> undef,
	points		=> [ $parameters{"position"} ],
	text		=> $text,
    };
    my $class = ref($proto) || $proto;
    bless($self, $class);

    #
    # Apply font flags and calculate the text size.
    #
    ${$self}{"fontFlags"} |= $parameters{"fontFlags"} & ~4;
    $self->setTextSize();

    push(@{${$tos}{"objects"}}, $self);
    return $self;
}

#
# Graphics::Fig::Text::translate
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
# Graphics::Fig::Text::rotate
#   $self:       object
#   $parameters: reference to parameter hash
#
sub rotate {
    my $self       = shift;
    my $parameters = shift;
    my $rotation = ${$parameters}{"rotation"};

    @{${$self}{"points"}} = Graphics::Fig::Parameters::rotatePoints(
    		$parameters, @{${$self}{"points"}});
    ${$self}{"rotation"} += $rotation;

    return 1;
}

#
# Graphics::Fig::Text::scale
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

    @{${$self}{"points"}} = Graphics::Fig::Parameters::scalePoints(
    		$parameters, @{${$self}{"points"}});
    ${$self}{"length"} *= $u;
    ${$self}{"height"} *= $v;

    return 1;
}

#
# Graphics::Fig::Text::getbbox
#   $self:       object
#   $parameters: getbbox parameters
#
#   Return [[xmin, ymin], [xmax, ymax]]
#
sub getbbox {
    my $self       = shift;
    my $parameters = shift;
    my $justification = ${$self}{"justification"};
    my $position      = ${$self}{"points"}[0];
    my $height	      = ${$self}{"height"};
    my $length	      = ${$self}{"length"};
    my ($xmin, $ymin, $xmax, $ymax);

    #
    # TODO: We need width and height (see setTextSize).  Additionally, we need
    # to know the distance between the lowest part of the text, e.g. bottom of
    # "y" or "g" and the baseline.
    #
    my $shift = $height / 3.0;

    if ($justification == 2) {
	$xmin = ${$position}[0] - $length;
	$xmax = ${$position}[0];
    } elsif ($justification == 1) {
	$xmin = ${$position}[0] - $length / 2.0;
	$xmax = ${$position}[0] + $length / 2.0;
    } else {
	$xmin = ${$position}[0];
	$xmax = ${$position}[0] + $length;
    }
    $ymin = $shift + ${$position}[1];
    $ymax = $shift + ${$position}[1] - $height;

    return [ [ $xmin, $ymin ], [ $xmax, $ymax ] ];
}

#
# Graphics::Fig::Text::print
#   $self:       object
#   $fh:         reference to output file handle
#   $parameters: save parameters
#
sub print {
    my $self       = shift;
    my $fh         = shift;
    my $parameters = shift;
    my $text_in    = ${$self}{"text"};
    my $text_out   = "";

    #
    # Encode bytes above 127 with octal escapes.
    #
    utf8::encode($text_in);
    for (my $i = 0; $i < length($text_in); ++$i) {
	my $c = substr($text_in, $i, 1);
	my $n = ord($c);
	die if $n < 0 || $n > 255;	# otherwise, utf8::encode didn't work
	if ($n == 0x5C) {		# '\'
	    $text_out .= '\\';
	    $text_out .= $c;
	    next;
	}
	if ($n > 127) {
	    $text_out .= sprintf("\\%03o", $n);
	    next;
	}
	$text_out .= $c;
    }

    #
    # Print
    #
    my $figPerInch = Graphics::Fig::_figPerInch($parameters);
    printf $fh ("4 %d %d %d -1 %d %.0f %.4f %u %.0f %.0f %d %d %s\\001\n",
	   ${$self}{"justification"},
	   ${$self}{"penColor"},
	   ${$self}{"depth"},
	   ${$self}{"fontName"},
	   ${$self}{"fontSize"},
	   ${$self}{"rotation"},
	   ${$self}{"fontFlags"},
	   ${$self}{"height"} * $figPerInch,
	   ${$self}{"length"} * $figPerInch,
	   ${$self}{"points"}[0][0] * $figPerInch,
	   ${$self}{"points"}[0][1] * $figPerInch,
	   $text_out);
}

1;
