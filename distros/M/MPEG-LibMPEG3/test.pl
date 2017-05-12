#!/usr/bin/perl -w

use lib './blib/lib';
use strict;
$| = 1;

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    if( $@ ) { 
	use lib 't';
    }
    use Test;
    plan tests => 3 }

use MPEG::LibMPEG3;
ok(1);

##------------------------------------------------------------------------
## Try a file, any file.. 
##------------------------------------------------------------------------
my @files = qw( eg/t.mpg eg/cdxa-fix.mpg );

my $mpeg = MPEG::LibMPEG3->new();
$mpeg->set_cpus(1); ## I only have 1 cpu but you can put whatever
$mpeg->set_mmx(1);    ## but it has mmx instructions

foreach my $file ( @files ) {
    print '-' x 74, "\n";
    print "Parsing file: $file ", -s $file, " bytes\n";
    print '-' x 74, "\n";

    ok $mpeg->probe( $file ) or next;


    
##------------------------------------------------------------------------
## Audio
##------------------------------------------------------------------------
    printf "Audio Streams: %d\n", $mpeg->astreams;
    for ( 0..$mpeg->astreams() - 1 ) {
	print  "  Stream #$_\n";
	    printf "\tachans  : %d\n", $mpeg->achans( $_ );
	printf "\tarate   : %d\n", $mpeg->arate( $_ );
	printf "\taformat : %s\n", $mpeg->acodec( $_ );
	printf "\tduration: %0.2f\n", $mpeg->aduration( $_ );
	print "\n";
    }
    
##------------------------------------------------------------------------
## Video
##------------------------------------------------------------------------
    printf "Video Streams: %d\n", $mpeg->vstreams;
    for ( 0..$mpeg->vstreams() - 1 ) {
	print  "  Stream #$_\n";
	    printf "\tWidth        : %d\n"   , $mpeg->width( $_ );
	printf "\tHeight       : %d\n"   , $mpeg->height( $_ );
	printf "\tAspect Ratio : %d\n"   , $mpeg->aspect( $_ );
	printf "\tFrame Rate   : %0.2f\n", $mpeg->fps( $_ );
	printf "\tTotal Frames : %d\n"   , $mpeg->vframes( $_ );
	printf "\tColor Model  : %d\n"   , $mpeg->colormodel( $_ );
	printf "\tDuration     : %0.2f\n", $mpeg->vduration( $_ );

	print "Dumping frames as YUV\n";
	for ( my $i = 0; $i < $mpeg->vframes; $i++ ) {
	    my $output_rows = $mpeg->get_yuv;
	    my $frame_yuv   = sprintf( "%s-%05d.yuv", $file, $i );
	    # printf "Opening $frame_yuv\n";
	    print '.';
	    open OUT, "> $frame_yuv" or 
		die "Can't open file $frame_yuv for output: $!\n";

	    print OUT $output_rows;
	
	    close OUT;

	    # drop_frames( 30, $_ );
	    if ( $i > 1 && $i % $mpeg->fps($_) == 0 ) {
		printf " %0.0f sec/s\n", $i/$mpeg->fps($_);
	    }
	}
	printf " %0.2f sec/s\n", $mpeg->duration;  

    }
    
##------------------------------------------------------------------------
## Miscellaneous
##------------------------------------------------------------------------

}
