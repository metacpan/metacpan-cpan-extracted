#!/usr/bin/perl

print <<__XXX__;
#VRML V2.0 utf8

# Viewpoint {
# 	position -5.431 -17.43329 -7.8381
# }

#  [0.330875428322261, -0.280945722899276, 0.786317373275996, -0.439654341729388]

# VP: [-4.25929650174993, -18.0355737661575, -6.2032912854634] [0.0865150763942622, 0.0675070751726609, 0.808799519575549, -0.577755375130763]


Transform {
	translation -3 -4 0
	children [
__XXX__

$box = "Box {size 8 1 1}";

for(0..6) {
	$angle = -0.3927 * $_;
	$cb = ($_)/10;
	$color = "$cb $cb 1";
	$trans = join ' ',$_, 3*$_, 0;
	print <<__XXX__;
		Transform {
			rotation 0 0.8 1 $angle
			translation $trans
			children [
				Shape {
					appearance Appearance {
						material Material {
							diffuseColor $color
						}
					}
					geometry $box
				}
			]
		}
__XXX__
}


print <<__XXX__;
	]
}
__XXX__
