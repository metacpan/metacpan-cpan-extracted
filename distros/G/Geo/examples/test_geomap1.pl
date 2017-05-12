#!/usr/local/bin/perl -w
use blib;
use strict;
use Geo::GNUPlot;

my ($plot_obj, $msg, $grid_file, $return_val, $track_AR, $output_file, $temp_dir)=undef;
my ($gnuplot, $map_file)=undef;

#$position_AR=[18.8,'N',93.9,'W'];
#$position_AR=[18.8,'N',175.9,'W'];
#$position_AR=[18.8,'N',180,'E'];
$track_AR=[
		[10,20],
		[20,20],
		[30,30],
		[30,40],
		[35,50],
	];

#Create new Geo::GNUPlot object.
$grid_file='/home/Geo-GNUPlot/examples/radius_grid'; 
$gnuplot='/usr/local/bin/gnuplot';
$map_file='/home/Geo-GNUPlot/examples/w2.dat'; 

($plot_obj,$msg)=Geo::GNUPlot->new({
							'grid_file' => $grid_file,
							'gnuplot' => $gnuplot,
							'map_file' => $map_file,
							});

#Generate a plot of the track
$output_file='/home/test/plot.gif';
$temp_dir='/home/test/';

($return_val,$msg)=$plot_obj->plot_track($track_AR,$output_file,{
								'temp_dir'=>$temp_dir,
								'x_pad' => 1,
								'y_pad' => 1,
								'x_scale' => 2,
								'y_scale' => 2,
								});

print "return_val is $return_val\n";
print "msg is $msg\n";

exit;
