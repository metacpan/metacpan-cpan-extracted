use strict;
use warnings;
use rlib;

use Test::LeakTrace;
#use Devel::LeakTrace;

use Geo::ShapeFile;

my $fname = 't/test_data/lakes.shp';

#leaktrace {
    process_file();
#} -verbose;


sub process_file {

    my $shapefile = Geo::ShapeFile->new ($fname);
    #$shapefile->caching('shp', 0);
    #$shapefile->caching('shx', 0);
    #$shapefile->caching('dbf', 0);
    $shapefile->disable_all_caching;

    my $n_features = $shapefile->shapes();
    for my $id (1 .. $n_features) {
        my %attr = $shapefile->get_dbf_record($id);
        my $polygon = $shapefile->get_shp_record($id);
        my @points = $polygon->points();
        my $pcount = 0;
        my $totalpoints = scalar (@points);
        foreach my $coord (@points) {
            my $x = $coord->get_x;
            my $y = $coord->get_y;
            #my ($x, $y) = ($coord->X, $coord->Y);
            #print "[$x,$y]";
            $pcount++;
            # All but the last coordinate should be followed by a comma
            #if ($pcount != $totalpoints) { 
                #print ",";
            #}
        }
    }
    my $x;  #  breakpoint hook
}