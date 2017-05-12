#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use Imager;
use GSAPI qw( :const );

use File::Basename;

use bytes;

my( $width, $height, $raster, $format, $outfile );
sub callback
{
    my( $name, $handle, $device, @more ) = @_;

    my $pimage;
    if( @more and 1024 < length $more[-1] ) {
        $pimage = pop @_;
    }

    if( $name eq 'display_update' ) {
        print STDERR '.';
        return 0;
    }

    if( $name eq 'display_size' ) {
        ( $width, $height, $raster, $format ) = @more;
        print "   width: $width\n";
        print "   height: $height\n";
    }
    if( $name eq 'display_page' ) {

        ### This is the important part
        my $img = Imager->new( xsize=>$width, ysize=>$height, channels=>3 );
        for( my $i=0; $i < $height; $i++ ) {

            ### Access one row of data
            my $line = substr( $pimage, $i*$raster, $width*4 );

            ### Add it to the image
            # Imager expects RGBa, but because GS always has a=0, we have
            # channels=>3 above, which mans the alpha layer is thrown away.
            $img->setscanline( 'y'=>$i, x=>0, type=>'8bit', 
                               pixels => $line
                             ) or die $img->errstr;
        }
        print "   $outfile\n";

        # my $new = $img->convert(preset=>'noalpha');
        $img->write( file => $outfile, type=>'png' )
                or die $img->errstr;
    }
    return 0;
}

###############################################################
# The following format is compatible with Imager
$format = sprintf( "%d", 
            DISPLAY_COLORS_RGB | 
            DISPLAY_ALPHA_LAST | 
            DISPLAY_DEPTH_8 |
            DISPLAY_BIGENDIAN | 
            DISPLAY_TOPFIRST
        );

foreach my $infile ( @ARGV ) {
    $outfile = basename $infile;
    $outfile .= ".png";
    print "----------------------------------------------------------------\n";
    print "$infile\n";

    my $gs = GSAPI::new_instance();
    die "Must have an instance of GSAPI" unless $gs;
    GSAPI::set_stdio($gs,
                     sub { "\n" },
                     sub { print "$_[0]"; length $_[0] }, 
                     sub { print STDERR "err: $_[0]"; length $_[0] }
                    );

    GSAPI::set_display_callback( $gs, \&callback );

    GSAPI::init_with_args( $gs,
                                "-q", "-r100",
                                "-dNOPAUSE",
                                "-dBATCH",
                                "-dDisplayHandle=1234",
                                "-dDisplayFormat=$format",
                                "-sDEVICE=display"
                         );

    GSAPI::run_file( $gs, $infile );

    GSAPI::exit($gs);
    GSAPI::delete_instance($gs);
}

