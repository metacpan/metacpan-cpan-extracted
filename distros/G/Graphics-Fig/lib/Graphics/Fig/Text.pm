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
our $VERSION = 'v1.0.8';

use strict;
use warnings;
use Carp;
use Math::Trig;
use Image::Info qw(image_info);
use Graphics::Fig::Color;
use Graphics::Fig::Parameters;
use Graphics::Fig::FontSize;


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
# Graphics::Fig::Text::calcSize: calculate dimensions of text
#
sub calcSize {
    my $self = shift;
    my $size = &Graphics::Fig::FontSize::getTextSize($self->{fontRef},
	    $self->{fontSize}, $self->{text});
    my $justification = $self->{justification};

    if ($justification == 1) {		# centered
	my $width = $size->{right} - $size->{left};

	$size->{left}  = -$width / 2.0;
	$size->{right} =  $width / 2.0;

    } elsif ($justification == 2) {	# right-justified
	my $width = $size->{right} - $size->{left};

	$size->{left}  = -$width;
	$size->{right} = 0.0;
    }
    $self->{size} = $size;
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
	Graphics::Fig::Parameters::parse($fig, "text",
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
	fontRef		=> $parameters{"fontName"},
	fontSize	=> $parameters{"fontSize"},
	fontFlags	=> $parameters{"fontName"}[0],
	rotation	=> $rotation,
	size		=> undef,
	points		=> [ $parameters{"position"} ],
	text		=> $text,
    };
    my $class = ref($proto) || $proto;
    bless($self, $class);

    #
    # Apply font flags and calculate the text size.
    #
    ${$self}{"fontFlags"} |= $parameters{"fontFlags"} & ~4;
    $self->calcSize();

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
    $self->{size}->{left}  *= $u;
    $self->{size}->{right} *= $u;
    $self->{size}->{up}    *= $v;
    $self->{size}->{down}  *= $v;

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

    my $position = ${$self}{"points"}[0];
    my $xmin = $position->[0] + $self->{size}->{left};
    my $xmax = $position->[0] + $self->{size}->{right};
    my $ymin = $position->[1] + $self->{size}->{up};
    my $ymax = $position->[1] + $self->{size}->{down};

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
    # Encode backslashes and bytes above 127 with backslash escapes.
    #
    for (my $i = 0; $i < length($text_in); ++$i) {
	my $c = substr($text_in, $i, 1);
	my $n = ord($c);
	die if $n < 0 || $n > 255;	# enforced in convertText
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
    my $width  = $self->{size}{right}  - $self->{size}{left};
    my $height = $self->{size}{down} - $self->{size}{up};
    printf $fh ("4 %d %d %d -1 %d %.0f %.4f %u %.0f %.0f %d %d %s\\001\n",
	   ${$self}{"justification"},
	   ${$self}{"penColor"},
	   ${$self}{"depth"},
	   ${$self}{"fontRef"}[1],
	   ${$self}{"fontSize"},
	   ${$self}{"rotation"},
	   ${$self}{"fontFlags"},
	   $height * $figPerInch,
	   $width  * $figPerInch,
	   ${$self}{"points"}[0][0] * $figPerInch,
	   ${$self}{"points"}[0][1] * $figPerInch,
	   $text_out);
}

1;
