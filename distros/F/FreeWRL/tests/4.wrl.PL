#!/usr/bin/perl

print <<__XXX__;
#VRML V2.0 utf8

DEF TIMER TimeSensor 
  {cycleInterval 6 startTime 0 stopTime -1 enabled TRUE loop TRUE}
DEF ORI OrientationInterpolator {
	key [ 0 0.25 0.5 0.75 1]
	keyValue [
		0 0 1 0
		0 0 1 1.570796
		0 0 1 3.141593
		0 0 1 4.71238898
		0 0 1 6.2831853
	]
}

Transform {
scale 0.2 0.2 0.2
rotation 1 0 0 1.57
children [

Shape {
	geometry Box { size 4.5 4.5 20 }
	appearance Appearance { material Material { diffuseColor 0.8 0.4 0.4} }
} 

DEF WHOLE Transform {
	translation 0 0 10
	children [
__XXX__



for(1..20) {
	$angle = ($_<21||$_>40?-0.314159 * $_ : 0.314159*$_);
	$cb = ($_)/20;
	$color = "$cb $cb 1";
	$trans = join ' ',($_>20&&$_<41?-3:0), 0, -$_;
	$len = 10.6-abs(10.5-($_%20));
	$transb = ($len/1+3)." 0 0";
	$bsize = "$len 1 1";
	print <<__XXX__;
		Transform {
			rotation 0 0 1 $angle
			translation $trans
			children [
				Transform {
				translation $transb
				scale $bsize
				children [
					Shape {
						appearance Appearance {
							material Material {
								diffuseColor $color
							}
						}
						geometry Sphere { }
						# geometry Box {size 2 2 2}
						# geometry Box {size $bsize}
					}
				]
				}
			]
		}
__XXX__
}


print <<__XXX__;
	]
}

]
}

ROUTE TIMER.fraction_changed TO ORI.set_fraction
ROUTE ORI.value_changed TO WHOLE.rotation
__XXX__
