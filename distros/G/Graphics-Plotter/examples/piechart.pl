#! /usr/bin/perl
#
# <NOTE ORIGINAL>
# Bernhard Reiter 	Fri Oct 10 20:07:12 MET DST 1997
# $Id: piechart.c,v 1.10 1998/07/28 13:41:54 breiter Exp $
#
# Copyright (C) 1997,1998 by Bernhard Reiter 
# 
#    This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#	
#	Creates piechart, must be linked with a libplot library
#	reads ascii input file from stdin.
#
#	format: one slice per line. every trailing tab and space will
#		be ignored. The string after the last tab or space is
#		will be scanned as value. The beginnign is the label-text.
#		Empty lines and lines starting with "#" are ignored
# </NOTE>
#
#   piechart adopted to Perl on Fri, Mar 12, 1999 by Piotr Klaban <makler@man.torun.pl>
#   Requires the Plotter perl module.
#

use Graphics::Plotter;

$VERSION = '0.8a';

my $progname = $0;

sub print_version
{
             print "piechart version $VERSION\n"; 
             print "Copyright (C) 1998 by Bernhard Reiter. \n".
             	    "The GNU GENERAL PUBLIC LICENSE applies. ".
             	    	"Absolutly No Warranty!\n";
             print "DEBUG option is switched on\n" if $DEBUG;
}

sub print_usage {
	print "usage: $progname [options]\n";
	print "\t the stdin is read once.\n";
	print "\t options are:\n".
		"\t\t-t Title\tset \"Title\" as piechart title\n".
		"\t\t-T Display-Type\tone of ".
		"X, gif, pnm, ps, fig, hpgl, tek, or meta\n".
		"\t\t\t\t(meta is the default)\n".
		"\t\t-r radius\tfloat out of [0.1;1.2] default:0.8\n".
		"\t\t-d textdistance\tfloat out of ".
			"[-radius;1.2] default:0.0\n".
		"\t\t-C colornames\tcomma separated list of colornames\n".
		"\t\t\t\t(see valid names in color.txt of plotutils doc.)\n".
             	"\t\t-h\t\tprint this help and exit\n".
             	"\t\t-V\t\tprint version and exit\n";
}

#	Color in which the separating lines and the circle are drawn

$LINECOLOR = "black";

# LINEWIDTH_LINES is for the separating lines and the circle
# -1 means default 

$LINEWIDTH_LINES = -1;

# Some hardcoded limits:
# the max number of slices (^=MAXSLICES).
# LINE_BUFSIZ is the maxmumlength of input-lines.
#(You see, how lasy i was. I was not using some object orientated language
#	like objective-c and left all the neat dynamic string handling for
#	the interested hacker and or some version in the future.)

$MAXSLICES = 50;

# if an input line starts with this character, it is ignored.
$COMMENTCHAR = '#';

$M_PI = 3.14159;

# Colors the slices are getting filled with.
# the color names are feed into the libplot functions.
# The plotutils distribution contains a file doc/colors.txt which lists the
# recogized names.
#
# if the nullpointer is reached the color pointer is resetted starting
# with the first color again.

@colortable = (
"red","blue","green","yellow", "brown",
 "coral",  "magenta","cyan", "seagreen3"
);

#******************************************************************************
# Beware: This following code is for hackers only.
# 	( Yeah, it is not THAT bad, you can risk a look, if you know some C ..)
#******************************************************************************

# Program structure outline:
#	- get all options 
#	- read all input data (only from stdin so far)
#	- print
#		+ init stuff
#		+ print title
#		+ print color part for slices
#		+ print separating lines and circle
#		+ print labels
#		+ clean up stuff
 


# A nice structure, we will fill some of it, when we read the input.

#struct slice {
#	char *text;		# label for the slice
#	double value;		# value for the slice
#};

# one global variable. It is needed everywhere..

# Attention: Main Progam to be started.... :)

use Getopt::Std;

my $title;			# Title of the chart
my $return_value;		# return value for libplot calls.
my $display_type = "meta";	# default libplot output format
my $handle;			# handle for open plotter

my @slices;			# the array of slices
my $n_slices=0;			# number of slices in slices[]	;)
my $t;				# loop var(s)
my $sum;			# sum of all slice values

my $radius=0.8;		# radius of the circle in plot coords
my $text_distance=0;		# distance of text from circle

&process_arguments();

read_stdin();

# Let us count the values
$sum=0.;
for($t=0;$t<$n_slices;++$t) {
	$sum+=$slices[$t]{"value"};
}	

# initialising one plot session
				# specify type of plotter
$display_type = 'Graphics::Plotter::' . $display_type;
$handle = $display_type->new(STDIN, STDOUT, STDERR);
$return_value= $handle->openpl();
if($return_value)
{
	warn "openpl returned $return_value!\n";
}

				# creating your user coordinates
if($title) {
	$return_value= $handle->fspace(-1.4,-1.4,1.4,1.4);
} else {
	$return_value= $handle->fspace(-1.2,-1.2,1.2,1.2);
}
if($return_value)
{
	warn "fspace returned $return_value!\n";
}

# we should be ready to plot, now!



				# i like to think in degrees.
sub X { my($radius,$angle)=@_; return(cos($angle)*($radius)) }
sub Y { my($radius,$angle)=@_; return(sin($angle)*($radius)) }

sub RAD { my($angle)=shift; return((($angle)/180.)*$M_PI) }

sub XY { my($radius,$angle)=@_; return(X(($radius),RAD($angle))),(Y(($radius),RAD($angle))) }

# plot title if there is one
if($title ne '')
{
	$handle->fmove(0,$radius+$text_distance+0.2);
	$handle->alabel('c','b',$title);
}

$handle->pencolorname($LINECOLOR);

# and now for the slices
{
    my $distance;
    my $angle=0;
    my $color=$colortable[0];
    my $curcolor = 0;
    my $r=$radius;		# the radius of the slice circle

    $handle->savestate();
    $handle->joinmod("round");

				# drawing the slices
    
    $handle->filltype(1);
    $handle->flinewidth($LINEWIDTH_LINES);
    $handle->pencolorname($LINECOLOR);
    for($t=0;$t<$n_slices;++$t)
				# draw one path for every slice
    {
    	$distance=($slices[$t]{"value"}/$sum)*360.;
    	$handle->fillcolorname($color);
				
	$handle->fmove(0,0);		# start at center..
	$handle->fcont(XY($r,$angle));	
    	if($distance>179)
    	{			# we need to draw a semicircle first
				# we have to be sure to draw 
				#  counterclockwise (180 wouldn`t work 
				#  in all cases)
	    $handle->farc(0,0,XY($r,$angle),XY($r,$angle+179)); 
	    $angle+=179;	
	    $distance-=179;
    	}
	$handle->farc(0,0,XY($r,$angle),XY($r,$angle+$distance));
	$handle->fcont(0,0);		# return to center
	$handle->endpath();		# not really necessary, but intuitive
	
	$angle+=$distance;	# log fraction of circle already drawn

	$color = $colortable[++$curcolor]; 		# next color for next slice
	$color=$colortable[0] if($color eq '') ;# start over if all colors used
    }

    				# the closing circle at the end
    $handle->filltype(0);
    $handle->fcircle(0.,0.,$r);	
    				# one point in the middle
    $handle->colorname($LINECOLOR);
    $handle->filltype(1);
    $handle->fpoint(0,0);	
   					
    $handle->restorestate();
}

# and now for the text
{
    my $distance;
    my $angle=0;
    my $place;
    my $r=$radius+$text_distance;# radius of circle where text is placed
    my ($h,$v);
    my $proc;
    $handle->savestate();

    for($t=0;$t<$n_slices;$t++) 
    {
    	$distance=($slices[$t]{"value"}/$sum)*360.;
    				# let us calculate the position ...
	$place=$angle+0.5*$distance;
				# and the alignment
	$proc = sprintf("%.2f",100*$slices[$t]{"value"}/$sum);

	if($place<180) {
		$v='b';
	} else {
		$v='t';
	}
	if($place<90 || $place>270) {
		$h='l';
	} else {
		$h='r';
	}
				# plot now!
	$handle->fmove(XY($r,$place));
	$handle->alabel($h,$v," ". $slices[$t]{"text"});
	if ($proc > 10) {
	    $handle->fmove(XY($r/2,$place));
	    $handle->alabel($h,$v,$proc . "%");
	}
	
	$angle+=$distance;
    }

    $handle->restorestate();
}


				# end a plot sesssion
$return_value= $handle->closepl();
if($return_value)
{
	warn "closepl returned $return_value!\n";
}

exit 0;			# that`s it.
# finish

#***********************************************************************
# functions

 
sub process_arguments {

    my $c;		
    my $errflg = 0;
    my $show_usage=0;
    my $show_version=0;

    getopts("Vt:T:r:d:C:h") ||
    do {
	&print_version();
	&print_usage();
	exit(1);
    };

    $title = $opt_t if defined $opt_t;
    if (defined $opt_T) {
	$display_type = $opt_T;
    }
    if (defined $opt_r) {
	$radius = sprintf("%f",$opt_r);
	++$errflg if ($text_distance<(-2.0)||$text_distance>1.2);
    }
    if (defined $opt_C) {
	@colortable = split(/\s*,\s*/,$opt_C);	
    }
    if (defined $opt_V) {
	++$show_version;
    }
    if (defined $opt_h) {
	++$show_usage;
    }

    if($text_distance< (-$radius)) { ++$errflg };
	  		
    if ($errflg) {
	warn "parameters were bad!\n";
	$show_usage++;
    }
    if($show_version)
    {
	&print_version(); 
        exit(1);
    }
    if($show_usage)
    {
	&print_usage();
	exit(1);
    }

# Everything is fine with the options now ...
}


sub read_stdin
{
    my ($text,$value);

    while (<>) {
				# Skip empty lines or lines beginning with COMMENTCHAR
	next if /^\s*$/ || /^\s*$COMMENTCHAR/;
	chomp;			# strip carridge return, if there is one

	warn "Scanning line: $line\n" if $DEBUG;

				# scanning the last part
				# after a tab or space as number
				 
				# delete trailing tabs and spaces
	s/^\s+//;
	s/\s+$//;
	($text,$value) = split(/\s+/,$_);
	
	$slices[$n_slices]{"text"} = $text;
	$slices[$n_slices++]{"value"} = sprintf("%lf",$value);

	if($n_slices>=$MAXSLICES) {
		die "too many ($n_slices>=$MAXSLICES) slices\n";
	}
    }
    warn "Read $n_slices slices!\n" if $DEBUG;
}
