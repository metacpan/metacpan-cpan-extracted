#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 39;
BEGIN { use_ok('GSAPI') };

use bytes;

my( $width, $height, $raster, $format );
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

    pass( $name );
    is( $handle, 1234, " ... handle ($handle)" );

    if( $name eq 'display_presize' ) {
        my( $width, $height, $raster, $format ) = @more;
        ok( $width,  " ... width ($width)" );
        ok( $height, " ... height ($height)" );
        ok( $raster, " ... raster ($raster)" );
        ok( $format, " ... format ($format)" );
    }
    if( $name eq 'display_size' ) {
        ( $width, $height, $raster, $format ) = @more;
        ok( $width,  " ... width ($width)" );
        ok( $height, " ... height ($height)" );
        ok( $raster, " ... raster ($raster)" );
        ok( $format, " ... format ($format)" );
    }
    if( $name eq 'display_page' ) {
        my( $copies, $flush ) = @more;
        ok( $copies, " ... copies ($copies)" );
        ok( $flush,  " ... flush ($flush)" );
        pimage_ok( $pimage );
    }
    if( $name eq 'display_sync' ) {
        pimage_ok( $pimage, 1 );
    }
    if( $name eq 'display_preclose' ) {
        ok( !$pimage, " ... no pimage" );
    }
    if( $name eq 'display_close' ) {
        ok( !$pimage, " ... no pimage" );
    }

    return 0;
}

sub pimage_ok
{
    my( $pimage, $blank ) = @_;
    ok( $pimage, " ... pimage (".length($pimage).")" );
    return if $blank;
    my $ok = 0;
    # make sure all the data is readable
    for( my $i=0; $i < $height; $i++ ) {
        my $line = substr( $pimage, $i*$raster, $width*4 );
        my $p = unpack "H*", $line;
        $ok = 1 unless $p =~ /^(ffffff00)+$/;
    }
    ok( $ok, " ... non-blank" );
}


###########################################################################
# The following format is compatible with RGBA.  However, the alpha is
# always 0

$format = sprintf( "%d", 
            GSAPI::DISPLAY_COLORS_RGB() | 
            GSAPI::DISPLAY_ALPHA_LAST() | 
            GSAPI::DISPLAY_DEPTH_8() |
            GSAPI::DISPLAY_BIGENDIAN() | 
            GSAPI::DISPLAY_TOPFIRST()
        );

my $gs = GSAPI::new_instance();

ok( $gs, ref $gs );
GSAPI::set_stdio($gs,
                 sub { "\n" },
                 sub { length $_[0] },
                 sub { print STDERR "err: $_[0]"; length $_[0] }
                );

pass( 'set_stdio' );

GSAPI::set_display_callback( $gs, \&callback );
pass( 'set_callback' );

GSAPI::init_with_args( $gs, "-q", 
                            "-r100",
                            "-dNOPAUSE",
                            "-dBATCH",
                            "-dDisplayHandle=1234",
                            "-dDisplayFormat=$format",
#                            "-dSAFER",
                            "-sDEVICE=display"
                     );
pass( 'init_with_args' );

GSAPI::run_file($gs, "eg/mozilla.ps" );
pass( 'run_file' );

GSAPI::exit($gs);
pass( 'exit' );
