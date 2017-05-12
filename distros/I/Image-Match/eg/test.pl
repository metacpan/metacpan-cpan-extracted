# $Id: test.pl,v 1.2 2008/09/02 10:31:53 dk Exp $
use strict;
use Image::Match;

$Image::Match::DEBUG++;

# make screenshot
my $big = Image::Match-> screenshot;
# extract 70x70 image
my $small = $big-> extract( 230, 230, 70, 70);
# find again
my @all_matches = $big-> match( $small, 
	multiple => 1,
	mode     => 'geom',
);

# draw
if ( @all_matches) {
	$big-> begin_paint;
	$big-> lineWidth(2);
	my @sz = $small-> size;
	for ( my $i = 0; $i < @all_matches; $i+=2) {
		my ( $x, $y) = @all_matches[$i,$i+1];
		print "found at: $x, $y\n";
		$big-> rectangle( $x, $y, $x + $sz[0], $y + $sz[1]);
	}
	$big-> end_paint;
} else {
	print "not found\n";
	exit;
}


# display
use Prima qw(ImageViewer);
my $w = Prima::MainWindow-> new( size => [ 640, 480 ]);
$w-> insert( ImageViewer =>
	pack => { fill => 'both', expand => 1 },
	image => $big,
);

my $x = Prima::Window-> new;
$x-> insert( ImageViewer =>
	pack => { fill => 'both', expand => 1 },
	image => $small,
);

run Prima;
1;
