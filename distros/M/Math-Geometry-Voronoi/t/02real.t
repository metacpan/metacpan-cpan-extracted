use strict;
use warnings;
use Test::More qw(no_plan);
BEGIN { use_ok('Math::Geometry::Voronoi') or die }

# run a test with some real data - around 1000 points on an integer grid
use vars qw(@POINTS);
do "t/real_data.txt";

my $geo = Math::Geometry::Voronoi->new(points => \@POINTS);
$geo->compute();
my @geo_polys = $geo->polygons(normalize_vertices => sub { int($_[0]) });


my @polygons;
foreach my $poly (@geo_polys) {
    my ($p, @verts) = @$poly;
    my $point = $POINTS[$p];

    next unless $point->[3] == 5017;
    
    push @polygons, { poly => \@verts,
                      point => $point };
}

# known real value
is(@polygons, 101);
