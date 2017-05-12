#!/usr/bin/perl
use strict;

# For simplified test responses
use Test;

# The modules we're testing
use GD::Graph::bars3d;
use GD::Graph::lines3d;
use GD::Graph::pie3d;

use GD::Graph::lines;
use GD::Graph::bars;

# For version number
use GD::Graph;

# To find where the matching files are
use FindBin;
use File::Spec;
use File::Basename;

# To allow GD to compare the images
use GD qw(:DEFAULT :cmp);

# To allow users to compare the images
use ExtUtils::MakeMaker qw( prompt );

# How many test do we have?
use vars qw( $test_count $export_format );

BEGIN { $|=1; $test_count = 10; plan test => $test_count; }

# If '-save' is given on the command-line then don't delete the comparison images
my $STORE = grep /^-?-save$/i, @ARGV;

# Get user response whether to run visual test
# (Would be nice to localize (localise? :-> ) this....
print STDERR "The following tests may require you to visually compare two sets of 
images. In order to do that the test will need to save an image to 
disk and have you look at them with software that supports reading 
the images. (Usually a web browser will do.) 

If the test all pass an internal comparison, you will not need to 
visually compare them. Each test that passes internal comparison 
will give an 'ok' message.

If you do not want to do any visual comparison this then you may 
skip these test.
";

my $res = prompt( "\nDo you want to perform the visual tests?", 'y' );
print "\n";

if( $res =~ /^n/i ) {
	my $skip_message = "Skipped by user request.";
	for( 1 .. $test_count ) {
		skip( $skip_message, $_ );
	} # end if
	exit 0;
} # end if



#--------------------------------------------------#
# Basic 3d bar graph                               #
#--------------------------------------------------#
my $graph = new GD::Graph::bars3d();
$export_format = $graph->export_format;

my @data = (
           ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
           [ 1203,  3500,  3973,  2859,  3012,  3423,  1230]
        );
$graph->set(
            x_label           => 'Day of the week',
            y_label           => 'Number of hits',
            title             => 'Daily Summary of Web Site',
            box_axis          => 1,
            boxclr            => '#FFFFCC',
);         
ok( compare( $graph->plot( \@data ), 'bar.png' ) );

#--------------------------------------------------#
# Large 3d bar graph with 3 datasets               #
#--------------------------------------------------#

$graph = new GD::Graph::bars3d( 800, 400 );

@data = (
  [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49],
  [3333,3573,3051,961,4318,1742,2889,1418,1683,3974,1140,4291,4496,1137,3942,1489,4084,2306,4397,3586,468,1202,428,3747,2467,866,1992,4043,4157,1914,4446,1620,1093,1491,1612,961,3983,2783,1844,3731,715,1187,3632,1935,4431,1012,2054,2374,3550,1811,608],
  [2691,2306,1545,1373,1903,2658,1163,2020,1206,1544,2264,654,2331,764,682,668,884,2734,643,2029,744,1099,934,1074,2311,1807,1320,1355,2690,2364,376,1369,2086,769,2140,1307,1954,1848,2782,2173,1720,2490,2194,1868,2104,1002,1680,1628,1841,2071,2668],
  [528,918,1472,996,1030,455,969,971,669,627,131,620,1272,597,779,745,410,1198,151,500,1320,1391,591,1316,846,1395,820,1451,934,87,1155,630,1435,487,338,460,236,410,1348,587,483,117,852,292,1417,1030,672,984,1073,361,923],
);

$graph->set(
    overwrite => 1,
    x_label => 'Den',
    y_label => 'Pocet pristupu',
    title => 'Pristupy k fakultnimu informacnimu systemu',
    y_max_value => 4500,
    y_tick_number => 18,
    y_label_skip => 2,
    x_label_skip => 1,
    x_all_ticks => 1,
    x_labels_vertical => 1,
    box_axis => 0,
    y_long_ticks => 1,
    );

ok( compare( $graph->plot( \@data ), 'multibar.png' ) );

#--------------------------------------------------#
# Stacked 3d bar graph with 3 datasets             #
#--------------------------------------------------#

$graph = new GD::Graph::bars3d();

@data = ( 
           ["1".."7"],
           [ 37,  25,   9,  10,   1,  30,  34],
           [ 12,  25,  56,  23,  51,  12,   8],
           [ 42,  25,  18,  32,   8,  13,  20],
);

$graph->set(
    cumulate     => 1,
    x_label      => 'Number',
    y_label      => 'Usage',
    title        => 'Total usage',
    box_axis     => 0,
    y_long_ticks => 1,
    );

ok( compare( $graph->plot( \@data ), 'stackbar.png' ) );

#--------------------------------------------------#
# 3d bars with x-tick-number set                  #
#--------------------------------------------------#
$graph = new GD::Graph::bars();

@data = ( 
           [ 0 .. 12 ],
           [ 14,16,19,20,23,25,22,23,22,23,25,27,28],
);
$graph->set(
        title => 'Temperature',
        x_label => "Time",
        y_label => "Temperature C",
        long_ticks=>1,
        y_max_value=> 30,
        y_min_value => 0,
        y_tick_number => 6,
#        x_tick_number => 12,
        y_label_skip => 1,
        x_label_skip => 2,
        x_max_value=> 12,
        bar_spacing=> 4,
        accent_threshold=> 400,
);

ok( compare( $graph->plot( \@data ), 'bar-ticks.png' ) );

#--------------------------------------------------#
# Basic 3d line graph                              #
#--------------------------------------------------#
$graph = new GD::Graph::lines3d();
@data = (
           ["Jan 1", "Jan 2", "Jan 3", "Jan 4", "Jan 5", "Jan 6", "Jan 7"],
           [ 120,  350,  397,  540,  110,  287,  287]
        );
$graph->set(
            x_label           => 'Date',
            y_label           => 'Number of hits',
            title             => 'Web Site Traffic',
            line_width        => 15,
            box_axis          => 1,
            boxclr            => '#FFFFCC',
);         
ok( compare( $graph->plot( \@data ), 'line.png' ) );


#--------------------------------------------------#
# Large 3d line graph with 5 datasets & legend     #
#--------------------------------------------------#

$graph = new GD::Graph::lines3d( 800, 400 );

@data = ( 
  [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49],
  [320,2447,1832,0,2411,1666,196,2072,833,2302,554,980,973,740,1218,1430,1124,79,763,1545,645,612,139,1537,506,2345,8,1492,950,1502,1188,839,2321,1725,2352,829,1288,1919,363,109,1021,1445,2401,2209,43,2114,250,35,810,187,906],
  [715,2170,645,1835,1511,618,2031,1134,1871,1338,1070,1631,372,1516,1164,2388,1983,1964,1441,1775,2620,992,1966,1754,1602,2170,800,2341,201,2617,1726,1013,749,2217,216,579,1997,400,1482,278,180,872,677,1118,1497,945,1575,228,454,851,1313],
  [2820,2546,2750,2692,2537,2903,2599,2618,2960,2997,2882,2943,2847,2965,2798,2571,2564,2502,2713,2586,2909,2859,2586,2503,2708,2992,2805,2897,2744,2906,2607,2574,2852,2932,2566,2662,2774,2976,2819,2759,2575,2992,2513,2551,2721,2694,2659,2503,2636,2786,2844],
  [1082,1295,1267,1101,1017,1188,1051,1219,1141,1045,1145,1053,1011,1166,1200,1216,1297,1016,1299,1209,1280,1071,1063,1113,1276,1080,1045,1089,1145,1292,1250,1110,1205,1087,1058,1137,1191,1268,1092,1180,1181,1151,1108,1141,1053,1215,1046,1086,1165,1229,1128],
  [795,1263,497,2711,2269,2922,2080,2363,525,811,2671,2147,664,990,1795,1936,1265,2550,338,1618,819,890,704,3010,345,2904,1319,2913,414,935,2479,2910,1296,814,2973,2996,1442,2854,1487,1638,3036,1127,227,2358,1821,1868,754,1424,2923,361,1478],
);

$graph->set(
    overwrite => 1,
    x_label => 'Den',
    y_label => 'Pocet pristupu',
    title => 'Pristupy k fakultnimu informacnimu systemu',
    y_max_value => 4500,
    y_tick_number => 18,
    y_label_skip => 2,
    x_label_skip => 1,
    x_all_ticks => 1,
    x_labels_vertical => 1,
    box_axis => 0,
    y_long_ticks => 1,
    legend_placement => 'RD',
    legend_spacing => 10,
    );

$graph->set_legend( 'Subset A', 'Subset B', 'Subset C', 'Subset D', 'Subset E',);

ok( compare( $graph->plot( \@data ), 'multiline.png' ) );

#--------------------------------------------------#
# 3d Lines with x-tick-number set                  #
#--------------------------------------------------#
$graph = new GD::Graph::lines3d();

@data = ( 
           [ 0 .. 24 ],
           [ 14,16,19,20,23,25,22,23,22,23,25,27,28,30,25,23,20,19,17,14,15,16,14,13,11],
);
$graph->set(
        title => 'Temperature',
        x_label => "Time",
        y_label => "Temperature C",
        long_ticks=>1,
        y_max_value=> 30,
        y_min_value => 0,
        y_tick_number => 6,
#        x_tick_number => 24,
        y_label_skip => 1,
        x_label_skip => 2,
        x_max_value=> 24,
        bar_spacing=> 4,
        accent_threshold=> 400,
);

ok( compare( $graph->plot( \@data ), 'line-ticks.png' ) );


#--------------------------------------------------#
# Basic 3d pie graph                               #
#--------------------------------------------------#

# GD::Graph makes different images in versions 1.32 and 1.33 (and will in 1.34)
my $GD_Graph_VERSION = $GD::Graph::VERSION;
if( ($GD_Graph_VERSION != 1.32)
 && ($GD_Graph_VERSION != 1.33)
) {
	warn "The version of GD::Graph that you have, $GD_Graph_VERSION, has not been tested. It may produce images that are different than those provided. If the images meet your satisfaction, respond, 'y' when asked if they are the same.\n";
	$GD_Graph_VERSION = 1.32;
} # end if

$graph = new GD::Graph::pie3d();
@data = (
           [".com", ".net", ".gov", ".org", ".de", ".uk", "Other"],
           [ 37,  25,  9,  7,  11,  3,  8]
        );
$graph->set(
            title             => 'Geography of Web Site',
);         

ok( compare( $graph->plot( \@data ), "pie-$GD_Graph_VERSION.png" ) );

#--------------------------------------------------#
# Basic 3d pie graph with one data point           #
#--------------------------------------------------#
$graph = new GD::Graph::pie3d();
@data = (
           [ '(Unknown)' ],
           [ 100 ]
        );
$graph->set(
            title             => 'Organisational Use',
);         

ok( compare( $graph->plot( \@data ), "pie100-$GD_Graph_VERSION.png" ) );

#--------------------------------------------------#
# Stacked bar chart with legend                    #
#--------------------------------------------------#
$graph = new GD::Graph::bars3d();

@data = ( 
           ["1".."7"],
           [ 37,  25,   9,  10,   1,  30,  34],
           [ 12,  25,  56,  23,  51,  12,   8],
           [ 42,  25,  18,  32,   8,  13,  20],
);

$graph->set(
    cumulate     => 1,
    x_label      => 'Number',
    y_label      => 'Usage',
    title        => 'Total usage',
    box_axis     => 0,
    y_long_ticks => 1,
	 legend_placement => 'RC',
);

$graph->set_legend( 'Red', 'Green', 'Blue' );

ok( compare( $graph->plot( \@data ), 'stackbar-legend.png' ) );



exit 0;

##############################################################################
#                                END OF TESTS                                #
##############################################################################


#
# A convenience function to build a graph and compare it with
# a graphics file already done
#
# Returns true on success, false on failure.
# If the failure is in building the graph then returns undef.
# If the failure is in the comparison of images, returns 0.
#
sub compare {
	my( $graph, $file ) = @_;
	# Normalize the filename into the test directory
	($file) = fileparse( $file );
	$file = File::Spec->catfile( $FindBin::RealBin, $file );
	# Open the file it should look like
	if( open( FILE, $file ) ) {
		my $gd = GD::Image->newFromPng( \*FILE ) || die "Error loading $file: $!\n";
		close FILE;
		# See if GD compares them (bypass user part if possible)
		return 1 unless ($graph->compare( $gd ) & GD_CMP_IMAGE);
	} else {
		warn "Cannot open $file: $!\n";
	} # end if
	
	# The images differ!
	# So write the image to a file and ask the user if they compare
	my $f2 = _write( $graph, $file );
	if( defined $f2 ) {
		my $r = prompt( "Do the images '$file' and '$f2' look substantially similar?", 'n' );
		print "\n";
		# Now remove the file, unless in STORE mode
		unlink $f2 unless $STORE;
		return ( $r =~ /^y/i ) ? 1 : 0;
		return 0;
	} else {
		warn "Could not save file $f2: $!\n";
		return 0;	# Failure!
	} # end if
} # end compare


#
# Writes a graphic to a file in whatever format the current engine supports
#
sub _write {
	# GLOBAL: $export_format
	my( $g, $f ) = @_;
	
	# Get the base filename, insert -t and format and put in t/ folder 
	($f) = fileparse( $f, '\..*' );
	$f = File::Spec->catfile( $FindBin::RealBin, $f );
	$f = "$f-t.$export_format";
	
	# Write out in whatever format GD prefers
	open( FILE, ">$f" ) || return undef;
	binmode FILE;
	print FILE $g->$export_format;
	close FILE;
	
	# Give back the filename
	return $f;
} # end _write
