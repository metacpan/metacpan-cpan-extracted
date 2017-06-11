use utf8;
use strict;
use warnings;
use File::Temp qw/ tempdir /;
use Test::More tests => 2;
use Math::Trig;
use t::FigCmp;

my $dir = tempdir(CLEANUP => 1);
#my $dir = "/tmp";

#
# Test 1: load the module
#
BEGIN {
    use_ok('Graphics::Fig')
};

#
# Test 2: splineto given three points
#
eval {
    #
    # Create drawing environment.
    #
    my $fig = Graphics::Fig->new({
	color          => "green",
	arrowStyle     => "filled-indented",
	arrowWidth     => "1.5 mm",
	arrowHeight    => "2.0 mm",
	units	   => "cm"
    });

    #
    # Draw arrows from a given center to the corners of a pentagon.
    # Save # the endpoints.
    #
    my $N = 5;
    my $R = 2;
    my $center = [ 4, 4 ];
    my @polygon;
    for (my $i = 0; $i < $N; ++$i) {
	$fig->lineto($R, 360.0 * -$i/$N,  { position  => $center,
					    arrowMode => "forw",
					    color     => "#BEBEBE" });
	push(@polygon, $fig->getposition());
    }

    #
    # Draw a polygon around the arrow tips.
    #
    $fig->polygon(\@polygon, { color => "SlateBlue" });

    #
    # Inscribe a circle inside the polygon.  Nest a half-size circle
    # inside of the first circle.
    #
    my $r = $R * cos(pi / $N);
    $fig->circle({ radius   => $r, center => $center, color => "LtBlue" });
    $fig->circle({ diameter => $r, center => $center, color => "LtBlue" });

    #
    # Draw a triangle between two fixed points and the center of the pentagon.
    #
    my @triangle = ( [ 4, 0 ], [ 6, 1 ], $center );
    $fig->begin({ color => "magenta" });
    $fig->moveto($triangle[0]);
    $fig->lineto($triangle[1]);
    $fig->lineto($triangle[2]);
    $fig->lineto($triangle[0]);
    $fig->end();

    #
    # Draw a circle around the first point of the triangle.
    #
    $fig->circle(0.5, { center => $triangle[0], color => "brown3" });

    #
    # Dran an ellipse that exactly passes through the first three points
    # of the pentagon and the first two points of the triangle.
    #
    $fig->ellipse([ $polygon[0], $polygon[1], $polygon[2],
		    $triangle[0], $triangle[1] ],
		    { areaFill => "white", fillColor => "green2",
		      depth => 75 });

    #
    # Add text at 4,1.
    #
    $fig->begin({ justification => "center", color => "black",
		  fontFlags => "+rigid -special -hidden", depth => 25 });
    $fig->moveto([ 4, 1 ]);
    $fig->text("Test Drawing");
    $fig->box($fig->getbbox(), { color => "#BEBEBE" });
    $fig->end();

    #
    # Draw the bounding box around the resulting objects.
    #
    $fig->options({ color => "#FFA500" });	# orange
    $fig->box($fig->getbbox(), { areaFill => "tint17",
				 fillColor => "#FFA500", depth => 100 });

    #
    # Rotate the entire figure by one side of the pentagon.
    #
    $fig->moveto($center);
    $fig->rotate(-360 / $N);

    #
    # Translate the result so that the the corners touch the top and left
    # sides of the page.
    #
    my $bb = $fig->getbbox();
    $fig->translate([ -${$bb}[0][0], -${$bb}[0][1] ]);

    $fig->save("${dir}/advanced2.fig");
    &FigCmp::figCmp("${dir}/advanced2.fig", "t/advanced2.fig") || die;
};
ok($@ eq "", "test2");

exit(0);
