use strict;
use warnings;
use blib;
use Math::Geometry::Voronoi;

my $n = shift || 1000;

my @points;
for (1 .. $n) {
    push @points, [ rand(), rand() ];
}

$|++;
while (1) {
    my $geo    = Math::Geometry::Voronoi->new(points => \@points);
    my $result = $geo->compute();

    #use Devel::Size qw(size total_size);
    #print "OBJ SIZE: " . total_size($geo);
    #print "RESULT SIZE: " . total_size($result);
    #print "DATA SIZE: " . total_size(\@points);
    print ".";    
}

