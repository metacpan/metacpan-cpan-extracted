use blib;

$VRML::verbose::be = 1;
require "VRML/Browser.pm";

VRML::VRMLFunc::render_verbose(1);

my $b = new VRML::Browser;
my $s = $b->get_scene;

my $a = $b->createVrmlFromString('
Transform {
rotation 1 0 0 0.1
children [
Transform {
translation 0 1 0
children [
	Shape {
	 geometry Cone { bottomRadius 1.5 }
	 appearance DEF AP
	   Appearance { material Material { diffuseColor 0.4 0.1 0.1 
	   	emissiveColor 0.6 0.01 0.01
		ambientIntensity 0.2
	   } }
	}
]
}
Transform {
translation 0 -1 0
children [
	Shape {
	 geometry Cylinder { radius 0.75 }
	 appearance DEF AP
	   Appearance { material Material { diffuseColor 0.6 0.1 0.1 
	   	emissiveColor 0.0 0.0 0.0
	   } }
	}
]
}
]
}
');

$s->topnodes($a);

print $s->as_string;


$b->prepare;
my $be = $b->get_backend;
$be->set_best();
$be->pushview([0,0,4.2],[0,0,1,0]);

$b->tick; $b->tick;

$b->tick();
$b->tick();
$b->tick();
print "TAKING SHOT\n";
my $s1 = $be->snapshot();
print "TOOK SHOT\n";

my $s1 = $be->snapshot();
$be->popview();
$be->pushview([0,0,-4.2],[0,1,0,atan2(0,-1)]);
$b->tick();
$b->tick();
$b->tick();
$b->tick();

my $s2 = $be->snapshot();

$be->popview();

# $b->eventloop;

wr($s1, "/tmp/s1.ppm");
wr($s2, "/tmp/s2.ppm");

$cj = "| cjpeg -quality 95";

system "pnmflip -rotate90 </tmp/s1.ppm | pnmscale -xysize 45 45 $cj >/tmp/sr.jpg";
system "pnmflip -rotate270 </tmp/s1.ppm | pnmscale -xysize 45 45 $cj >/tmp/sl.jpg";
system "pnmflip -tb </tmp/s2.ppm | pnmscale -xysize 45 45 $cj >/tmp/su.jpg";

sub wr {
	my($i,$n) = @_;
	open O,"|rawtoppm $i->[0] $i->[1] > $n";
	print O $i->[2];
	close O;
}
