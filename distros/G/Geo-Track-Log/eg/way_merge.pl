#!/usr/bin/perl

# way_merge.pl - merge all waypoints
use Geo::Track::Log;

my $way_list;
foreach (@ARGV){
    my $way = new Geo::Track::Log;
    open my $fd, $_;
    $way->loadWayFromGarnix($fd);
    $way->{name} = $_;
    close $fd;
    push @$way_list, $way;
}

# Geo::Track::Log doesn't know how to clean up waypoints.
# so create another tool...but I don't really know what the
# tool should do, so hack on it here.

use Data::Dumper;

my $combined = new Geo::Track::Log;
$combined->combine_waypoint($way_list);

# now we have a Geo::Track::Log object with the combination of all
# of our track logs within...get rid of everything where long= -90
# this is a special case to fix my broken import to my Rino.

my $final = new Geo::Track::Log();
foreach my $pt (@{$combined->{log}}){   
        next if ($pt->{long} == -90);
        $final->addPoint($pt);
}

$final->output_track_text();

exit;
