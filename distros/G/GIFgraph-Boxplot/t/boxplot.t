use lib './t';
use strict;
use GIFgraph::boxplot;

$::WRITE = 0;
require 'ff.pl';

my $one = [27, -35, 14, 29, 39, 52];
my $two = [41, -140, 29, 45, 62, 125];
my $three = [100, 30, 88, 95, 115, 155];
my $four = [80, -100, 60, 100, 110, 195];

my @data = ( 
	["1st", "2nd", "3rd", "4th"],
	[ $one, $two, $three, $four],
	);
	
my $opts = {
	box_spacing		=> 35,
	do_stats		=> 0
	};

print "1..1\n";
($::WARN) && warn "\n";

my $fn = 't/boxplot.gif';

my $checkImage = get_test_data($fn);

my $g = new GIFgraph::boxplot( );
$g->set( %$opts );
my $Image = $g->plot( \@data );

print (($checkImage eq $Image ? "ok" : "not ok"). " 1\n");
($::WARN) && warn (($checkImage eq $Image ? "ok" : "not ok"). " 1\n");

write_file($fn, $Image) if ($::WRITE);
