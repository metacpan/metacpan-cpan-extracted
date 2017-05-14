#!/usr/bin/perl

# Computes the waypoints on a path composed only of orthogonal
# linear segments between the 2 tiles on the "waypoints" layer
# with properties "spawn_point" and "leave_point", and moving
# along the path tiles on the "path" layer

# This allows you to place 2 tiles with the correct properties
# on the map, draw some path between them (made up of only
# horizontal or vertical segments), and get a list of cell
# row,col pairs to use as waypoints for creeps traveling
# along the path

# You draw it, we give you the numbers

# Note loops in path will kill this script, and ambiguous paths
# can lead to strange results

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Games::TMX::Parser;

my $parser = Games::TMX::Parser->new(
    map_dir  => $Bin,
    map_file => 'tower_defense.tmx',
);

my $map             = $parser->map;
my $waypoints_layer = $map->get_layer('waypoints');
my $path_layer      = $map->get_layer('path');
my @spawn_cells     = $waypoints_layer->find_cells_with_property('spawn_point');
my @leave_cells     = $waypoints_layer->find_cells_with_property('leave_point');

die "Exactly one spawn and one leave point are required"
    unless @spawn_cells == 1 && @leave_cells == 1;

my ($spawn, $leave) = ($spawn_cells[0], $leave_cells[0]);

my ($cell, $dir, @cells);

# start on spawn cell but from path layer not waypoints layer
$cell = $path_layer->get_cell($spawn->xy);

while (my $next = advance(\@cells, $cell, $dir)) {
    ($cell, $dir) = @$next;
}

for my $c (@cells) {
    print $c->x.",".$c->y."\n";
}

# if the path we are on continues on same dir, continue the path
# else register new waypoint and seek next cell in path
sub advance {
    my ($cells, $cell, $dir) = @_;
    if ($dir) {
        my $next_cell = $cell->$dir;
        return [$next_cell, $dir] if $next_cell && $next_cell->tile;
    }
    push @$cells, $cell;
    my $seek = $cell->seek_next_cell($dir);
    return $seek;
}

