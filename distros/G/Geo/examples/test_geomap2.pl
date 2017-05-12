#!/usr/local/bin/perl -w
use blib;
use strict;
use Geo::GNUPlot;

#$Geo::GNUPlot::DEBUG=1;

my ($plot_obj, $msg, $grid_file, $return_val, $track_AR, $output_file, $output_file2, $temp_dir)=undef;
my ($gnuplot, $map_file)=undef;

#Create new Geo::GNUPlot object.
$grid_file='/home/Geo-GNUPlot/examples/radius_grid'; 
$gnuplot='/usr/local/bin/gnuplot';
$map_file='/home/Geo-GNUPlot/examples/w2.dat'; 

($plot_obj,$msg)=Geo::GNUPlot->new({
							'grid_file' => $grid_file,
							'gnuplot' => $gnuplot,
							'map_file' => $map_file,
							});

#Generate a plot of the radius function
$output_file='/home/test/plot.gif';
$output_file2='/home/test/plot2.gif';
$temp_dir='/home/test/';

($return_val,$msg)=$plot_obj->plot_radius_function($output_file,$output_file2,{
								'temp_dir'=>$temp_dir,
								'x_pad' => 1,
								'y_pad' => 1,
								'x_scale' => 2,
								'y_scale' => 2,
								});

print "return_val is $return_val\n";
print "msg is $msg\n";

exit;
