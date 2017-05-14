#!/usr/local/bin/perl -w -d:ptkdb
use blib;
use strict;
use Geo::GNUPlot;

my ($plot_obj, $msg, $grid_file, $return_val, $position_AR)=undef;

$position_AR=[18.8,'N',93.9,'W'];
#$position_AR=[18.8,'N',175.9,'W'];
#$position_AR=[18.8,'N',180,'E'];

$grid_file='/home/Geo-GNUPlot/examples/radius_grid'; 

($plot_obj,$msg)=Geo::GNUPlot->new($grid_file);

($return_val,$msg)=$plot_obj->_radius_function($position_AR);

print "return_val is $return_val\n";
print "msg is $msg\n";

exit;
