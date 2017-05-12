#!/home/jason/perl/bin/perl -w
##############################
use strict;
use Geo::ShapeFile::Point comp_includes_z => 0, comp_includes_m => 0;
use Geo::ShapeFile;

# TODO: not sure if the real shpdump does z or m first
# TODO: documentation

my $obj = new Geo::ShapeFile(shift());

print "Shapefile Type: ".$obj->shape_type_text."   # of Shapes: ".$obj->shapes;
print "\n\n";
printf("File Bounds: ( %.3f,  %.3f,%d,%d)\n",
    $obj->x_min, $obj->y_min,
    ($obj->m_min || 0), ($obj->z_min || 0),
);
printf("         to  ( %.3f,  %.3f,%d,%d)\n\n",
    $obj->x_max, $obj->y_max,
    ($obj->m_max || 0), ($obj->z_max || 0),
);

for (1 .. $obj->shapes) {
    my $shape = $obj->get_shp_record($_);

    printf("Shape:%d (%s)  nVertices=%i, nParts=%i\n",
        $_-1, $shape->shape_type_text,$shape->num_points,$shape->num_parts,
    );
    printf("  Bounds:( %.3f,  %.3f,%d,%d)\n",
        $shape->x_min,$obj->y_min,($obj->m_min || 0),($obj->z_min || 0),
    );
    printf("      to ( %.3f,  %.3f, %d,%d)\n",
        $obj->x_max,$obj->y_max,($obj->m_max || 0),($obj->z_max || 0),
    );
    foreach my $p (1 .. $shape->num_parts) {
        my @part = $shape->get_part($p);
        my $labeled = 0;
        for(@part) {
            printf("   %1s ( %.3f,  %.3f, %d, %d) %s\n",
                ((($p > 0) && (!$labeled))?"+":""),
                $_->X,$_->Y,($_->M || 0),($_->Z || 0),
                ($labeled?"":"Ring"),
            );
            
            $labeled = 1;
        }
    }
    print "\n";
}
