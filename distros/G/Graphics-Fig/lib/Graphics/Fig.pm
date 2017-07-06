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
package Graphics::Fig;
our $VERSION = 'v1.0.3';

use strict;
use warnings;
use Carp;
use File::Temp qw/ tempfile /;
use Graphics::Fig::Color;
use Graphics::Fig::Matrix;
use Graphics::Fig::Parameters;
use Graphics::Fig::Arc;
use Graphics::Fig::Compound;
use Graphics::Fig::Ellipse;
use Graphics::Fig::Polyline;
use Graphics::Fig::Spline;
use Graphics::Fig::Text;

my $FIG2DEV = "fig2dev";

#
# Graphics::Fig::_figPerInch return fig units per inch
#   $parameters
#
sub _figPerInch {
    my $parameters = shift;
    my $unitSystem = ${$parameters}{"units"}[1];

    if ($unitSystem eq "Metric") {
	return 1143.0;	#  450 fig units/cm
    } else {
	return 1200.0;	# 1200 fig units/in
    }
}

#
# Graphics::Fig::convertEndAction
#   $fig:     Fig instance
#   $prefix:  error message prefix
#   $value:   end action
#   $context: parameter context
#
sub convertEndAction {
    my $fig     = shift;
    my $prefix  = shift;
    my $value   = shift;
    my $context = shift;

    if ($value eq "merge" || $value eq "group" || $value eq "discard") {
	return $value;
    }
    croak("${prefix}: ${value}: error: expected Landscape or Portrait");
}

#
# Global Parameters
#
my %GlobalParameterTemplate = (
    positional	=> {
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::PositionParameter,	# must be second
	 @Graphics::Fig::Parameters::ArrowParameters,
	\%Graphics::Fig::Parameters::CapStyleParameter,
	\%Graphics::Fig::Parameters::ColorParameter,
	\%Graphics::Fig::Parameters::CornerRadiusParameter,
	\%Graphics::Fig::Parameters::DepthParameter,
	\%Graphics::Fig::Parameters::DetachedLinetoParameter,
	 @Graphics::Fig::Parameters::ExportParameters,
	 @Graphics::Fig::Parameters::FillParameters,
	\%Graphics::Fig::Parameters::GridParameter,
	\%Graphics::Fig::Parameters::JoinStyleParameter,
	 @Graphics::Fig::Parameters::LineParameters,
	 @Graphics::Fig::Parameters::SaveParameters,
	\%Graphics::Fig::Parameters::SplineSubtypeParameter,
	 @Graphics::Fig::Parameters::TextParameters,
    ],
);

#
# Export Parameters
#
my %ExportParameterTemplate = (
    positional	=> {
	"."	=> [ "filename" ],
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::PositionParameter,	# must be second
	 @Graphics::Fig::Parameters::SaveParameters,
	{
	    name	=> "filename",
	},
	{
	    name	=> "exportFormat",	# duplicated for alias
	    aliases	=> [ "format" ],
	},
	{
	    name	=> "exportOptions",	# duplicated for alias
	    aliases	=> [ "options" ],
	    convert	=> \&Graphics::Fig::Parameters::convertExportOptions,
	},
    ],
);

#
# Move Parameters
#
my %MovetoParameterTemplate = (
    positional	=> {
	"@"  => [ "point" ],
	".." => [ "distance", "heading" ],
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::PositionParameter,	# must be second
	\%Graphics::Fig::Parameters::PointParameter,
	{
	    name		=> "distance",
	    convert		=> \&Graphics::Fig::Parameters::convertLength,
	},
	{
	    name		=> "heading",
	    convert		=> \&Graphics::Fig::Parameters::convertAngle,
	},
    ],
);

#
# Translate Parameters
#
my %TranslateParameterTemplate = (
    positional	=> {
	"@" => [ "offset" ],
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::OffsetParameter,
    ],
);

#
# Rotate Parameters
#
my %RotateParameterTemplate = (
    positional	=> {
	"." => [ "rotation" ],
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::PositionParameter,	# must be second
	\%Graphics::Fig::Parameters::CenterParameter,
	\%Graphics::Fig::Parameters::RotationParameter,
    ],
);

#
# Scale Parameters
#
my %ScaleParameterTemplate = (
    positional	=> {
	"." => [ "scale" ],
	"@" => [ "scale" ],
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::PositionParameter,	# must be second
	\%Graphics::Fig::Parameters::CenterParameter,
	\%Graphics::Fig::Parameters::ScaleParameter,
    ],
);

#
# End Parameters
#
my %EndParameterTemplate = (
    positional	=> {
	"."	=> [ "action" ],
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::PositionParameter,	# must be second
	\%Graphics::Fig::Parameters::GridParameter,
	{
	    name	=> "action",
	    convert	=> \&convertEndAction,
	    default	=> "merge",
	},
    ],
);

##
## Load Parameters
##
#my %LoadParameterTemplate = (
#    positional	=> {
#	"."	=> [ "filename" ],
#    },
#    named	=> [
#	{
#	    name	=> "filename",
#	},
#    ],
#);

#
# Save Parameters
#
my %SaveParameterTemplate = (
    positional	=> {
	"."	=> [ "filename" ],
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
	\%Graphics::Fig::Parameters::PositionParameter,	# must be second
	 @Graphics::Fig::Parameters::SaveParameters,
	{
	    name	=> "filename",
	},
    ],
);

#
# Get Position and Get Bounding Box Parameters
#
my %UnitsOnlyParameterTemplate = (
    positional	=> {
    },
    named	=> [
	\%Graphics::Fig::Parameters::UnitsParameter,	# must be first
    ],
);

#
# Graphics::Fig::new: constructor
#   $proto:   prototype
#   [ { option1=value1, option2=value2, ... } ]
#
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {
	colors	=> Graphics::Fig::Color->new(),
	stack	=> [
	    {
		options		=> { },
		objects		=> [ ],
		openLineto	=> undef,
		openSplineto	=> undef,
	    },
	],
    };
    bless($self, $class);
    $self->options({});

    #
    # Process global options.
    #
    my $stack = ${$self}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    eval {
	Graphics::Fig::Parameters::parse($self, "Graphics::Fig::new",
					 \%GlobalParameterTemplate,
					 undef, ${$tos}{"options"}, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    return $self;
}

#
# Graphics::Fig::options: change global options
#   $self:    class instance
#   [ { option1=value1, option2=value2, ... } ]
#
sub options {
    my $self = shift;
    my $stack = ${$self}{"stack"};
    my $tos   = ${$stack}[$#{$stack}];

    eval {
	Graphics::Fig::Parameters::parse($self, "options",
					 \%GlobalParameterTemplate,
					 ${$tos}{"options"},
					 ${$tos}{"options"}, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return 1;
}

#
# Graphics::Fig::moveto move to a new position
#   $self:    class instance
#   moveto options...
#
sub moveto {
    my $self = shift;
    my $stack = ${$self}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    my $options = ${$tos}{"options"};
    my %parameters;
    my $newPosition;

    eval {
	Graphics::Fig::Parameters::parse($self, "moveto",
					 \%MovetoParameterTemplate, $options,
					 \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    if (defined($parameters{"point"})) {
	if (defined($parameters{"distance"})) {
	    croak("moveto error: point and distance cannot be given together");
	}
	if (defined($parameters{"heading"})) {
	    croak("moveto error: point and heading cannot be given together");
	}
	$newPosition = $parameters{"point"};

    } elsif (defined(my $r = $parameters{"distance"})) {
	my $theta = $parameters{"heading"};
	if (!defined($theta)) {
	    croak("moveto error: expected point, or distance and heading");
	}
	$newPosition = [ $parameters{"position"}[0] + $r * cos($theta),
			 $parameters{"position"}[1] - $r * sin($theta) ];

    } elsif (defined($parameters{"position"})) {
	$newPosition = $parameters{"position"};

    } else {
	croak("moveto error: point and distance cannot be given together");
    }
    ${$options}{"position"} = $newPosition;

    return 1;
}

#
# Graphics::Fig::getposition: return the current position
#   $self:    class instance
#
sub getposition {
    my $self = shift;
    my $stack = ${$self}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    my $options = ${$tos}{"options"};
    my %parameters;
    my $position;
    my $scale;

    eval {
	Graphics::Fig::Parameters::parse($self, "getposition",
		\%UnitsOnlyParameterTemplate, $options, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    $scale    = $parameters{"units"}[0];
    $position = ${$options}{"position"};
    return [ ${$position}[0] / $scale, ${$position}[1] / $scale ];
}

#
# Graphics::Fig::begin: begin a sub-environment
#   $self:    class instance
#   [ { } ]
#
sub begin {
    my $self = shift;
    my $stack = ${$self}{"stack"};
    my $tos = ${$stack}[$#{$stack}];
    my %parameters;

    eval {
	Graphics::Fig::Parameters::parse($self, "begin",
					 \%GlobalParameterTemplate,
					 ${$tos}{"options"},
					 \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    push(@{$stack}, {
	options		=> \%parameters,
	objects		=> [ ],
	openLineto	=> undef,
	openSplineto	=> undef,
    });

    return 1;
}

#
# Graphics::Fig::end: end a sub-environment
#   $self:    class instance
#   [ [ action ] { action={merge|group|discard} }
#
sub end {
    my $self = shift;
    my %parameters;

    my $stack  = ${$self}{"stack"};
    my $oldTos = pop(@{$stack});
    my $tos = ${$stack}[$#{$stack}];


    eval {
	Graphics::Fig::Parameters::parse($self, "end", \%EndParameterTemplate,
					 ${$tos}{"options"}, \%parameters,
					 @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    if ($parameters{"action"} eq "merge") {
	push(@{${$tos}{"objects"}}, @{${$oldTos}{"objects"}});

    } elsif ($parameters{"action"} eq "group") {
	my $objects = ${$oldTos}{"objects"};
	Graphics::Fig::Compound->new($self, $objects, \%parameters);
    }
    return 1;
}

#
# Graphics::Fig::arc draw an arc
#   $self:    class instance
#   arc parameters...
#
sub arc {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Arc->arc($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::arc draw an arc
#   $self:    class instance
#   arc parameters...
#
sub arcto {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Arc->arcto($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::circle: draw a circle
#   $self:    class instance
#   circle parameters...
#
sub circle {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Ellipse->circle($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::ellipse: draw an ellipse
#   $self:    class instance
#   ellipse parameters...
#
sub ellipse {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Ellipse->ellipse($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::polyline: draw a polyline object
#   $self:    class instance
#   polyline parameters...
#
sub polyline {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Polyline->polyline($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::lineto: draw a line from position to the given point(s)
#   $self:    class instance
#   polyline parameters...
#
sub lineto {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Polyline->lineto($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::box draw a box object
#   $self:    class instance
#   box parameters...
#
sub box {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Polyline->box($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::polygon draw a polygon object
#   $self:    class instance
#   polygon parameters...
#
sub polygon {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Polyline->polygon($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::picture embed a picture
#   $self:    class instance
#   picture parameters...
#
sub picture {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Polyline->picture($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::spline: draw a spline
#   $self:    class instance
#   picture parameters...
#
sub spline {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Spline->spline($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::splineto: draw a spline from current point
#   $self:    class instance
#   picture parameters...
#
sub splineto {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Spline->splineto($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::text add text
#   $self:    class instance
#   text parameters...
#
sub text {
    my $self = shift;
    my $obj = eval {
	return Graphics::Fig::Text->text($self, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    return $obj;
}

#
# Graphics::Fig::translate: translate all objects
#   $self:    class instance
#   translate parameters...
#
sub translate {
    my $self = shift;

    my $stack = ${$self}{"stack"};
    my $tos   = ${$stack}[$#{$stack}];
    my %parameters;
    eval {
	Graphics::Fig::Parameters::parse($self, "translate",
					 \%TranslateParameterTemplate,
					 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    foreach my $object (@{${$tos}{"objects"}}) {
	$object->translate(\%parameters);
    }
}

#
# Graphics::Fig::rotate: rotate all objects
#   $self:    class instance
#   rotate parameters...
#
sub rotate {
    my $self = shift;

    my $stack = ${$self}{"stack"};
    my $tos   = ${$stack}[$#{$stack}];
    my %parameters;
    eval {
	Graphics::Fig::Parameters::parse($self, "translate",
					 \%RotateParameterTemplate,
					 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    foreach my $object (@{${$tos}{"objects"}}) {
	$object->rotate(\%parameters);
    }
}

#
# Graphics::Fig::scale: scale all objects
#   $self:    class instance
#   scale parameters...
#
sub scale {
    my $self = shift;

    my $stack = ${$self}{"stack"};
    my $tos   = ${$stack}[$#{$stack}];
    my %parameters;
    eval {
	Graphics::Fig::Parameters::parse($self, "translate",
					 \%ScaleParameterTemplate,
					 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    foreach my $object (@{${$tos}{"objects"}}) {
	$object->scale(\%parameters);
    }
}

#
# Graphics::Fig::getbbox return the bounding box of all objects
#   $self:    class instance
#   bbox parameters...
#
sub getbbox {
    my $self = shift;

    my $stack = ${$self}{"stack"};
    my $tos   = ${$stack}[$#{$stack}];
    my $options = ${$tos}{"options"};
    my %parameters;
    my $scale;
    my ($x_min, $y_min, $x_max, $y_max);
    eval {
	Graphics::Fig::Parameters::parse($self, "getbbox",
		\%UnitsOnlyParameterTemplate, $options, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }
    foreach my $object (@{${$tos}{"objects"}}) {
	my $bbox = $object->getbbox(\%parameters);
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
    $scale = $parameters{"units"}[0];
    return [ [ $x_min / $scale, $y_min / $scale ],
             [ $x_max / $scale, $y_max / $scale ] ];
}

# TODO: Implement load.
#
# Load would allow you to incorporate existing figures, manipulate
# them using translate, rotate and scale, form groups around them
# and superimpose new objects over them.
#
# Notes:
# - Some older formats should be accepted.  Documented versions are: 1.3, 1.4,
#   1.5 1.6, 2.0, 2.1, 3.0, 3.1 and 3.2.  Version 1.4 was the first to have a
#   #FIG line.  Versions 1.5 and 1.6 seem to have been a dead-end side
#   development path.
#
#   These are the preambles to a few formats:
#
#   1.3:
#     [no #FIG line]
#     resolution in pixels per inch
#     origin: 2
#     canvas width (pixels)
#     canvas height (pixels)
#
#   1.4:
#     #FIG line was added in this version
#     resolution
#     coordinate_system: 2
#
#   2.0:
#     resolution
#     coordinate_system: 2
#
#   3.1:
#     resolution: 1200
#     orientation: Landscape or Portrait
#     justification: Center or Flush Left
#     units: Metric or Inches
#     coordinate_system: 2
#
#   3.2:
#     orientation: Landscape or Portrait
#     justification: Center or Flush Left
#     units: Metric or Inches
#     papersize: Letter Legal Ledger Tabloid A B C D E A4 A3 A2 A1 A0 B5
#     magnification: <float (in percent)>
#     multiple-page: Single or Multiple
#     transparent color: <int>
#     resolution coordinate_system: 1200 2
#
# - One approach would be to load the file into the current drawing
#   environment, mapping any new custom colors to new values.  Another approach
#   would be to construct a new Graphics::Fig object and provide a "merge"
#   function that merges one Fig object into another.  The later has the
#   benefit of providing merge, which may be useful in itself.  Like load,
#   merge also has to reassign color map entries.
#
## Graphics::Fig::load: load a .fig file into the current drawing environment
##   $self:    class instance
##   load parameters...
##
#sub load {
#    my $self = shift;
#
#    my $stack = ${$self}{"stack"};
#    my $tos   = ${$stack}[$#{$stack}];
#    my %parameters;
#    eval {
#	Graphics::Fig::Parameters::parse($self, "load", \%LoadParameterTemplate,
#					 ${$tos}{"options"}, \%parameters, @_);
#    };
#    if ($@) {
#	$@ =~ s/ at [^\s]* line \d+\.\n//;
#	croak("$@");
#    }
#
#    my $filename = $parameters{"filename"};
#    if (!defined($filename)) {
#	croak("load: error: expected filename");
#    }
#    my $fh;
#    open($fh, "<", $filename) || croak("save: $filename: $!");
#
#    if (!<$fh>) {
#	close($fh):
#	croak("load: error: can't read header line");
#    }
#    if (!/^#FIG (.*)/) {
#	close($fh):
#	croak("load: error: exepected FIG file format");
#    }
#
#    HERE
#
#    close($fh);
#}

#
# Graphics::Fig::_saveCommon: common code for save and export
#   $self:       class instance
#   $tos:        top of drawing stack
#   $parameters: reference to parameter hash
#   $fh:         open filehandle to the output file
#
sub _saveCommon {
    my $self       = shift;
    my $tos	   = shift;
    my $parameters = shift;
    my $fh	   = shift;

    my $figPerInch = _figPerInch($parameters);
    my $comment = ${$parameters}{"comment"};
    if ($comment ne "") {
	$comment =~ s/^/# /gm;
	if (!($comment =~ m/\n$/)) {
	    $comment .= "\n";
	}
    }
    printf $fh ("#FIG 3.2  Produced by Graphics::Fig\n");
    printf $fh ("%s\n", ${$parameters}{"orientation"});
    printf $fh ("%s\n", ${$parameters}{"pageJustification"});
    printf $fh ("%s\n", ${$parameters}{"units"}[1]);
    printf $fh ("%s\n", ${$parameters}{"paperSize"});
    printf $fh ("%.2f\n", ${$parameters}{"magnification"});
    printf $fh ("%s\n", ${$parameters}{"multiplePage"});
    printf $fh ("%d\n", ${$parameters}{"transparentColor"});
    if ($comment ne "") {
	printf $fh ("%s", $comment);
    }
    #
    # In the imperial unit system, 1200 is the number of fig units per
    # inch.  In metric, it's the number of fig units in 400/381 inches.
    # In other words, 1200 means 450 fig units per cm or exactly 1143
    # fig units per inch.
    #
    printf $fh ("1200 2\n");

    #
    # Add custom colors.
    #
    my $customHex = $self->{"colors"}->{"customHex"};
    for (my $i = 0; $i < scalar(@{$customHex}); ++$i) {
	printf $fh ("0 %d %s\n", 32 + $i, ${$customHex}[$i]);
    }

    #
    # Add objects.
    #
    foreach my $object (@{${$tos}{"objects"}}) {
	$object->print($fh, $parameters);
    }
}

#
# Graphics::Fig::save: save the .fig file
#   $self:    class instance
#   save parameters...
#
sub save {
    my $self = shift;

    my $stack = ${$self}{"stack"};
    my $tos   = ${$stack}[$#{$stack}];
    my %parameters;
    eval {
	Graphics::Fig::Parameters::parse($self, "save", \%SaveParameterTemplate,
					 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    my $filename = $parameters{"filename"};
    if (!defined($filename)) {
	croak("save: error: expected filename");
    }
    open(my $fh, ">", $filename) || croak("save: $filename: $!");
    &_saveCommon($self, $tos, \%parameters, $fh);
    close($fh);
}


#
# Graphics::Fig::export: export the drawing to the given format
#   $self:    class instance
#   save parameters...
#
sub export {
    my $self = shift;

    my $stack = ${$self}{"stack"};
    my $tos   = ${$stack}[$#{$stack}];
    my %parameters;
    eval {
	Graphics::Fig::Parameters::parse($self, "export",
					 \%ExportParameterTemplate,
					 ${$tos}{"options"}, \%parameters, @_);
    };
    if ($@) {
	$@ =~ s/ at [^\s]* line \d+\.\n//;
	croak("$@");
    }

    #
    # Validate parameters.  Determine the output format either from the
    # type argument or the filename extension.
    #
    my $outputFilename = $parameters{"filename"};
    if (!defined($outputFilename)) {
	croak("export: error: expected filename");
    }
    my $type;
    if (defined($parameters{"type"})) {
	$type = $parameters{"type"};
    } elsif ($outputFilename =~ m/\.([^.]+)$/) {
	$type = $1;
    } else {
	croak("export: error: cannot determine output file type");
    }

    #
    # Save the drawing to a temporary file.
    #
    my ($fh, $tempFilename) = tempfile();
    &_saveCommon($self, $tos, \%parameters, $fh);
    close($fh);

    #
    # Build the argument list and run fig2dev.
    #
    my @Args = ($FIG2DEV, "-L", $type);
    if (defined($parameters{"options"})) {
	push(@Args, @{$parameters{"options"}});
    }
    push(@Args, $tempFilename, $outputFilename);
    if ((system @Args) != 0) {
	croak("export: error: $!\n");
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Graphics::Fig - xfig library

=head1 SYNOPSYS

=head2 Objects

B<arc(>I<radius>B<,> I<angle>B<)>

B<arc(>I<points>B<)>

B<< arc({ center => [ >> I<xc>B<,> I<yc> B<< ], r => >> I<length>B<< , angle => >> I<angle>B<< , rotation => >> I<rotation>, ... B<})>

B<< arc({ center => [ >> I<xc>B<,> I<yc> B<< ], d => >> I<length>B<< , angle => >> I<angle>B<< , rotation => >> I<rotation>, ... B<})>

B<< arc({ center => [ >> I<xc>B<,> I<yc> B<< ], point => [ >> I<x1>B<,> I<y1> B<< ], angle => >> I<angle>B<,> ... B<})>

B<< arc({ points => [[ >> I<x1>B<,> I<y1> B<], [> I<x3>B<,> I<y3> B<< ]], angle => >> I<angle>B<,> ... B<})>

B<< arc({ points => [[ >> I<x1>B<,> I<y1> B<], [> I<x2>B<,> I<y2> B<], [> I<x3>B<,> I<y3> B<]],> ... B<})>

B<arcto(>I<distance>B<,> I<heading>B<,> I<angle>B<)>

B<arcto(>I<points>B<)>

B<< arcto({ center => [ >> I<xc>B<,> I<yc> B<< ], angle => >> I<angle>B<,> ... B<})>

B<< arcto({ point => [ >> I<x3>B<,> I<y3> B<< ], angle => >> I<angle>B<,> ... B<})>

B<< arcto({ points => [[ >> I<x2>B<,> I<y2> B<], [> I<x3>B<,> I<y3> B<]],> ... B<})>

B<box(>I<width>B<,> I<height>B<)>

B<box(>I<points>B<)>

B<< box({ center => [ >> I<xc>B<,> I<yc> B<< ], width => >> I<width>B<< , height => >> I<height>B<,> ... B<})>

B<< box({ points => [[ >> I<x1>B<,> I<y1> B<], [> I<x2>B<,> I<y2> B<]],> ... B<})>

B<circle(>I<d>B<)>

B<circle(>I<points>B<)>

B<< circle({ center => [ >> I<xc>B<,> I<yc> B<< ], d => >> I<length>B<,> ... B<})>

B<< circle({ center => [ >> I<xc>B<,> I<yc> B<< ], r => >> I<length>B<,> ... B<})>

B<< circle({ center => [ >> I<xc>B<,> I<yc> B<< ], point => [ >> I<x>B<,> I<y> B<],> ... B<})>

B<< circle({ points => [[ >> I<x1>B<,> I<y1> B<], [> I<x2>B<,> I<y2> B<], [> I<x3>B<,> I<y3> B<]],> ... B<})>

B<ellipse(>I<a>B<,> I<b>B<)>

B<ellipse(>I<a>B<,> I<b>B<,> I<rotation>B<)>

B<ellipse(>I<points>B<)>

B<< ellipse({ center => [ >> I<xc>B<,> I<yc> B<< ], points => [[ >> I<x1>B<,> I<y1> B<], [> I<x2>B<,> I<y2> B<]],> B<< rotation => >> I<rotation>B<,> ... B<})>

B<< ellipse({ center => [ >> I<xc>B<,> I<yc> B<< ], points => [[ >> I<x1>B<,> I<y1> B<], [> I<x2>B<,> I<y2> B<], [> I<x3>B<,> I<y3> B<]],> ... })>

B<< ellipse({ points => [[ >> I<x1>B<,> I<y1> B<], [> I<x2>B<,> I<y2> B<], [> I<x3>B<,> I<y3> B<], [> I<x4>B<,> I<y4> B<], [> I<x5>B<,> I<y5> B<]],> ... })>

B<lineto(>I<distance>B<,> I<heading>B<)>

B<lineto(>I<points>B<)>

B<< lineto({ distance => >> I<length>B<< , heading => >> I<heading>B<,> ... B<})>

B<< lineto({ point => [ >> I<x2>B<,> I<y2> B<],> ... B<})>

B<< lineto({ points => [[ >> I<x2>B<,> I<y2> B<], [> I<x3>B<,> I<y3> B<],> ... B<],> ... B<})>

B<picture(>I<filename>B<)>

B<picture(>I<filename>B<,> I<width>B<)>

B<picture(>I<filename>B<,> I<width>B<,> I<height>B<)>

B<picture(>I<filename>B<,> I<points>B<)>

B<< picture({ filename => >> I<filename>B<< , width => >> I<width>B<< , height => >> I<height>B<,> ... B<})>

B<< picture({ filename => >> I<filename>B<< , points => [[ >> I<x1>B<,> I<y1> B<], [> I<x2>B<,> I<y2> B<]],> ... B<})>

B<polygon(>I<n>B<,> I<radius>B<)>

B<polygon(>I<points>B<)>

B<< polygon({ center => [ >> I<xc>B<,> I<yc> B<< ], r => >> I<length>B<< , rotation => >> I<rotation>B<< , n => >> I<n-sides>B<,> ... B<})>

B<< polygon({ center => [ >> I<xc>B<,> I<yc> B<< ], point => [ >> I<x1>B<,> I<y1> B<< ], n => >> I<n-sides>B<,> ... B<})>

B<< polygon({ points => [[ >> I<x1>B<,> I<y2> B<], [> I<x2>B<,> I<y2> B<], [> I<x3>B<,> I<y3> B<],> ... B<], > ... B<})>

B<polyline(>I<points>B<)>

B<< polyline({ points => [[ >> I<x1>B<,> I<y1> B<], [> I<x2>B<,> I<y2> B<],> ... B<],> ... B<})>

B<spline(>I<points>B<)>

B<< spline({ points => [[ >> I<x1>B<,> I<y2> B<], [> I<x2>B<,> I<y2> B<], [> I<x3>B<,> I<y3> B<],> ... B<],> ... B<})>

B<splineto(>I<distance>B<,> I<heading>B<)>

B<splineto(>I<points>B<)>

B<< splineto(distance => >> I<length>B<< , heading => >> I<heading>B<,> ... B<})>

B<< splineto(points => [[ >> I<x2>B<,> I<y2> B<], [> I<x3>B<,> I<y3> B<],> ... B<],> ... B<})>

B<text(>I<text>B<)>

=head2 Control

B<new({> I<global-parameters>... B<})>

B<options({> I<global-parameters>... B<})>

B<begin({> I<global-parameters>... B<})>

B<end(>I<action>B<)>

B<< end({ action => "merge" >> | B<"group"> | B<"discard",> ... B<}) >

B<moveto(>I<distance>, I<heading>B<)>

B<moveto(>I<point>B<)>

B<< moveto({ distance => >> I<length>B<< , heading => >> I<heading>B<,> ... B<})>

B<< moveto({ point => [ >> I<x>B<,> I<y>B< ],> ... B<})>

B<getposition()>

B<translate(>I<offset>B<)>

B<< translate({ offset => [ >> I<dx>B<,> I<dy> B<],> ... B<})>

B<rotate(>I<rotation>B<)>

B<< rotate({ rotation => >> I<rotation>B<,> ... B<})>

B<scale(>I<scale>B<)>

B<< scale({ scale => >> I<scale><,> ... B<})>

B<< scale({ scale => [ >> I<x-scale>B<,> I<y-scale> B<],> ... B<})>

B<getbbox()>

B<save(>I<filename>B<)>

B<< save({ filename => >> I<filename>B<,> ... B<})>

B<export(>I<filename>B<)>

B<< export({ filename => >> I<filename>B<,> ... B<})>

=head1 DESCRIPTION

Graphics::Fig is a drawing library that produces xfig save files.
This version is based on xfig v3.2.

=head2 Simple Example

    my $fig = Graphics::Fig->new();
    $fig->moveto([ 1, 1 ]);
    $fig->lineto([ 4, 1 ]);
    $fig->lineto([ 4, 3 ]);
    $fig->lineto([ 1, 3 ]);
    $fig->lineto([ 1, 1 ]);
    $fig->export("example.pdf");

The first line of the example creates a Fig object and establishes a
drawing environment.  The moveto command moves the starting position to
[ 1, 1 ].  The next four lines draw a rectangle from the starting
position.  The final line exports the drawing to pdf format.

=head2 Parameter Passing

All functions in the library accept named parameters.  If the last
parameter is a reference to a hash, the hash is interpeted as a set of
parameter name / value pairs.  In addition, most functions also accept
a few positional parameters.  For example:

    $fig->lineto([ 3, 2 ]);				# positional

is equivalent to:

    $fig->lineto({ point => [ 3, 2 ] });		# named

You may mix both positional and named parameters in the same function.
For example:

    $fig->lineto([ 3, 2 ], { color => "red" });		# mixed

is equivalent to:

    $fig->lineto({ point => [ 3, 2 ], color => "red" });

This function draws a line segment from the current position to
point [ 3, 2 ] using a pen color of red.

Many parameters take default values from the current drawing environment.
See I<Global Parameters>.

=head2 Functions

=for comment ------------------------ new -------------------------------------

=over

=item B<new()>

=item B<new({> I<global-parameters>... B<})>

The B<new> function constructs a new Fig object and establishes the
initial drawing environment.  All other functions in the library are
methods of the Fig object, thus this function must be called first.

The B<new> function accepts an optional list of global parameters that
set defaults for other functions (see I<Global Parameters> below).

=for comment ------------------------ arc -------------------------------------

=item B<arc>(I<radius>)

=item B<arc>(I<radius>, I<angle>)

=item B<arc>(I<points>)

The B<arc> function draws an arc from a starting point, through a
control point, to a final point.  The arc can be specified in any of
the following ways:

=over

=item center, radius|diameter, angle|Θ, rotation, [controlAngle]

Center and either radius or diameter give the location and size of the
associated circle.  Angle (alternatively Θ) is the central angle of the
arc.  Rotation is the angle of the starting point relative to the x-axis.

An optional controlAngle parameter places the control point.  If not
given, the control point is placed at the midpoint along the arc.

The direction of the arc (clockwise or counterclockwise) is inferred
from the sign of I<angle> or can be set explicitly using B<direction>.
See parameters below.

=item center, starting point, angle, [controlAngle]

The starting point can be given instead of radius and rotation.

=item starting point, final point, angle, [controlAngle]

The starting point and final point can be given instead of center,
radius and rotation.

=item starting point, control point, final point

Starting point, control point and final point uniquely describe the arc.

=back

B<Parameters>

=over

=item B<angle>|B<Θ> (degrees, default 90)

Angle is the central angle of the arc, i.e. the angle formed by starting
point, center and final point.

=item B<center> = I<point> (default: current position)

Center is the origin of the associated circle.  If not given, center
defaults to the current position.

=item B<controlAngle> (degrees, default angle/2)

Control angle is the angle between the starting point and middle point
of the arc.  The control point appears as a movable point in xfig.
If not given, control angle defaults to B<angle> divided by two.

=item B<diameter>|B<d> = I<length>

Diameter is the diameter of the associated circle.  See B<radius>.

=item B<direction> = "clockwise"|"cw" or "counterclockwise"|"ccw"

Direction specifies whether the arc is drawn counterclockwise or
clockwise from the starting point to the final point.  If not given,
the direction is inferred from the sign of I<angle>, counterclockwise
if angle is positive and clockwise if angle is negative.  This parameter
is particularly useful when using the arrow modes.

=item B<points> = I<points>

Points specifies one, two or three points along the arc: start, start
and final, or start, control and final.

=item B<radius>|B<r> = I<length>

Radius describes the radius of the associated circle.  See B<diameter>.

=item B<rotation> (degrees)

Rotation is the angle in degrees from the center to the first point
relative to the x axis.  If neither rotation nor points is given,
rotation defaults to zero.

=item B<subtype> = "B<open>" (default) | "B<closed>"

Subtype selects between a simple arc (open) or a pie wedge, (closed).
Closed can alternatively be specified as "pie" or "pie-wedge".

=item B<areaFill> = I<areaFill>

=item B<arrowHeight> = I<length>

=item B<arrowMode> = "none" | "forw[ard]" | "back[ward]" | "both"

=item B<arrowStyle>

=item B<arrowThickness> = I<length>

=item B<arrowWidth> = I<length>

=item B<capStyle> = "butt" | "round" | "projecting"

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ----------------------- arcto ------------------------------------

=item B<arcto>(I<distance>, I<heading>)

=item B<arcto>(I<distance>, I<heading>, I<angle>)

=item B<arcto>(I<points>)

The B<arcto> function draws an arc from the current position, through a
control point, to a final point then moves the current position to the
final point.  Arcto can be specified in any of the following ways:

=over

=item distance, heading, angle, [controlAngle]

Distance and heading describe the final point relative to the current
point, where distance is in the current unit and heading is in degrees,
with zero aligned on the x-axis.  Angle is the central angle of the arc.

The optional controlAngle places the control point.  See B<arc>.

Use a positive angle for a counterclockwise arc, a negative angle for a
clockwise arc, or specify the direction explicitly using the B<direction>
parameter.

=item center, angle, [controlAngle]

The final point can be calculated from the center of the associated
circle and central angle of the arc.

=item final point, angle, [controlAngle]

The final point can be given directly.

=item control point, final point

Control point and final point uniquely describe the arc.

=back

B<Parameters>

=over

=item B<angle>|B<Θ> (degrees, default 90)

Angle is the central angle of the arc, i.e. the angle formed by starting
point, center and final point.  Angle can alternatively be written as Θ.

=item B<center> = I<point>

Center is the origin of the associated circle.

=item B<controlAngle> (degrees, default angle/2)

Control angle is the angle between the starting point and middle point
of the arc.  This control point appears as a movable point in xfig.
If not given, control angle defaults to I<angle> divided by two.

=item B<direction> = "clockwise"|"cw" or "counterclockwise"|"ccw"

Direction specifies whether the arc is drawn counterclockwise or
clockwise from the starting point to the final point.  If not given,
the direction is inferred from the sign of I<angle>, counterclockwise
if angle is positive and clockwise if angle is negative.  This parameter
is particularly useful when using the arrow modes.

=item B<distance> = I<length>

Distance is the straight-line distance from the current position to the
final point.

=item B<heading> (degrees)

Heading is the angle in degrees of the final point relative to the
current position.

=item B<points> = I<points>

Points specifies one or two points along the arc: final, or control
and final.

=item B<subtype> = "B<open>" (default) | "B<closed>"

Selects between a simple arc (open) or a pie wedge, (closed).
Closed can alternatively be specified as "pie" or "pie-wedge".

=item B<areaFill> = I<areaFill>

=item B<arrowHeight> = I<length>

=item B<arrowMode> = "none" | "forw[ard]" | "back[ward]" | "both"

=item B<arrowStyle>

=item B<arrowThickness> = I<length>

=item B<arrowWidth> = I<length>

=item B<capStyle> = "butt" | "round" | "projecting"

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ----------------------- begin ------------------------------------

=item B<begin>({ I<global-parameters> })

The B<begin> function pushes a new empty drawing context with given
global parameters.  Any parameters not specified default to the values
in the parent drawing context.  See B<end>.

Drawing contexts are useful for drawing a series of objects with shared
default parameters and for creating groups.

=for comment ----------------------- end --------------------------------------

=item B<end>()

=item B<end>(I<action>)

The B<end> function leaves a drawing context started by a matching
B<begin>.  Based on the given action, objects created within the
sub-context are either merged into the parent context, grouped and added
to the parent context or discarded.  The default action is "merge".

B<Parameters>

=over

=item B<action> = B<merge> | B<group> | B<discard>

An action of B<merge> (default) merges all objects created in the
sub-environment into the parent environment.  An action of B<group> groups
the objects and adds the group to the parent environment.  An action
of B<discard> discards all objects created in the sub-environment.
The discard option can be useful if you called B<save> while in the
sub-environment.

=item B<grid> = length

When creating a group, this option expands the corners of the group as
needed to snap to a grid of given resolution.  If not given, the corners
of the group are defined by the bounding box of the contained objects.

=item B<position> = I<point>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ----------------------- box --------------------------------------

=item B<box>(I<width>, I<height>)

=item B<box>(I<points>)

The B<box> function draws a rectangular box specified by either of:

=over

=item center, width, height

Center is the central point of the box.  Width and height are the
dimensions of the box.  If not given, center defaults to the current
position.

=item two points

Two opposite corners describe a box.

=back

B<Parameters>

=over

=item B<center> = I<point> (default: current position)

Center is the central point of the box.  If not given, center defaults
to the current position.

=item B<height> = I<length>

Height is the vertical dimension of the box.

=item B<width> = I<length>

Width is the horizontal dimension of the box.

=item B<points>

Two points give the locations of a pair of opposite corners of the box.

=item B<areaFill> = I<areaFill>

=item B<color> = I<color>

=item B<cornerRadius> = I<length>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- circle ------------------------------------

=item B<circle>(I<diameter>)

=item B<circle>(I<points>)

The B<circle> function draws a circle described by any of the following:

=over

=item center, radius|diameter

Center is the origin point of the circle.  Radius or alternatively,
diameter is the size of the circle.  If not given, center defaults
to the current position.

=item center, starting point

Center and a point on the circle can be given instead of radius or
diameter.  If not given, center defaults to the current position.

=item first point, second point, third point

Any three non-collinear points uniquely describe a circle.

=back

B<Parameters>

=over

=item B<center> = I<point> (default: current position)

Center is the origin of the circle.  If not given, center defaults to
the current position.

=item B<diameter>|B<d>

Diameter is the diameter of the circle.  See B<radius>.

=item B<point>|B<points>

Points specifies one or three points on the circle: the starting point,
or any three non-colinear points.

=item B<radius>|B<r>

Radius describes the radius of the circle.  See B<diameter>.

=item B<rotation> (degrees)

Rotation is the angle from center to the starting point relative to
the x-axis.  The starting point appears as a movable point in xfig.

=item B<subtype> = B<"radius"> | B<"diameter">

Subtype determines whether xfig describes the circle by center and one
control point on the circle (radius), or or by two control points on
opposite sides of the circle (diameter).  If not given, the subtype is
automatically inferred from the other parameters.

=item B<areaFill> = I<areaFill>

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- ellipse -----------------------------------

=item B<ellipse>(I<a>, I<b>)

=item B<ellipse>(I<a>, I<b>, I<rotation>)

=item B<ellipse>(I<points>)

The B<ellipse> function draws an ellipse specified in any of the
following ways:

=over

=item center, a, b, rotation

Center, a and b give the origin of the ellipse and the lengths of the
two semi axes.  Rotation is the angle between the first semi axis and
the x axis.  If center is not given, it defaults to the current position.

=item center, two points, rotation

Any two points on the ellipse not colinear with the center can be given
instead of the semi axes.  If center is not given, center defaults to
the current position.  If rotation is not given, it defaults to the
angle of the first point.

=item center, three points

Center and any three points on the ellipse not colinear with the center
or with each other can be given instead of rotation.  If center is not
given, it defaults to the current position.

=item five points

Any five non-colinear points uniquely describe the ellipse.

=back

B<Parameters>

=over

=item B<a> = I<length>, B<b> = I<length>

The B<a> and B<b> parameters give the lenghts of the two semi axes.
While B<a> is normally the major semi axis, it's not an error for it
to be smaller than B<b>.

=item B<center> = I<point> (default: current position)

Center is the origin of the ellipse.  If center is not given, it defaults
to the current position.

=item B<points> = I<points>

Points describes two, three or five non-colinear points along the ellipse.

=item B<rotation> (degrees)

Rotation is the angle of the first axis of the ellipse relative the
x axis.

Rotation is the angle from center to the starting point relative to
the x-axis.  The starting point appears as a movable point in xfig.

=item B<subtype> = B<"radii"> | B<"diameters">

Subtype determines whether xfig describes the ellipse by center and the
control points of the two semi axes (radii), or by the four control
points of the full axes (diameters).  If not given, the subtype is
automatically inferred from other parameters.

=item B<areaFill> = I<areaFill>

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- export ------------------------------------

=item B<export>(I<filename>)

The B<export> function exports all objects in the current environment
to a given graphics format.

B<Parameters>

=over

=item B<exportFormat>|B<format>

Specify the output file format, overriding the output filename extension.
The list of supported formats depends on version and compile time options
of the I<fig2dev> program.  Typical supported graphics formats are: "box",
"cgm", "dxf" (AutoCAD drawing exchange format), "eepic", "eepicemu",
"emf", "epic", "eps", "gbx" (Gerber), "ge", "gif", "ibmgl", "jpeg",
"latex", "map" (HTML image map), "mf" (MetaFont), "mmp" (Multi-MetaPost),
"mp" (MetaPost), "pcx", "pdf", "pdftex", "pdftex_t", "pic", "pictex",
"png", "ppm", "ps", "pstex", "pstex_t", "pstricks", "ptk", "shape"
(LaTeX shaped paragraphs), "sld" (AutoCAD slide format), "svg", "textyl",
"tiff", "tk", "tpic", "xbm" and "xpm".

=item B<exportOptions>|B<options>

Provide additional command-line options to the I<fig2dev> program.
The value must be a reference to an array of strings.  Example:
B<[ "-f", "Roman" ]>.

=item B<filename>

Specify the filename of the output file.  If the B<exportFormat> option
is not given, the type is taken from the filename extension.

=item B<comment> = I<string>

=item B<pageJustification> = "Center" | "Flushleft"

=item B<magnification> = (float, percentage)

=item B<multiplePage> = "Single" | "Multiple"

=item B<orientation> = "Landscape" | "Portrait"

=item B<paperSize> = I<papersize>

=item B<position> = I<point>

=item B<transparentColor> = -2 | -1 | I<color>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- getbbox -----------------------------------

=item B<getbbox>()

The B<getbbox> function returns a reference to an array of two points
giving the bounding box for all objects in the current environment.
The return value is of the form [ [ x1, y1 ], [ x2, y2 ] ], where
[ x1, y1 ] is the top-left corner and [ x2, y2 ] is the bottom right corner.

B<Parameters>

=over

=item B<units> = I<units>

See Global Parameters.

=back

=for comment -------------------- getposition ---------------------------------

=item B<getposition>()

The B<getposition> function returns the current position in the current
unit.  The return value is a reference to an array of two scalars,
[ x, y ].  This array is a copy of the internal position and the caller may
modify the returned point without affecting the library.

B<Parameters>

=over

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- lineto ------------------------------------

=item B<lineto>(I<distance>, I<heading>)

=item B<lineto>(I<points>)

The B<lineto> function draws a line segment (or series of connected
segments) from the current position.  Then it moves the current position
to the end of the last segment.  This object can be given by either of
the following:

=over

=item distance, heading

Distance and heading describe the distance and angle of the next point
relative to the current point.

=item point|points

Given one or more points, the B<lineto> function draws a segment or
series of segments passing through each point.

=back

B<Parameters>

=over

=item B<distance> = I<length>

Distance is the straight-line distance from the current position to the
next point.

=item B<heading> (degrees)

Heading is the angle in degrees of the next point relative to the
current position.

=item B<new>|B<detachedLineto> = I<boolean>

By default, sequences of B<lineto> calls are merged into a single polyline
object when possible, i.e. when the position and other parameters are
unchanged since the previous call.  This behavior is more efficient
in terms of number of xfig objects created and it has the benefit of
honoring the B<joinStyle> parameter.  But when using the arrow modes,
it may not be desired because only the final segment receives an arrow.

If the B<new> parameter or global B<detachedLineto> parameter is true,
B<lineto> creates a new polyline object even if it could have merged
with the previous call.  This is useful when using arrow modes.

=item B<point>|B<points>

One or more points through which the segments should be drawn.

=item B<areaFill> = I<areaFill>

=item B<arrowHeight> = I<length>

=item B<arrowMode> = "none" | "forw[ard]" | "back[ward]" | "both"

=item B<arrowStyle>

=item B<arrowThickness> = I<length>

=item B<arrowWidth> = I<length>

=item B<capStyle> = "butt" | "round" | "projecting"

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<joinStyle> = "miter" | "round" | "bevel"

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- moveto ------------------------------------

=item B<moveto>(I<distance>, I<heading>)

=item B<moveto>(I<points>)

The B<moveto> function changes the current position.  There are two
styles:

=over

=item distance, heading

Distance and heading give the distance and angle of the destination
relative to the current position.

=item point

The new position is given as an absolute point.

=back

B<Parameters>

=over

=item B<distance> = I<length>

Distance is the distance from the current position to the target position.

=item B<heading> (degrees)

Heading is the angle in degrees of the target position relative to the
current position.

=item B<point> = I<point>

A single point sets the new absolute position.

=item B<position> = I<point>

The optional B<position> parameter is sets the current position *before*
the B<moveto> function changes it again.  When using B<distance> and
B<heading>, B<position> overrides the starting point; when using B<point>,
B<position> has no effect.

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- options -----------------------------------

=item B<options>({ I<global-parameters> })

The B<options> function sets default options for subsequent functions.
See I<Global Parameters>.

=for comment ---------------------- picture -----------------------------------

=item B<picture>(I<filename>)

=item B<picture>(I<filename>, I<width>)

=item B<picture>(I<filename>, I<width>, I<height>)

=item B<picture>(I<points>)

The B<picture> function inserts an embedded picture into the drawing.
There are several forms:

=over

=item filename, center

=item filename, center, width

=item filename, center, height

=item filename, center, width, height

Filename is the image to be inserted.  Center is the central point
of the picture.  If not given, center defaults to the current position.
If either width or height is given, the picture is scaled, preserving
aspect ratio, to fit the given dimension.  If both width and height are
given, the picture is scaled to fit both, modifying the aspect ratio
if needed.

=item filename, two opposite corners

Two points describing opposite corners may be given in place of center,
width and height.  The original top-left corner of the image is placed
at the first point; original bottom-right corner is placed the second
point.

=back

B<Parameters>

=over

=item B<center> = I<point> (default: current position)

Center is the central point of the picture.  If not given, center
defaults to the current position.

=item B<filename>

Filename is the name of the file containing the image.  The following
formats are accepted: eps, gif, jpeg, pcx, png, ppm, ps, tiff, xbm
and xpm.

=item B<height> = I<length>, B<width> = I<length>

Height scales the image vertically; width scales the image horizontally.

=item B<points> = I<points>

Two points are the locations of a pair of opposite corners of
the object.

=item B<resolution> = I<xres> [I<yres>] [B<dpi>|B<dpcm>|B<dpm>]

Resolution specifies the resolution of the image in dots per inch,
dots per centimeter or dots per meter.  You may describe non-square
pixels by specifying both xres and yres.  If not given, the B<picture>
function tries to automatically determine the resolution from the image.
If the resolution cannot be determined, it defaults to 100 dpi.

=item B<areaFill> = I<areaFill>

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<joinStyle> = "miter" | "round" | "bevel"

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- polygon -----------------------------------

=item B<polygon>(I<n>, I<radius>)

=item B<polygon>(I<points>)

The B<polygon> function draws a polygon described by any of the following:

=over

=item center, n, radius, rotation

This form draws an n-sided regular polygon.  Center is the central point
of the polygon.  If not given, center defaults to the current position.
Radius is the distance from center to each corner.  Rotation is the
angle from center to the first point relative to the x axis.

=item center, n, point

You may specify the first point instead of radius and rotation.

=item points

This form draws an arbitrary closed polygon passing through each point.

=back

B<Parameters>

=over

=item B<center> = I<point> (default: current position)

Center is the origin of a regular polygon.  If not given, center defaults
to the current position.

=item B<n>

N is the number of sides for a regular polygon.

=item B<point>|B<points>

One point specifies the location of the first corner of a regular polygon.
Three or more points specify the corners of an arbitrary polygon.

=item B<radius>|B<r>

Radius is the distance from the center to each corner of a regular
polygon.

=item B<rotation> (degrees)

Rotation is the angle from center to the first point of a regular polygon
relative to the x axis.

=item B<areaFill> = I<areaFill>

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<joinStyle> = "miter" | "round" | "bevel"

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- polyline ----------------------------------

=item B<polyline>(I<points>)

The B<polyline> function draws a sequence of interconnected line segments
passing through the given points.

B<Parameters>

=over

=item B<points> = I<points>

Two or more points specify the segments of the object.

=item B<areaFill> = I<areaFill>

=item B<arrowHeight> = I<length>

=item B<arrowMode> = "none" | "forw[ard]" | "back[ward]" | "both"

=item B<arrowStyle>

=item B<arrowThickness> = I<length>

=item B<arrowWidth> = I<length>

=item B<capStyle> = "butt" | "round" | "projecting"

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<joinStyle> = "miter" | "round" | "bevel"

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- rotate ------------------------------------

=item B<rotate>(I<angle>) (degrees)

The B<rotate> function rotates all objects in the current drawing context
about the given center by the given angle.

B<Parameters>

=over

=item B<center> = I<point>

Center is the point about which the objects are rotated.  If not given,
center defaults to the current position.

=item B<rotation> (degrees)

Rotation is the number of degrees to rotate the objects.  A positive
rotation is counterclockwise; a negative rotation is clockwise.

=item B<position> = I<point>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ----------------------- save -------------------------------------

=item B<save>(I<filename>)

The B<save> function saves all objects in the current environment to a
file in xfig (.fig) format.

B<Parameters>

=over

=item B<filename>

Give the filename of the save file.  The caller should include the .fig
suffix as it is not added automatically.

=item B<comment> = I<string>

=item B<pageJustification> = "Center" | "Flushleft"

=item B<magnification> = (float, percentage)

=item B<multiplePage> = "Single" | "Multiple"

=item B<orientation> = "Landscape" | "Portrait"

=item B<paperSize> = I<papersize>

=item B<position> = I<point>

=item B<transparentColor> = -2 | -1 | I<color>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ----------------------- scale ------------------------------------

=item B<scale>(I<scale>)

The B<scale> function scales all objects relative to the given center
or current position.

B<Parameters>

=over

=item B<center>

Center is the point about which all objects are scaled.  If not given,
center defaults to the current position.

=item B<scale> = I<s> | [ I<u>, I<v> ]

Scale is the factor by which objects are scaled.  The argument may be
either a single value to scale with constant aspect ratio, or a reference
to an array of two values to scale x and y with different ratios.
In some cases, changing the aspect ratio changes the object type.
For example, circles become ellipses.

Note that when changing aspect ration, not all objects can be scaled
linearly.  For example, when changing the aspect ratio of an B<arc>
object, the three control points are scaled as specified, but the object
remains an arc, i.e. xfig does not have a representation for a section
an an ellipse.

=item B<position> = I<point>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ---------------------- spline ------------------------------------

=item B<spline>(I<points>)

The B<spline> function draws a spline described by three or more control
points.

B<Parameters>

=over

=item B<points>

Three or more points are the control points of the spline.

=item B<shapeFactor>|B<shapeFactors>

When drawing an x-spline (see B<subtype>), you must provide either a
single shape factor to be applied to all points, or a vector of shape
factors, one entry for each point, to control the smoothness of the curve
around the control points.  A shape factor of -1.0 is an interpolated
spline, 0.0 is a polyline, and +1.0 is an approximated spline.  Values
closer to zero produce sharper curves; values closer to -1.0 or +1.0
provide smoother curves.

=item B<subtype>|B<splineSubtype>

The spline object has six subtypes: open-approximated,
closed-approximated, open-interpolated, closed-interpolated, open-x
and closed-x.  The default is "open-approximated".

When using open-x or closed-x, you must include a vector of shapeFactors,
one for each control point (see above).

=item B<areaFill> = I<areaFill>

=item B<arrowHeight> = I<length>

=item B<arrowMode> = "none" | "forw[ard]" | "back[ward]" | "both"

=item B<arrowStyle>

=item B<arrowThickness> = I<length>

=item B<arrowWidth> = I<length>

=item B<capStyle> = "butt" | "round" | "projecting"

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment --------------------- splineto -----------------------------------

=item B<splineto>(I<distance>, I<heading>)

=item B<splineto>(I<points>)

The B<splineto> function draws a spline object, leaving the current position
at the final point.  The function may be called in either of the following two
ways:

=over

=item distance, heading

Distance and heading give the distance and angle of the next control point
relative to the current position.

=item point|points

Starting at the given position, add the specified control points to the spline.

=back

Note that a valid spline must have at least three control points.
If B<splineto> is called only once, giving only two control points,
the object becomes a polyline.

B<Parameters>

=over

=item B<distance> = I<length>

Distance is the straight-line distance from the current position to the
next point.

=item B<heading> (degrees)

Heading is the angle in degrees of the next point relative to the
current position.

=item B<new> = I<boolean>

By default, sequences of B<splineto> calls are merged into a single
spline object when possible, i.e. if the position and other parameters
are unchanged since the previous call.  If the B<new> parameter is true,
B<lineto> creates a new spline object even if it could have merged with
the previous call.  This is useful when using arrow modes.

=item B<point>|B<points>

Starting at the current position, add the given list of control
points to the spline.

=item B<shapeFactor>|B<shapeFactors>

When drawing an x-spline (see B<subtype>), you must provide either a
single shape factor to be applied to all points, or a vector of shape
factors, one entry for each point, to control the smoothness of the curve
around the control points.  A shape factor of -1.0 is an interpolated
spline, 0.0 is a polyline, and +1.0 is an approximated spline.  Values
closer to zero produce sharper curves; values closer to -1.0 or +1.0
provide smoother curves.

=item B<subtype>|B<splineSubtype>

The spline object has six subtypes: open-approximated,
closed-approximated, open-interpolated, closed-interpolated, open-x
and closed-x.  The default is "open-approximated".

=item B<areaFill> = I<areaFill>

=item B<arrowHeight> = I<length>

=item B<arrowMode> = "none" | "forw[ard]" | "back[ward]" | "both"

=item B<arrowStyle>

=item B<arrowThickness> = I<length>

=item B<arrowWidth> = I<length>

=item B<capStyle> = "butt" | "round" | "projecting"

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fillColor> = I<color>

=item B<lineStyle>

=item B<lineThickness> = I<length>

=item B<position> = I<point>

=item B<styleVal> = I<length>

=item B<units> = I<units>

See Global Parameters.

=back

=for comment ----------------------- text -------------------------------------

=item B<text>(I<text>)

Format a line of text at the current position.

B<Parameters>

=over

=item B<rotation> = I<rotation> (degrees)

Rotate the text relative to the x axis.

=item B<text> = I<string>

Specify a line of text.

=item B<color> = I<color>

=item B<depth> = I<depth>

=item B<fontFlags> = I<fontFlags>

=item B<fontName> = I<fontName>

=item B<fontSize> = I<fontSize> (1/72nd inch)

=item B<position> = I<point>

=item B<textJustification> = B<"left"> | B<"right"> | B<"center">

=item B<units> = I<units>

See Global Parameters.

=back

=for comment --------------------- translate ----------------------------------

=item B<translate>(I<offset>)

The B<translate> function translates all objects in the current drawing
context by the given [ dx, dy ] offset.

B<Parameters>

=over

=item B<offset> = [ I<dx>, I<dy> ]

Specify the change in each dimension.  Both I<dx> and I<dy> are of
type I<length> (see length below).

=item B<position> = I<point>

=item B<units> = I<units>

See Global Parameters.

=back

=back

=for comment ----------------- Global Parameters ------------------------------

=head2 Global Parameters

The B<new>, B<options> and B<begin> functions take the following global
parameters.  These parameters provide defaults for subsequent functions.

=over

=item B<areaFill> (default "not-filled")

Set the area fill pattern (also see B<fillColor>).  Valid values are:
"not-filled", "black", "shade1" .. "shade19", "tint1" .. "tint19",
"full", "saturated", "white", "left-diagonal-30", "right-diagonal-30",
"crosshatch-30", "left-diagonal-45", "right-diagonal-45", "crosshatch-45",
"horizontal-bricks", "vertical-bricks", "horizontal-lines",
"vertical-lines", "crosshatch", "horizontal-right-shingles",
"horizontal-left-shingles", "vertical-descending-shingles",
"vertical-ascending-shingles", "fish-scales", "small-fish-scales",
"circles", "hexagons", "octagons", "horizontal-tire-treads",
"vertical-tire-treads".

=item B<arrowHeight> = I<length> (default 0.1 inch)

Set the height of arrows (see B<arrowMode>).  Alternatively,
B<fArrowHeight> and B<bArrowHeight> set the height for only forward
arrows or only backward arrows, respectively.

=item B<arrowMode> = "none" (default) | "forw[ard]" | "back[ward]" | "both"

Draw arrows on B<arc>, B<arcto>, B<lineto>, B<polyline>, B<spline>
and B<splineto> figures.

=item B<arrowStyle> (default "stick")

Set the style for arrows (see B<arrowMode>).  Valid values are: "stick",
"triangle", "filled-triangle", "indented", "filled-indented", "pointed",
"filled-pointed", "diamond", "filled-diamond", "circle", "filled-circle",
"goblet", "filled-goblet", "square", "filled-square", "reverse-triangle",
"filled-reverse-triangle", "left-indented", "right-indented",
"half-triangle", "filled-half-triangle", "half-indented",
"filled-half-indented", "half-pointed", "filled-half-pointed", "y", "t",
"goal", "gallows", "[ m, n ]",

Alternatively, B<fArrowStyle> and B<bArrowStyle> set the style for only
forward arrows or only backward arrows, respectively.

=item B<arrowThickness> = I<length> (default 0.0125 inch)

Set the thickness of arrow lines.  Used with B<arrowMode>.  Alternatively,
B<fArrowThickness> and B<bArrowThickness> set the thickness for only
forward arrows or only backward arrows, respectively.

=item B<arrowWidth> = I<length> (default 0.05 inch)

Set the width of arrows.   Used with B<arrowMode>.  Alternatively,
B<fArrowWidth> and B<bArrowWidth> set the arrow width for only forward
arrows or only backward arrows, respectively.

=item B<capStyle> = "butt" (default) | "round" | "projecting"

Set the endcap style for B<arc>, B<arcto>, B<lineto>, B<polyline>,
B<spline>, and B<splineto>.

=item B<color> = I<color> (default "black")

Set the default pen color for all objects.

=item B<comment> = I<string>

Set the comment string that appears in the header of the .fig file.

=item B<cornerRadius> = I<length>

Set the default corner radius for B<box> objects.

=item B<depth> = I<depth> (default 50)

Set the default layer for all objects.  Valid values are 0..999.

=item B<detachedLineto> = I<boolean> (default "false")

Don't merge adjacent segments of B<lineto> objects.  This option is
useful when using the arrow modes to show an arrow to every segment.

=item B<exportFormat>

Specify the output file format, overriding the output filename extension.
The list of supported formats depends on version and compile time options
of the I<fig2dev> program.  Typical supported graphics formats are: "box",
"cgm", "dxf" (AutoCAD drawing exchange format), "eepic", "eepicemu",
"emf", "epic", "eps", "gbx" (Gerber), "ge", "gif", "ibmgl", "jpeg",
"latex", "map" (HTML image map), "mf" (MetaFont), "mmp" (Multi-MetaPost),
"mp" (MetaPost), "pcx", "pdf", "pdftex", "pdftex_t", "pic", "pictex",
"png", "ppm", "ps", "pstex", "pstex_t", "pstricks", "ptk", "shape"
(LaTeX shaped paragraphs), "sld" (AutoCAD slide format), "svg", "textyl",
"tiff", "tk", "tpic", "xbm" and "xpm".

=item B<exportOptions>

Provide additional command-line options to the I<fig2dev> program.
The value must be a reference to an array of strings.  Example:
B<[ "-f", "Roman" ]>.

=item B<fillColor> = I<color> (default "white")

Set the default fill color when using areaFill.

=item B<fontFlags>

Set or clear miscellaneous text modifier flags.  Use +I<flagName> to set
the flag, or -I<flagName> to clear the flag.

=over

=item [+-]B<rigid>

If the rigid flag is on, the font size does not scale when a compound
object is scaled.

=item [+-]B<special>

If the special text flag is on, special characters such as backslash are
passed unmodified to the output when exporting.  This option is useful
when embedding LaTeX control sequences in the text.

=item [+-]B<hidden>

If the hidden flag is on, the string "<<>>" is displayed on the canvas
instead of the text itself.  The text is displayed as usual when printing
or exporting.

=back

=item B<fontName>

Valid values are the following LaTeX fonts: "Default", "Roman", "Bold",
"Italic", "Sans Serif" or "Typewriter", or the PostScript fonts:
"Postscript Default", "Times Roman", "Times Italic", "Times Bold",
"Times Bold Italic", "Avantgarde Book", "Avantgarde Book Oblique",
"Avantgarde Demi", "Avantgarde Demi Oblique", "Bookman Light",
"Bookman Light Italic", "Bookman Demi", "Bookman Demi Italic", "Courier",
"Courier Oblique", "Courier Bold", "Courier Bold Oblique", "Helvetica",
"Helvetica Oblique", "Helvetica Bold", "Helvetica Bold Oblique",
"Helvetica Narrow", "Helvetica Narrow Oblique", "Helvetica Narrow Bold",
"Helvetica Narrow Bold Oblique", "New Century Schoolbook Roman",
"New Century Schoolbook Italic", "New Century Schoolbook Bold",
"New Century Schoolbook Bold Italic", "Palatino Roman", "Palatino Italic",
"Palatino Bold", "Palatino Bold Italic", "Symbol",
"Zapf Chancery Medium Italic", "Zapf Dingbats".

=item B<fontSize>

Set the font size in 1/72nd's of an inch.

=item B<grid> = length

Set an optional snap-to grid for groups.  Causes the corners of groups
(see B<end>) to be rounded outward to the next multiple of this length.

=item B<joinStyle> = "miter" (default) | "round" | "bevel"

Set the segment join style for B<polyline> and B<lineto>.

=item B<pageJustification> = "Center" (default) | "Flushleft"

Control how fig objects are positioned on a printed page.

=item B<lineStyle>

Set the default line style.  Valid values are: "default", "solid"
(default), "dashed", "dotted", "dash-dotted", "dash-double-dotted",
"dash-triple-dotted".

=item B<lineThickness> = I<length> (default "0.0125 inch")

Set the default thickness for all lines.

=item B<magnification> = (float, percentage, default 100)

Set the printing magnification in percent.

=item B<multiplePage> = "Single" (default) | "Multiple"

Select whether to print on a single page or multiple pages.

=item B<orientation> = "Landscape" (default) | "Portrait"

Set the paper orientation or printing.

=item B<paperSize> (default "Letter")

Set the paper size for printing.  Valid values are: "Letter", "Legal",
"Ledger", "Tabloid", "A", "B", "C", "D", "E", "A0", "A1", "A2", "A3",
"A4", "B5".

=item B<position> = I<point> (default [0, 0])

Set the starting position.  This option has the same effect as using
B<moveto> to set the position.

=item B<splineSubtype> (default "open-approximated")

Set the default subtype for B<spline> and B<splineto>.  Valid values
are: "open-approximated", "closed-approxmated", "open-interpolated",
"closed-interpolated", "open-x", "closed-x".

=item B<styleVal> = I<length> (default "0.075 inch")

Set the spacing for dashed lines.  See B<lineStyle>.

=item B<textJustification>|B<justification>

Set the text justification.  Valid values are: "left", "center" and "right".

=item B<transparentColor> = -2 (default) | -1 | I<color>

Set the transparent color for GIF export.  The special value -2 indicates
"none", and the special value -1 indicates background.

=item B<units> = I<units> (default "1.0 inch")

Set the default unit of length for all length values.  If no number is
given, it defaults to 1.0.

=back

=for comment -------------- Common Parameter Types ----------------------------

=head2 Common Parameter Types

=over

=item I<boolean>

=over

=item trueS< >  | 1

=item false | 0

=back

=item I<color>

Any of the xfig built-in colors: B<default>, B<black>, B<blue>,
B<green>, B<cyan>, B<red>, B<magenta>, B<yellow>, B<white>, B<blue4>,
B<blue3>, B<blue2>, B<ltblue>, B<green4>, B<green3>, B<green2>, B<cyan4>,
B<cyan3>, B<cyan2>, B<red4>, B<red3>, B<red2>, B<magenta4>, B<magenta3>,
B<magenta2>, B<brown4>, B<brown3>, B<brown2>, B<pink4>, B<pink3>,
B<pink2>, B<pink>, B<gold>, any color in B</usr/share/X11/rgb.txt>,
or a hexadecimal color code B<#>XXXXXX

=item I<length>

a number followed by optional unit (see I<units>)

=item I<point>

[ x, y ] where x and y are of type length

=item I<points>

[[ x1, y1 ], [ x2, y2 ], [ x3, y3 ], ... ]

where xi, yi are of type length.  Except for the case of the
interpolated spline, the outline of the figure always passes
through all points.

=item I<units>

an optional number followed by one of:

=over

=item ft | foot | feet:

foot

=item in | inch | inches:

inch

=item mil:

1/1000 inch

=item pt | point:

0.0125 inch

=item m | meter | metre:

meter

=item dam | dekameter | dekametre:

10^-1 meter

=item cm | centimeter | centametre

10^-2 meter

=item mm | millimeter | millimetre

10^-3 meter

=item fig:

1200 fig units per inch (imperial mode), or 450 fig units per cm (metric mode)

=back

=back

=cut

=head1 LICENSE

This module is free software: you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0 or later.

=head1 AUTHOR

Scott Guthridge <scott_guthridge@rompromity.net>

=head1 BUGS

Bounding boxes around text are only an approxmation.

=head1 SEE ALSO

B<xfig>, B<fig2dev>
