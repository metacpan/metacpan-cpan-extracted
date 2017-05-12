#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(
	no_plan
	);

use Math::Geometry::Planar::Offset qw(OffsetPolygon);

my @points = ( # pairs of in/expect
[
	[
		[-12231.997978, -17957.6210468],
		[-12231.997978, -17977.046657009],
		[-12224.682307, -17976.891324613],
		[-12224.682307, -17959.0772560202],
		[-12177.102307, -17957.603464947],
		[-12177.102307, -17975.8810638292],
		[-12113.646734, -17974.5337187852],
		[-12113.646734, -17954.7491170294],
	],
	[
		[
			[-12175.582307, -17957.7725027741],
			[-12175.582307, -17974.3284472438],
			[-12115.166734, -17973.0456501778],
			[-12115.166734, -17956.3064490441],
		],
		[
			[-12230.477978, -17959.1046097],
			[-12230.477978, -17975.4940405134],
			[-12226.202307, -17975.4032559195],
			[-12226.202307, -17959.0008555997],
		]
	]
], # end set
); # end test points

my $dist = 1.52;

foreach my $pair (@points) {
	my $copy = [map({[@$_]} @{$pair->[0]})];
	my @polys = OffsetPolygon($copy, $dist);
	is_deeply($copy, $pair->[0], 'unmodified');
	ok(scalar(@polys) == scalar(@{$pair->[1]}), 'split count') if $pair->[1];
	if($pair->[1]) {
		# XXX numeric match likely to fail on some platforms
		# (namely 64bit, etc) -- send patches
		for(my $i = 0; $i < @polys; $i++) {
			is_deeply($polys[$i], $pair->[1][$i], 'match expected');
		}
	}
	else {
		if((-t STDOUT) and defined($ENV{DEBUG}) and (-e 'tools/show_me')) {
			# sounds like me running this manually
			my @show = map(
				{join(" ", map({'[' . join(', ', @$_) . '],'} @$_))}
				$copy, @polys);
			system($^X, 'tools/show_me', @show) and die;
			
		}
		foreach my $poly (@polys) {
			warn join("\n", map({'[' . join(', ', @$_) . '],'} @$poly)), "\n\n";
		}
	}
}

# vim:ts=4:sw=4:noet
