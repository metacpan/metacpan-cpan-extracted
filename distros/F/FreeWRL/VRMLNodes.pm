# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# Default is exposedfield - third argument says what it is if otherwise:
# 0 = non-exposed field,
# in = eventIn
# out = eventOut
#
# The event subs:
#  Initialize($node,$fields,$time,$scene): called when node created in world
#  EventsProcessed($node,$fields,$time): called when events have been received
#					and processed by other routines 
#  field/eventname($node,$fields,$value,$time) 
#	(if field/exposedField, the name, otherwise exact eventname)
#		: called when eventIn received in that event.
#  ClockTick($node,$fields,$time): called at each clocktick if exists 
#	(only timesensor-type nodes)
#  
# default field/eventname: $t->set_field(...,...), if event received,
#  field is not set so that it can be ignored (e.g. TimeSensor)
#  set_field returns the eventout to send also...!!
#
#  all these can return lists of eventOuts to send.
#
# XXXXXXXXXXXX
#  Problem: Interpolators send an event at startup and they shouldn't...
#  TouchSensor: how to get hitpoint, normal and texcoords without 
#   		spending an ungodly amount of time at it?

package VRML::NodeType; # Same for internal and external!

sub check_perl_script {
	if(!$VRML::DO_PERL) {
		die(q~Perl scripts are currently unsafe as they are
trusted and run in the main interpreter. If you are sure of your
code (i.e. you have written it or know the writer), set 
the variable '$VRML::DO_PERL' to 1.

FreeWRL will soon be modified to be able to run untrusted Perl code
in Safe compartments. Until that, Perl scripts are disabled by default
now that the browser can get files from the internet.
~);
	}
}

sub init_image {
	my($name, $urlname, $t, $f, $scene) = @_;
	my $purl = $t->{PURL} = $scene->get_url;
	my $urls = $f->{$urlname};
	if($#{$urls} == -1) {
		$f->{__depth.$name} = 0;
		$f->{__x.$name} = 0;
		$f->{__y.$name} = 0;
		$f->{__data.$name} = "";
		return;
	}
	$urls->[0] =~ /\.(\w*)$/ or die("Suffixless image '$urls->[0]' (@$urls)?");
	my $suffix = $1;
	my $file = VRML::URL::get_relative($purl, $urls->[0], 1);
	my ($hei,$wi,$dep,$dat);
	if($suffix =~ /jpe?g/i) {
		eval 'require VRML::JPEG';
		if($@) {die("Cannot open image textures: '$@'")}
		print "Reading jpeg file '$file'\n";
		$dat = "";
		if(!VRML::JPEG::read_file($file,$dat,$dep,$hei,$wi)) {
			die("Couldn't read jpeg file");
		}
	} elsif($suffix =~ /png/i) {
		eval 'require VRML::PNG';
		if($@) {die("Cannot open image textures: '$@'")}
		print "Reading png file '$file'\n";
		$dat = "";
		if(!VRML::PNG::read_file($file,$dat,$dep,$hei,$wi)) {
			die("Couldn't read png file");
		}
	} else {
		die("Invalid image suffix: '$suffix'\n");
	} 
	$f->{__depth.$name} = $dep;
	$f->{__x.$name} = $wi;
	$f->{__y.$name} = $hei;
	$f->{__data.$name} = $dat;
	print"GOT IMAGE $urlname into $name [$file] ($dep $wi $hei)\n";
}

my $protono;

{
my %MAP = (
	"" => "field",
	"in" => "eventIn",
	"out" => "eventOut"
);

# XXX When this changes, change Scene.pm: VRML::Scene::newp too --
# the members must correspond
sub new {
	my($type,$name,$fields,$eventsubs) = @_;
	my $this = bless {
		Name => $name,
		Fields => {},
		Defaults => {},
		Actions => $eventsubs,
	},$type;
	for(keys %$fields) {
		$this->{Defaults}{$_} = $fields->{$_}[1];
		$this->{FieldTypes}{$_} = $fields->{$_}[0];
		# $this->{Fields}{$_} = "VRML::Field::$fields->{$_}[0]";
		my $t = $fields->{$_}[2];
		if(!defined $t or $t eq "" or $t eq "field" or $t eq "exposedField") {
			if(!defined $t or $t eq "exposedField") {
				$this->{EventOuts}{$_} = $_;
				$this->{EventOuts}{$_."_changed"} = $_;
				$this->{EventIns}{$_} = $_;
				$this->{EventIns}{"set_".$_} = $_;
			}
		} else {
			my $io;
			if($t =~ /[oO]ut$/) {
				$io = Out;
			} else {
				$io = In;
			}
			$this->{Event.$io."s"}{$_} = $_;
		}
		if(!defined $t) {
			$t = exposedField;
		} else {
			$t = ($MAP{$t} or $t);
		}
		$this->{FieldKinds}{$_} = $t;
	}
	return $this;
}
}


%VRML::Nodes::bindable = map {($_,1)} qw/
	Viewpoint
	Background
	Navigationinfo
	Fog
/;

%VRML::Nodes::initevents = map {($_,1)} qw/
	TimeSensor
	TouchSensor
	PlaneSensor
	CylinderSensor
	SphereSensor
	ProximitySensor
	Collision
	VisibilitySensor
/;

# What are the transformation-hierarchy child nodes?
%VRML::Nodes::children = qw(
	Transform	children
	Group		children
	Billboard	children
	Anchor		children
);

%VRML::Nodes::siblingsensitive = map {($_,1)} qw/
	TouchSensor
	PlaneSensor
	CylinderSensor
	SphereSensor
/;

%VRML::Nodes::sensitive = map {($_,1)} qw/
	ProximitySensor
/;



%VRML::Nodes = (
# Internal structures, to store def and use in the right way
DEF => new VRML::NodeType("DEF",{node => [SFNode, NULL]}, id => [SFString,""]),
USE => new VRML::NodeType("USE",{node => [SFNode, NULL]}, id => [SFString,""]),

Shape => new VRML::NodeType ("Shape",
	{appearance => [SFNode, NULL],
	 geometry => [SFNode, NULL]}
),

# Complete
Appearance => new VRML::NodeType ("Appearance",
	{material => [SFNode,NULL],
	 texture => [SFNode,NULL],
	textureTransform => [SFNode,NULL]
	 }
),

# Complete 
Material => new VRML::NodeType ("Material",
	{diffuseColor => [SFColor, [0.8, 0.8, 0.8]],
	 ambientIntensity => [SFFloat, 0.2],
	 specularColor => [SFColor, [0,0,0]],
	 emissiveColor => [SFColor, [0,0,0]],
	 shininess => [SFFloat, 0.2],
	 transparency => [SFFloat, 0]}
),

ImageTexture => new VRML::NodeType("ImageTexture",
	{url => [MFString, []],
	 repeatS => [SFBool, 1],
	 repeatT => [SFBool, 1],
	 __depth => [SFInt32, 1],
	 __x => [SFInt32,0],
	 __y => [SFInt32,0],
	 __data => [SFString, ""],
	},{
	Initialize => sub {
		my($t,$f,$time,$scene) = @_;
		init_image("","url",$t,$f,$scene);
		return ();
	}
	}
),

Box => new VRML::NodeType("Box",
	{size => [SFVec3f, [2,2,2]]}
),

# Complete
Cylinder => new VRML::NodeType ("Cylinder",
	{radius => [SFFloat,1],
	 height => [SFFloat,2],
	 side => [SFBool,1],
	 top => [SFBool,1],
	 bottom => [SFBool,1]},
),

# Complete
Cone => new VRML::NodeType ("Cone",
	{bottomRadius => [SFFloat,1],
	 height => [SFFloat,2],
	 side => [SFBool,1],
	 bottom => [SFBool,1]},
),

# Complete
Coordinate => new VRML::NodeType("Coordinate",
	{point => [MFVec3f, []]}
),
Color => new VRML::NodeType("Color",
	{color => [MFColor, []]}
),
Normal => new VRML::NodeType("Normal",
	{vector => [MFVec3f, []]}
),

TextureCoordinate => new VRML::NodeType("TextureCoordinate",
	{point => [MFVec2f, []]}
),


ElevationGrid => new VRML::NodeType("ElevationGrid",
	{height => [MFFloat, []],
	 xDimension => [SFInt32, 0],
	 zDimension => [SFInt32, 0],
	 xSpacing => [SFFloat, 1.0],
	 zSpacing => [SFFloat, 1.0],
	 solid => [SFBool, 1],
	 creaseAngle => [SFFloat, 0],
	 color => [SFNode, NULL],
	 normal => [SFNode, NULL],

	 colorPerVertex => [SFBool, 1],
	 normalPerVertex => [SFBool, 1],
	}
),

Extrusion => new VRML::NodeType("Extrusion",
	{beginCap => [SFBool, 1],
	 ccw => [SFBool, 1],
	 convex => [SFBool, 1],
	 creaseAngle => [SFFloat, 0],
	 crossSection => [MFVec2f, [[1,1],[1,-1],[-1,-1],[-1,1],[1,1]]],
	 endCap => [SFBool, 1],
	 orientation => [MFRotation, [[0,0,1,0]]],
	 scale => [MFVec2f, [[1,1]]],
	 solid => [SFBool, 1],
	 spine => [MFVec3f, [[0,0,0],[0,1,0]]]
	}
),

# Complete
Sphere => new VRML::NodeType("Sphere",
	{radius => [SFFloat, 1]}
),

IndexedFaceSet => new VRML::NodeType("IndexedFaceSet",
	{coord => [SFNode, NULL],
	 coordIndex => [MFInt32, []],
	 colorIndex => [MFInt32, []],
	 normal => [SFNode, NULL],
	 normalIndex => [MFInt32, []],
	 solid => [SFBool, 1],
	 creaseAngle => [SFFloat, 0],
	 texCoord => [SFNode, NULL],
	 texCoordIndex => [MFInt32, []],
	 convex => [SFBool, 1],
	 color => [SFNode, NULL],
	 colorPerVertex => [SFBool, 1],
	 ccw => [SFBool, 1],
	}
),

# Complete

IndexedLineSet => new VRML::NodeType("IndexedLineSet",
	{coord => [SFNode, NULL],
	 color => [SFNode, NULL],
	 colorIndex => [MFInt32, []],
	 coordIndex => [MFInt32, []],
	 colorPerVertex => [SFBool, 1],
	}
),

PointSet => new VRML::NodeType("PointSet",
	{color => [SFNode, NULL],
	 coord => [SFNode, NULL]
	}
),

Text => new VRML::NodeType ("Text",
	{string => [MFString, []],
	 fontStyle => [SFNode, NULL],
	 length => [MFFloat, []],
	 maxExtent => [SFFloat, 0.0],
	 __rendersub => [SFInt32, 0],   # Function ptr hack
	}, {
	Initialize => sub {
		my($t,$f) = @_;
		my $a = eval 'require VRML::Text; VRML::Text::get_rendptr();';
		if($@) {die("Warning: text loading error: '$@'\n");}
		$f->{__rendersub} = $a;
		return ();
	}
	}
),

FontStyle => new VRML::NodeType("FontStyle",
	{family => [MFString, ["SERIF"]],
	 horizontal => [SFBool, 1],
	 justify => [MFString, ["BEGIN"]],
	 language => [SFString, ""],
	 leftToRight => [SFBool, 1],
	 size => [SFFloat, 1.0],
	 spacing => [SFFloat, 1.0],
	 style => [SFString, ["PLAIN"]],
	 topToBottom => [SFBool, 1],
	}
),

Switch => new VRML::NodeType("Switch",
	{choice => [MFNode, []],
	 whichChoice => [SFInt32, -1]
	}
),

LOD => new VRML::NodeType("LOD",
	{level => [MFNode, []],
	 center => [SFVec3f, [0,0,0],  field],
	 range => [MFFloat, []]
	}
),

Transform => new VRML::NodeType ("Transform",
	{translation => [SFVec3f, [0,0,0]],
	 rotation => [SFRotation, [0,0,1,0]],
	 scale => [SFVec3f, [1,1,1]],
	 scaleOrientation => [SFRotation, [0,0,1,0]],
	 children => [MFNode, []],
	 center => [SFVec3f, [0,0,0]],
	 bboxCenter => [SFVec3f, [0,0,0]],
	 bboxSize => [SFVec3f, [-1,-1,-1]],
	},
),

TextureTransform => new VRML::NodeType ("TextureTransform",
	{center => [SFVec2f, [0,0]],
	 rotation => [SFFloat, 0],
	 scale => [SFVec2f, [1,1]],
	 translation => [SFVec2f, [0,0]],
	}
),

# Complete 
Group => new VRML::NodeType("Group",
	{children => [MFNode, []],
	 bboxCenter => [SFVec3f, [0,0,0]],
	 bboxSize => [SFVec3f, [-1,-1,-1]],
	}
),

Anchor => new VRML::NodeType("Anchor",
	{children => [MFNode, []],
	 url => [MFString, []],
	 description => [SFString, ""],
	 parameter => [MFString, []],
	 bboxCenter => [SFVec3f, [0,0,0]],
	 bboxSize => [SFVec3f, [-1,-1,-1]],
	}
),

# XXX add&removechildren
Billboard => new VRML::NodeType("Billboard",
	{children => [MFNode, []],
	 axisOfRotation => [SFVec3f, [0,1,0]],
	 bboxCenter => [SFVec3f, [0,0,0]],
	 bboxSize => [SFVec3f, [-1,-1,-1]],
	}
),

# Complete
WorldInfo => new VRML::NodeType("WorldInfo",
	{title => [SFString, ""],
	 info => [MFString, []]
	}
),

# Complete
# XXX "getting value if no events should give keyValue[0]!!!"
ScalarInterpolator => new VRML::NodeType("ScalarInterpolator",
	{key => [MFFloat, []],
	 keyValue => [MFFloat, []],
	 set_fraction => [SFFloat, undef, in],
	 value_changed => [SFFloat, undef, out],
	},
	{Initialize => sub {
		my($t,$f) = @_;
		$t->{Fields}->{value_changed} = 
		 (defined $f->{keyValue}[0] ?
		 	$f->{keyValue}[0] : 0);
		return [$t, value_changed, $f->{keyValue}[0]];
	 },
	 EventsProcessed => sub {
		my($t, $f) = @_;
		my $k = $f->{key};
		my $kv = $f->{keyValue};
		my $fr = $f->{set_fraction};
		my $v;
		if($f->{set_fraction} <= $k->[0]) {
			$v = $kv->[0]
		} elsif($f->{set_fraction} >= $k->[-1]) {
			$v = $kv->[-1]
		} else {
			my $i;
			for($i=1; $i<=$#$k; $i++) {
				if($f->{set_fraction} < $k->[$i]) {
					print "SCALARX: $i\n"
						if $VRML::verbose;
					$v = ($f->{set_fraction} - $k->[$i-1]) /
					     ($k->[$i] - $k->[$i-1]) *
					     ($kv->[$i] - $kv->[$i-1]) +
					     $kv->[$i-1];
					last
				}
			}
		}
		print "SCALAR: NEW_VALUE $v ($k $kv $f->{set_fraction}, $k->[0] $k->[1] $k->[2] $kv->[0] $kv->[1] $kv->[2])\n"
			if $VRML::verbose;
		return [$t, value_changed, $v];
	}
	}
),

# Complete
# XXX "getting value if no events should give keyValue[0]!!!"
OrientationInterpolator => new VRML::NodeType("OrientationInterpolator",
	{key => [MFFloat, []],
	 keyValue => [MFRotation, []],
	 set_fraction => [SFFloat, undef, in],
	 value_changed => [SFRotation, undef, out],
	},
	{Initialize => sub {
		my($t,$f) = @_;
		# XXX Correct?
		$t->{Fields}{value_changed} = ($f->{keyValue}[0] or [0,0,1,0]);
		return ();
		# return [$t, value_changed, $f->{keyValue}[0]];
	 },
	 EventsProcessed => sub {
		my($t, $f) = @_;
		my $k = $f->{key};
		my $kv = $f->{keyValue};
		my $fr = $f->{set_fraction};
		my $v;
		if($f->{set_fraction} <= $k->[0]) {
			$v = $kv->[0]
		} elsif($f->{set_fraction} >= $k->[-1]) {
			$v = $kv->[-1]
		} else {
			my $i;
			for($i=1; $i<=$#$k; $i++) {
				if($f->{set_fraction} < $k->[$i]) {
					print "ORIENTX: $i ($#$k) $k->[$i] $k->[$i-1] @{$kv->[$i]} | @{$kv->[$i-1]}\n"
						if $VRML::verbose::oint;
					my $f = ($f->{set_fraction} - $k->[$i-1]) /
					     ($k->[$i] - $k->[$i-1]) ;
					my $s = VRML::Quaternion->
						new_vrmlrot(@{$kv->[$i-1]});
					my $e = VRML::Quaternion->
						new_vrmlrot(@{$kv->[$i]});
					print "Start: ",$s->as_str,"\n" if $VRML::verbose::oint;
					print "End: ",$e->as_str,"\n" if $VRML::verbose::oint;
					my $step = $e->multiply($s->invert);
					print "Step: ",$step->as_str,"\n" if $VRML::verbose::oint;
					$step = $step->multiply_scalar($f);
					print "StepMult $f: ",$step->as_str,"\n" if $VRML::verbose::oint;
					my $tmp = $s->multiply($step);
					print "TMP: ",$tmp->as_str,"\n" if $VRML::verbose::oint;
					$v = $tmp->to_vrmlrot;
					print "V: ",(join ',  ',@$v),"\n" if $VRML::verbose::oint;
					last
				}
			}
		}
		print "OR: NEW_VALUE $v ($k $kv $f->{set_fraction}, $k->[0] $k->[1] $k->[2] $kv->[0] $kv->[1] $kv->[2])\n"
			if $VRML::verbose::oint;
		return [$t, value_changed, $v];
	}
	}
),

# Complete
# XXX "getting value if no events should give keyValue[0]!!!"
ColorInterpolator => new VRML::NodeType("ColorInterpolator",
	{key => [MFFloat, []],
	 keyValue => [MFColor, []],
	 set_fraction => [SFFloat, undef, in],
	 value_changed => [SFColor, undef, out],
	},
    @x = 
	{Initialize => sub {
		my($t,$f) = @_;
		$t->{Fields}->{value_changed} = ($f->{keyValue}[0] or [0,0,0]);
		return ();
		# XXX DON'T DO THIS!
		# return [$t, value_changed, $f->{keyValue}[0]];
	 },
	 EventsProcessed => sub {
		my($t, $f) = @_;
		my $k = $f->{key};
		my $kv = $f->{keyValue};
		# print "K,KV: $k, $kv->[0][0], $kv->[0][1], $kv->[0][2],
		# 	$kv->[1][0], $kv->[1][1], $kv->[1][2]\n";
		my $fr = $f->{set_fraction};
		my $v;
		if($f->{set_fraction} <= $k->[0]) {
			$v = $kv->[0]
		} elsif($f->{set_fraction} >= $k->[-1]) {
			$v = $kv->[-1]
		} else {
			my $i;
			for($i=1; $i<=$#$k; $i++) {
				if($f->{set_fraction} < $k->[$i]) {
					print "COLORX: $i\n"
						if $VRML::verbose or
						   $VRML::sverbose =~ /\binterp\b/;
					for(0..2) {
						$v->[$_] = ($f->{set_fraction} - $k->[$i-1]) /
						     ($k->[$i] - $k->[$i-1]) *
						     ($kv->[$i][$_] - $kv->[$i-1][$_]) +
						     $kv->[$i-1][$_];
					}
					last
				}
			}
		}
		print "SCALAR: NEW_VALUE $v ($k $kv $f->{set_fraction}, $k->[0] $k->[1] $k->[2] $kv->[0] $kv->[1] $kv->[2])\n"
			if $VRML::verbose or
			   $VRML::sverbose =~ /\binterp\b/;
		return [$t, value_changed, $v];
	}
	}
),

PositionInterpolator => new VRML::NodeType("PositionInterpolator",
	{key => [MFFloat, []],
	 keyValue => [MFVec3f, []],
	 set_fraction => [SFFloat, undef, in],
	 value_changed => [SFVec3f, undef, out],
	},
	@x
),
	
# Complete
# XXX "getting value if no events should give keyValue[0]!!!"
CoordinateInterpolator => new VRML::NodeType("ColorInterpolator",
	{key => [MFFloat, []],
	 keyValue => [MFVec3f, []],
	 set_fraction => [SFFloat, undef, in],
	 value_changed => [MVVec3f, undef, out],
	},
    @x = 
	{Initialize => sub {
		my($t,$f) = @_;
		# Can't do $f->{} = .. because that sends an event.
		my $nkv = scalar(@{$f->{keyValue}}) / 
				scalar(@{$f->{key}});
		$t->{Fields}->{value_changed} = 
		   ([@{$f->{keyValue}}[0..$nkv-1]] or []);
		return ();
		# XXX DON'T DO THIS!
		# return [$t, value_changed, $f->{keyValue}[0]];
	 },
	 EventsProcessed => sub {
		my($t, $f) = @_;
		my $k = $f->{key};
		my $kv = $f->{keyValue};
		my $n = scalar(@{$f->{keyValue}});
		my $nkv = scalar(@{$f->{keyValue}}) / 
				scalar(@{$f->{key}});
		# print "K,KV: $k, $kv->[0][0], $kv->[0][1], $kv->[0][2],
		# 	$kv->[1][0], $kv->[1][1], $kv->[1][2]\n";
		my $fr = $f->{set_fraction};
		my $v;
		if($f->{set_fraction} <= $k->[0]) {
			$v = [@{$kv}[0..$nkv-1]];
		} elsif($f->{set_fraction} >= $k->[-1]) {
			$v = [@{$kv}[$n-$nkv .. $n-1]];
		} else {
			my $i;
			for($i=1; $i<=$#$k; $i++) {
				if($f->{set_fraction} < $k->[$i]) {
					print "COLORX: $f->{set_fraction} $i $k->[$i] - $k->[$i-1]\n"
						if $VRML::verbose::interp;
					$v = [];
					my $o = $i * $nkv;
					for my $kn (0..$nkv-1) {
						for(0..2) {
							$v->[$kn][$_] 
							 = ($f->{set_fraction} - $k->[$i-1]) /
							     ($k->[$i] - $k->[$i-1]) *
							     ($kv->[$o+$kn][$_] - $kv->[$o+$kn-$nkv][$_]) +
							     $kv->[$o+$kn-$nkv][$_];
						}
					}
					last
				}
			}
		}
		print "CoordinateI: NEW_VALUE $v ($k $kv $f->{set_fraction}, $k->[0] $k->[1] $k->[2] $kv->[0] $kv->[1] $kv->[2])\n"
			if $VRML::verbose::interp;
		return [$t, value_changed, $v];
	}
	}
),


TimeSensor => new VRML::NodeType("TimeSensor",
	{cycleInterval => [SFTime, 1],
	 enabled => [SFBool, 1],
	 loop => [SFBool, 0],
	 startTime => [SFTime, 0],
	 stopTime => [SFTime, 0],
	 isActive => [SFBool, undef, out],
	 cycleTime => [SFTime, undef, out],
	 fraction_changed => [SFFloat, undef, out],
	 time => [SFTime, undef, out]
	}, 
	{
	 Initialize => sub {
	 	my($t,$f) = @_;
	 	return ();
	 },
	 EventsProcessed => sub {
	 	return ();
	 },
	 # 
	 #  Ignore startTime and cycleInterval when active..
	 #
	 startTime => sub {
	 	my($t,$f,$val) = @_;
		if($t->{Priv}{active}) {
		} else {
			# $f->{startTime} = $val;
		}
	 },
	 cycleInterval => sub {
	 	my($t,$f,$val) = @_;
		if($t->{Priv}{active}) {
		} else {
			# $f->{cycleInterval} = $val;
		}
	 },
	 # Ignore if less than startTime
	 stopTime => sub {
	 	my($t,$f,$val) = @_;
		if($t->{Priv}{active} and $val < $f->{startTime}) {
		} else {
			# return $t->set_field(stopTime,$val);
		}
	 },

	 ClockTick => sub {
		my($t,$f,$tick) = @_;
		my @e;
		my $act = 0; 
		# XXX Not spec :(
		if(!$f->{enabled}) {
			if($f->{isActive}) {
				push @e, [$t, "isActive", 0];
			}
			return @e;
		}
		# Are we active?
		if($tick > $f->{startTime}) {
			if($f->{startTime} >= $f->{stopTime}) {
				if($f->{loop}) {
					$act = 1;
				} else {
					if($f->{startTime} + $f->{cycleInterval} >=
						$tick) {
						$act = 1;
					}
				}
			} else {
				if($tick < $f->{stopTime}) {
					if($f->{loop}) {
						$act = 1;
					} else {
						if($f->{startTime} + $f->{cycleInterval} >=
							$tick) {
							$act = 1;
						}
					}
				}
			}
		}
		my $ct = 0, $frac = 0;
		my $time = ($tick - $f->{startTime}) / $f->{cycleInterval};
		print "TIMESENS: $time '$act'\n" if $VRML::verbose::timesens;
		if($act) {
			if($f->{loop}) {
				$frac = $time - int $time;
			} else {
				$frac = ($time > 1 ? 1 : $time);
			}
		} else {$frac = 1}
		$ct = int $time;
		if($act || $f->{isActive}) {
			push @e, [$t, "time", $tick];
			push @e, [$t, fraction_changed, $frac];
			print "TIME: FRAC: $frac ($time $act $ct $tick $f->{startTime} $f->{cycleInterval} $f->{stopTime})\n"
				if $VRML::verbose;
			if($ct != $f->{cycleTime}) {
				push @e, [$t, cycleTime, $ct];
			}
		} 
		if($act) {
			if(!$f->{isActive}) {
				push @e, [$t, isActive, 1];
			}
		} else {
			if($f->{isActive}) {
				push @e, [$t, isActive, 0];
			}
		}
		$this->{Priv}{active} = $act;
		return @e;
	 },
	}
),

TouchSensor => new VRML::NodeType("TouchSensor",
	{enabled => [SFBool, 1],
	 isOver => [SFBool, undef, out],
	 isActive => [SFBool, undef, out],
	 hitPoint_changed => [SFVec3f, undef, out],
	 hitNormal_changed => [SFVec3f, undef, out],
	 hitTexCoord_changed => [SFVec2f, undef, out],
	 touchTime => [SFTime, undef, out],
	},
	{
	__mouse__ => sub {
		my($t,$f,$time,$moved,$button,$over,$pos,$norm,$texc) = @_; 
		print "MOUSE: over $over but $button moved $moved\n"
			if $VRML::verbose::tsens;
		if($button eq "DRAG") {return}
		# 1. isover
		if($moved and $t->{MouseOver} != $over) {
			print "OVCH\n"
				if $VRML::verbose::tsens;
			$f->{isOver} = $over;
			$t->{MouseOver} = $over;
		}
		if($over) {
			$f->{hitPoint_changed} = $pos;
			$f->{hitNormal_changed} = $norm;
		}
		# 2. hitpoint
		# XXX
		# 3. button
		if($t->{MouseOver} and $button) {
			if($button eq "PRESS") {
				print "ISACT\n"
					if $VRML::verbose::tsens;
				$f->{isActive} = 1;
				$t->{MouseActive} = 1;
			} else {
				if($t->{MouseActive}) {
					print "TOUCHTIM\n"
						if $VRML::verbose::tsens;
					$f->{touchTime} = $time;
				}
				print "ISACT 0\n"
					if $VRML::verbose::tsens;
				$f->{isActive} = 0;
				$t->{MouseActive} = 0;
			}
		}
	}
	}
),

PlaneSensor => new VRML::NodeType("PlaneSensor",
	{
	 enabled => [SFBool, 1],
	 maxPosition => [SFVec2f, [-1,-1]],
	 minPosition => [SFVec2f, [0,0]],
	 offset => [SFVec3f, [0,0,0]],
	 autoOffset => [SFBool, 1],
	 isActive => [SFBool, undef, eventOut],
	 trackPoint_changed => [SFVec3f, undef, eventOut],
	 translation_changed => [SFVec3f, undef, eventOut],
	},
	{
	__mouse__ => sub {
		my($t,$f,$time,$moved,$button,$over,$pos,$norm,$texc) = @_;
		# print "PS_MOUSE: $moved $button $over @$pos @$norm\n";
		if($button eq "PRESS") {
			$t->{OrigPoint} = $pos;
			$f->{isActive} = 1;
		} elsif($button eq "RELEASE") {
			print "PLREL!\n";
			undef $t->{OrigPoint};
			$t->{isActive} = 0;
			if($f->{autoOffset}) {
				$f->{offset} = $f->{translation_changed};
			}
		} elsif($button eq "DRAG") {
			# 1. get the point on the plane
			my $op = $t->{OrigPoint};
			my $of = $f->{offset};
			my $mult = 
			   ($op->[2] - $pos->[2]) / 
				($norm->[2] - $pos->[2]);
			my $nx = $pos->[0] + $mult * ($norm->[0] - $pos->[0]);
			my $ny = $pos->[1] + $mult * ($norm->[1] - $pos->[1]);
			# print "Now: ($mult $op->[2]) $nx $ny $op->[0] $op->[1] $of->[0] $of->[1]\n";
			$f->{trackPoint_changed} = [$nx,$ny,$op->[2]];
			my $tr = [
				$nx - $op->[0] + $of->[0], $ny - $op->[1] + $of->[1], 0 + $of->[2]];
			print "TR: @$tr\n";
			for(0..1) {
				# Clamp
				if($f->{maxPosition}[$_] >=
				   $f->{minPosition}[$_]) {
					if($tr->[$_] < $f->{minPosition}[$_]) {
						$tr->[$_] =
						 $f->{minPosition}[$_];
					} elsif($tr->[$_] > $f->{maxPosition}[$_]) {
						$tr->[$_] =
						 $f->{maxPosition}[$_];
					}
				}
			}
			print "TRC: (@$tr) (@$pos)\n";
			$f->{translation_changed} = $tr;
		}
	}
	}
),

SphereSensor => new VRML::NodeType("SphereSensor",
	{
	 enabled => [SFBool, 1],
	 offset => [SFRotation, [0,1,0,0]],
	 autoOffset => [SFBool, 1],
	 isActive => [SFBool, undef, eventOut],
	 trackPoint_changed => [SFVec3f, undef, eventOut],
	 rotation_changed => [SFRotation, undef, eventOut],
	}, 
	{
	__mouse__ => sub {
		my($t,$f,$time,$moved,$button,$over,$pos,$norm,$texc) = @_;
		# print "PS_MOUSE: $moved $button $over @$pos @$norm\n";
		if($button eq "PRESS") {
			$t->{OrigPoint} = $pos;
			$t->{Radius} = $pos->[0] ** 2 +
				$pos->[1] ** 2 + $pos->[2] ** 2;
			$f->{isActive} = 1;
		} elsif($button eq "RELEASE") {
			undef $t->{OrigPoint};
			$t->{isActive} = 0;
			if($f->{autoOffset}) {
				$f->{offset} = $f->{rotation_changed};
			}
		} elsif($button eq "DRAG") {
			# 1. get the point on the plane
			my $op = $t->{OrigPoint};
			my $r = $t->{Radius};
			my $of = $f->{offset};

			my $tr1sq = $pos->[0]**2 + $pos->[1]**2 + $pos->[2]**2;
			my $tr2sq = $norm->[0]**2 + $norm->[1]**2 + $norm->[2]**2;
			my $tr1tr2 = $pos->[0]*$norm->[0] +$pos->[1]*$norm->[1] +$pos->[2]*$norm->[2];
			my @d = map {$norm->[$_]-$pos->[$_]} 0..2;
			my $dlen = $d[0]**2 + $d[1]**2 + $d[2]**2;

			my $a = $dlen;
			my $b = 2*($d[0]*$pos->[0] + $d[1]*$pos->[1] + $d[2]*$pos->[2]);
			my $c = $tr1sq - $r*$r;

			$b /= $a; $c /= $a;

			my $und = $b*$b - 4*$c;
			if($und >= 0) {
				my $sol;
				if($b >= 0) {
					$sol = (-$b + sqrt($und))/2;
				} else {
					$sol = (-$b - sqrt($und))/2;
				}
				my @r = map {
					$pos->[$_] + $sol * ($norm->[$_] - $pos->[$_])
				} 0..2;
				# Ok, now we have the two vectors op
				# and r, find out the rotation to take 
				# one to the other.
				my @cp = (
					$r[1] * $op->[2] - $op->[1] * $r[2],
					$r[2] * $op->[0] - $op->[2] * $r[0],
					$r[0] * $op->[1] - $op->[0] * $r[1],
				) ;
				my @dot = (
					$r[0] * $op->[0],
					$r[1] * $op->[1],
					$r[2] * $op->[2]
				);
				my $an = atan2((my $cl
					 = $cp[0]**2+$cp[1]**2+$cp[2]**2),
				      $dot[0]**2+$dot[1]**2+$dot[2]**2);
				for(@cp) {$_ /= $cl}
				$f->{trackPoint_changed} = [@r];
				
				# print "QNEW: @cp, $an (R: $r)\n";
				my $q = VRML::Quaternion->new_vrmlrot(
					@cp, -$an
				);
				# print "QNEW2: @$of\n";
				my $q2 = VRML::Quaternion->new_vrmlrot(
					@$of
				);

				$f->{rotation_changed} = 
					$q->multiply($q2)->to_vrmlrot();
			}
			
		}
	}
	}
),

VisibilitySensor => new VRML::NodeType("VisibilitySensor",
	{center => [SFVec3f, [0,0,0]],
	 enabled => [SFBool, 1],
	 size => [SFVec3f, [0,0,0]],
	 enterTime => [SFTime, undef, out],
	 exitTime => [SFTime, undef, out],
	 isActive => [SFBool, undef, out],
	},
	{
	Initialize => sub {
		my($t,$f,$time,$scene) = @_;
		if($f->{enabled}) {
			return ([$t, enterTime, $time],
				[$t, isActive, 1]);
		}
		return ();
	}
	}
),

ProximitySensor => new VRML::NodeType("ProximitySensor",
	{center => [SFVec3f, [0,0,0]],
	 size => [SFVec3f, [0,0,0]],
	 enabled => [SFBool, 1],
	 enterTime => [SFTime, undef, out],
	 exitTime => [SFTime, undef, out],
	 isActive => [SFBool, undef, out],
	 position_changed => [SFVec3f, undef, out],
	 orientation_changed => [SFRotation, undef, out],
    # These fields are used for the info.
         __hit => [SFInt32, 0],
	 __t1 => [SFVec3f, [10000000,0,0]],
	 __t2 => [SFRotation, [0,1,0,0]],
	},
	{
	 ClockTick => sub {
	 	my($t,$f,$tick) = @_;
	#	print "PRCT: '$f->{enabled}' '$t->{BackEnd}'\n"
	#		if($VRML::verbose::prox);
		return if !$f->{enabled};
		return if !$t->{BackEnd};
		# Ugly - should abstract
		my $r = $t->{BackEnd}->get_proximitysensor_stuff($t->{BackNode});
		if($VRML::verbose::prox) {
			print "PROX: $r->[0] ($r->[1][0] $r->[1][1] $r->[1][2]) ($r->[2][0] $r->[2][1] $r->[2][2] $r->[2][3])\n";
		}
		if($r->[0]) {
			if(!$f->{isActive})  {
				$f->{isActive} = 1;
				$f->{enterTime} = $tick;
			}
			$f->{position_changed} = $r->[1];
			$f->{orientation_changed} = $r->[2];
		} else {
			if($f->{isActive}) {
				$f->{isActive} = 0;
				$f->{exitTime} = $tick;
			}
		}
	 }
	}
),


DirectionalLight => new VRML::NodeType("DirectionalLight",
	{ambientIntensity => [SFFloat, 0],
	 color => [SFColor, [1,1,1]],
	 direction => [SFVec3f, [0,0,-1]],
	 intensity => [SFFloat, 1],
	 on => [SFBool, 1]
	}
),

PointLight => new VRML::NodeType("DirectionalLight",
	{ambientIntensity => [SFFloat, 0],
	 color => [SFColor, [1,1,1]],
	 direction => [SFVec3f, [0,0,-1]],
	 intensity => [SFFloat, 1],
	 on => [SFBool, 1],

	 attenuation => [SFVec3f, [1,0,0]],
	 location => [SFVec3f, [0,0,0]],
	 radius => [SFFloat, 100],
	}
),

SpotLight => new VRML::NodeType("DirectionalLight",
	{ambientIntensity => [SFFloat, 0],
	 color => [SFColor, [1,1,1]],
	 direction => [SFVec3f, [0,0,-1]],
	 intensity => [SFFloat, 1],
	 on => [SFBool, 1],

	 attenuation => [SFVec3f, [1,0,0]],
	 beamWidth => [SFFloat, 1.570796],
	 cutOffAngle => [SFFloat, 0.785398],
	 location => [SFVec3f, [0,0,0]],
	 radius => [SFFloat, 100],
	}
),

# XXX
Background => new VRML::NodeType("Background",
	{
	 set_bind => [SFBool, undef, eventIn],
	 skyAngle => [MFFloat, []],
	 skyColor => [MFColor, [[0,0,0]]],
	 groundAngle => [MFFloat, []],
	 groundColor => [MFColor, []],
	 isBound => [SFBool, undef, eventOut],
	 bindTime => [SFTime, undef, eventOut],
	 (map {(
		 $_.Url => [MFString, []],
		 __x_.$_ => [SFInt32,0],
		 __y_.$_ => [SFInt32,0],
		 __data_.$_ => [SFString, ""],
		 __depth_.$_ => [SFInt32, 1],
	 )} qw/back front top bottom left right/),
	},
	{
	Initialize => sub {
		my($t,$f,$time,$scene) = @_;
		for(qw/back front top bottom left right/) {
			init_image("_$_","${_}Url",$t,$f,$scene);
		}
		return ();
	}
	}
),

Viewpoint => new VRML::NodeType("Viewpoint",
	{position => [SFVec3f,[0,0,10]],
	 orientation => [SFRotation, [0,0,1,0]],
	 fieldOfView => [SFFloat, 0.785398],
	 description => [SFString, ""],
	 jump => [SFBool, 1],
	 set_bind => [SFBool, undef, in],
	 bindTime => [SFTime, undef, out],
	 isBound => [SFBool, undef, out],
	},
	{
	Initialize => sub {
		my($t,$f) = @_;
		return ();
	},
	WhenBound => sub {
		my($t,$scene,$revealed) = @_;
		print "VP_BOUND!\n" if $VRML::verbose::bind;
		$t->{BackEnd}->bind_viewpoint($t,
			($revealed?$t->{VP_Info}:undef));
	},
	WhenUnBound => sub {
		my($t,$scene) = @_;
		print "VP_UNBOUND!\n" if $VRML::verbose::bind;
		$t->{VP_Info} = $t->{BackEnd}->unbind_viewpoint($t);
	}
	}
),

NavigationInfo => new VRML::NodeType("NavigationInfo",
	{type => [MFString, ""],
	 headlight => [SFBool, 1],
	 avatarSize => [MFFloat, [0.25, 1.6, 0.75]],
	 visibilityLimit => [SFFloat, 0.0],
	 set_bind => [SFBool, undef, eventIn],
	 isBound => [SFBool, undef, eventOut],
	 speed => [SFFloat, 1.0],
	 },
	{
	 	WhenBound => sub {
			my($t) = @_;
			$t->{BackEnd}->bind_navi_info($t);
		},
	},
),

# Complete
#  - fields, eventins and outs parsed in Parse.pm by special switch :(
Script => new VRML::NodeType("Script",
	{url => [MFString, []],
	 directOutput => [SFBool, 0, ""], # not exposedfields
	 mustEvaluate => [SFBool, 0, ""]
	},
	{
		Initialize => sub {
			my($t,$f,$time,$scene) = @_;
			print "ScriptInit $_[0] $_[1]!!\n" if $VRML::verbose::script;
			print "Parsing script\n" if $VRML::verbose::script;
			my $h;
			my $Browser = $scene->get_browser();
			for(@{$f->{url}}) {
				my $str = $_;
				print "TRY $str\n" if $VRML::verbose::script;
				if(s/^perl_tjl_xxx://) {
					check_perl_script();
					$h = eval "({$_})";
					if($@) {
						die "Inv script '$@'"
					}
					last;
				} elsif(s/^perl_tjl_xxx1://) {
					{
					print "XXX1 script\n" if $VRML::verbose::script;
					check_perl_script();
					my $t = $t->{RFields};
					$h = eval "({$_})";
					print "Evaled: $h\n" if $VRML::verbose::script;
					if($@) {
						die "Inv script '$@'"
					}
					}
					last;
				} elsif(/\.class$/) {
					$t->{PURL} = $scene->get_url;
					if(!defined $VRML::J) {
						eval('require "VRML/VRMLJava.pm"');
						if($@) {die $@;}
						$VRML::J = 
							VRML::JavaCom->new();
					}
					$VRML::J->newscript($t->{PURL},$_,$t);
					$t->{J} = $VRML::J;
					$t->{J}->sendinit($t);
					last;
				} elsif(/\.js/) {
					die("Sorry, no javascript files yet -- XXX FIXME (trivial fix!)");
				} elsif(s/^(java|vrml)script://) {
					eval('require VRML::JS;');
					if($@) {die $@}
					$t->{J} = VRML::JS->new($_,$t,$Browser);
					last;
				} else {
					warn("unknown script: $_");
				}
			}
			if(!defined $h and !defined $t->{J}) {
				die "Didn't found a valid perl_tjl_xxx(1) or java script";
			}
			print "GOT EVS: ",(join ',',keys %$h),"\n" if $VRML::verbose::script;
			$t->{ScriptScript} = $h;
			my $s;
			if(($s = $t->{ScriptScript}{"initialize"})) {
				print "CALL $s\n if $VRML::verbose::script"
				 if $VRML::verbose::script;
				return &{$s}();
			} elsif($t->{J}) {
				return $t->{J}->initialize($scene);
			}
			return ();
		},
		url => sub {
			print "ScriptURL $_[0] $_[1]!!\n" if $VRML::verbose::script;
			die "URL setting not enabled";
		},
		__any__ => sub {
			my($t,$f,$v,$time,$ev) = @_;
			print "ScriptANY $_[0] $_[1] $_[2] $_[3] $_[4]!!\n"
				if $VRML::verbose::script;
			my $s;
			if(($s = $t->{ScriptScript}{$ev})) {
				print "CALL $s\n"
				 if $VRML::verbose::script;
				return &{$s}();
			} elsif($t->{J}) {
				return $t->{J}->sendevent($t, $ev, $v, $time);
			}
			return ();
		},
		EventsProcessed => sub {
			my($t,$f) = @_;
			print "ScriptEP $_[0] $_[1]!!\n"
				if $VRML::verbose::script;
			if($t->{J}) {
				return $t->{J}->sendeventsproc($t);
			}
			return ();
		},
	}
),

# XXX
Collision => new VRML::NodeType("Collision",
	{collide => [SFBool, 1],
	 children => [MFNode, []],
	}
),

Inline => new VRML::NodeType("Inline",
	{bboxSize => [SFVec3f, [-1,-1,-1]],
	 bboxCenter => [SFVec3f, [0,0,0]],
	 url => [MFString, []]
	},
	{
	Initialize => sub {
		my($t,$f,$time,$scene) = @_;
		# XXXXXX!!
		my $purl = $scene->get_url();

		my $urls = $f->{url};
		my ($text,$url) = VRML::URL::get_relative($purl, $urls->[0]);

		$p = $scene->new_proto("__proto".$protono++);
		$p->set_url($url);
		VRML::Parser::parse($p, $text);

		if(!defined $p) {
			die("Inline not found");
		}
		$t->{ProtoExp} = $p;
		$t->{ProtoExp}->set_parentnode($t);
		$t->{ProtoExp}->make_executable();
		$t->{ProtoExp}{IsInline} = 1;
		$t->{IsProto} = 1;
		return ();
	}
	}
),

);



