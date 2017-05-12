#!/usr/bin/perl

# Main functional testing for Image::Math::Constrain

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 47;
use Image::Math::Constrain;





#####################################################################
# Constructor Testing

sub ok_constrain {
	my $expected = shift;
	my @params   = @_;
	my $math     = Image::Math::Constrain->new( @params );
	isa_ok( $math, 'Image::Math::Constrain' );
	is( $math->{width},  $expected->[0], '->{width} is correct'  );
	is( $math->width,    $expected->[0], '->width is correct'    );
	is( $math->{height}, $expected->[1], '->{height} is correct' );
	is( $math->height,   $expected->[1], '->height is correct'   );
}

# A zillion variants of the legal way to create a new constrain object
my @tests = (
	[ [ 800, 600 ], 800, 600             ],
	[ [ 800, 600 ], 800, 600             ],
	[ [ 800, 600 ], [ 800, 600 ]         ],
	[ [ 800, 600 ], 'constrain(800x600)' ],
	[ [ 800, 600 ], '800x600'            ],
	[ [ 800, 600 ], '800w600h'           ],
	[ [ 800, 0   ], '800w'               ],
	[ [ 0,   0   ], '0x0'                ],
	);

foreach my $test ( @tests ) {
	ok_constrain( @$test );
}





#####################################################################
# Test the actual constraining

my $math = Image::Math::Constrain->new( 80, 100 );
isa_ok( $math, 'Image::Math::Constrain' );

my @list = $math->constrain( 800, 600 );
my $hash = $math->constrain( 800, 600 );

is_deeply( \@list, [ 80, 60, 0.1 ], '->constrain returns correctly in list context' );
is_deeply( $hash, { width => 80, height => 60, scale => 0.1 },
	'->constrain returns correctly in scalar context' );

@list = $math->constrain( 40, 60 );
is_deeply( \@list, [ 40, 60, 1 ], '->constrain returns correctly in list context' );





# Other miscellaneous things
ok( $math, 'An object is true' );
is( $math->as_string, 'constrain(80x100)', '->as_string works correctly' );
is( "$math", 'constrain(80x100)', '->as_string is the auto-stringification method' );
