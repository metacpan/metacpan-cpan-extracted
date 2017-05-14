use blib;

require "VRML/Browser.pm";

my $b = new VRML::Browser;
my $s = $b->get_scene;
my $be = $b->get_backend;
$be->set_best();

my $a = $b->createVrmlFromString('

DEF CYL Shape {
    appearance Appearance {
        material Material {
            diffuseColor 1 1 0
            shininess 20
        }
    }
    geometry Cylinder {
        radius 0.25
        height 0.5
    }
}

Transform {
    translation -0.4 0.5 0.5
    children [
        USE CYL
    ]
}
');


$s->topnodes($a);

$b->eventloop;

my $s2 = $be->snapshot();

wr($s2, "/tmp/foo.ppm");
system("cjpeg -quality 95  </tmp/foo.ppm >/tmp/scene.jpg");
system("pnmtops </tmp/foo.ppm >/tmp/scene.ps");

sub wr {
	my($i,$n) = @_;
	open O,"|rawtoppm $i->[0] $i->[1] > $n";
	print O $i->[2];
	close O;
}
