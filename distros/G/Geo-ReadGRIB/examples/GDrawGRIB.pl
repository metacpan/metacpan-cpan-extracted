#! /usr/bin/perl
#--------------------------------------------------------------------------
# GDrawGRIB.pl
#
# Create a animated GIF from Wavewatch III GRIB data.
#--------------------------------------------------------------------------

use strict;
use warnings;

# use lib "../lib";
use Geo::ReadGRIB;
use IO::File;
use Carp;
use GD;

our $VERSION = 1.0;

my $gribFile = shift or help();


#----------------------------------------------
# The following variables are scaled for use 
# with the small Wavewatch III GRIB file 
# akw.HTSGW.grb included with this distribution 
# covering the far north Pacific.
#
# For use with other Wavewatch GRIB files adjust
# latitude longitude pairs, time and data type
# as needed.
# 
# The points ($la1, $lo1) and ($la2, $lo2) define
# the corners of rectangular area. 
#
# Printing the output or the show() and getError()
# methods as shown below will help find these
# values.   
#----------------------------------------------
# ADJUST THESE VARIABLES AS NEEDED
#----------------------------------------------
my $la1  = 65;
my $la2  = 45;
my $lo1  = 159.5;
my $lo2  = 236.5;
my $time = 1142078400;
my $type = 'HTSGW';

my $w = Geo::ReadGRIB->new($gribFile);
$w->getFullCatalog;

print $w->getError,"\n" if $w->getError;
print $w->show;

my $plit = $w->extractLaLo( [$type], $la1, $lo1, $la2, $lo2, $time );

croak $w->getError,"\n" if $w->getError;

#---------------------------------------
# Example: Find the range of data values
#          in this file.
#---------------------------------------

$plit->first;
print "number of lat points: ",$plit->numLat," number of long points ",$plit->numLong,"\n";

my ( $min, $max, %unique ) = ( 1000, 0 );
while ( my $place = $plit->current and $plit->next ) {
    next if $place->data($type) eq 'UNDEF';

    $unique{ $place->data( $type ) }++;

    if ( $place->data( $type ) < $min ) {
        $min = $place->data( $type );
    }

    if ( $place->data( $type ) > $max ) {
        $max = $place->data( $type );
    }
}

print "min: $min, max: $max, unique values: ",scalar keys %unique,"\n";

#---------------------------------------
# Example: create a GIFF image from 
# this data.
#---------------------------------------
my $im = GD::Image->new( $plit->numLong, $plit->numLat );    # (width, height)

my $white = $im->colorAllocate( 255, 255, 255 );
my $black = $im->colorAllocate( 0,   0,   0 );
$im->transparent($white);
$im->interlaced('true');

my $colors = Colors();
my @palette;
foreach my $c (@$colors) {
    $palette[ $c->[3] ] = $im->colorAllocate( $c->[0], $c->[1], $c->[2] );
}

# Set up a mapping between data value ranges and colors using function...
my $theseBands = colorBandMap( $min, $max );  # (min, max)

# Not iterate through the data and draw GIF with colors maped to data values
$plit->first;
for  my $y ( 0 .. $plit->numLat -1 ) {
    for my $x ( 0 .. $plit->numLong -1 ) {
        
        my $place = $plit->current;
        my $td = $place->data( $type );

        if ( $td =~ /UNDEF/ ) {
            # land will be UNDEF, make it black
            $im->setPixel( $x, $y, $black );
        }
#       for optional lat long lines
#       elsif ( $place->long % 30 == 0 or $place->lat % 30 == 0 ) {
#            $im->setPixel( $x, $y, $white );
#       }

        else {
            foreach my $band (@$theseBands) {
                # color this pixle accoding to the  
                # band the data is in
                if ( $td >= $band->[0] and $td <= $band->[1] ) {
                    $im->setPixel( $x, $y, $palette[ $band->[2] ] );
                }
            }
        }

        $plit->next;
    }
}

my $file_name = "out-GDrawGRIB.gif";
my $F = IO::File->new( ">$file_name" ) or croak "can't open $file_name";
binmode $F;
print $F $im->gif;
close $F;


#--------------------------------------------------------------------------
# Colors()
#
# Returns an array of RGB values for a spectrum of colors from blue to red
# and numbers 1-33 to use as names in GD code.
#
# This color palette was developed by Frank Cox in 1999 for use when 
# graphing weather data. 
#--------------------------------------------------------------------------
sub Colors {

   my $rgb =
      # blue
     [[   0,170,255, 1],
      [   0,187,255, 2],
      [   0,204,255, 3],
      [   0,221,255, 4],
      [   0,238,255, 5],
      [   0,255,255, 6],
      # blue green                
      [  17,255,255, 7],
      [  34,255,238, 8],
      [  51,255,221, 9],
      [  68,255,204,10],
      [  85,255,184,11],
      [ 102,255,107,12],
      # green                
      [ 119,255,153,13],
      [ 136,255,136,14],
      [ 153,255,119,15],
      [ 170,255,102,16],
      [ 187,255, 85,17],
      [ 204,255, 68,18],
      [ 221,255, 51,19],
      [ 238,255, 34,20],
      # yellow                
      [ 255,255, 17,21],
      [ 255,255,  0,22],
      [ 255,238,  0,23],
      [ 255,221,  0,24],   # orange
      [ 255,187,  0,25],
      [ 255,153,  0,26],
      # red
      [ 255,119,  0,27],
      [ 255, 85,  0,28],
      [ 255, 51,  0,29],
      [ 255, 17,  0,30],
      [ 230,  0,  0,31],
      [ 196,  0,  0,32],
      [ 162,  0,  0,33]];

   return $rgb;
}

#--------------------------------------------------------------------------
# colorBandMap( min, max)
#
# Takes a minimum and maximum value.
#
# Returns an array mapping data values to color number from the GDraw()
# color set 1-33. Array elements are triplets [band-start, band-end, 
# color-number] like this [[a1,b1,c1],[a2,b2,c2],...] where ax and bx 
# define a range of data values (ax < bx) and cx is the color number. 
#--------------------------------------------------------------------------
sub colorBandMap {

    my ( $mn, $mx ) = @_;

    carp "max ($mx) should be bigger than min ($mn)" if not $mx > $mn;

    my $inc = sprintf "%.2f", ( $mx - $mn ) / 33;

    my $bands = [];

    my ( $lower, $upper ) = ( $mn, $mn + $inc );

    for my $n ( 1 .. 32 ) {
        push @$bands, [ $lower, $upper, $n ];
        $lower = sprintf "%.2f", $upper + .01;
        $upper = sprintf "%.2f", $upper + $inc;
    }

    push @$bands, [ $lower, 1000, 33 ];

    return $bands;
}



#--------------------------------------------------------------------------
# help()
#--------------------------------------------------------------------------
sub help {

   my $help = <<"   END";

   Usage: GDrawGRIB.pl gribfile_name
   Example: GDrawGRIB.pl ../lib/Geo/Sample-GRIB/akw.HTSGW.grb

   END

   print $help;
   exit;
}

__END__



#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#  Application Documentation
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


=head1 NAME

GDrawGRIB.pl - An example program using Geo::ReadGRIB to extract data from a 
Wavewatch III GRIB file and draw a map image with it.

=head1 VERSION

This documentation refers to GDrawGRIB.pl version 1.0


=head1 USAGE

    # The following usage example will work with the small Wavewatch III GRIB 
    # file akw.HTSGW.grb included with this distribution when run from the
    # examples directory of the distribution. The file covers wave height in 
    # the far north Pacific for late March 2006.

    Usage: GDrawGRIB.pl gribfile_name
    Example: GDrawGRIB.pl ../lib/Geo/Sample-GRIB/akw.HTSGW.grb

    # The output is a GIF file: out-GDrawGRIB.gif in the current directory.
    #
    # To use with other Wavewatch GRIB files, adjust latitude longitude pairs,
    # time and data type as needed. These will all be found as veriables near
    # the beginning of the program.
    # 
    # The points ($la1, $lo1) and ($la2, $lo2) define the corners of a 
    # rectangular area that must be covered in the file. Likewise, $time must
    # be an included time in epoch seconds and $type will be name of an 
    # included data type.
    #
    # Printing the output or the show() and getError() methods as shown in the 
    # code will help find these. 

=head1 DESCRIPTION

This example program shows how to use Geo::ReadGRIB and its iterator methods to
extract data from a Wavewatch III file and create a GIF map image of the data
at a given time. The default values of variables are set to work with the small 
GRIB file included with the Geo::ReadGRIB distribution. Veriable values can be
adjusted for other Wavewatch GRIB files.

Wavewatch III GRIB files can be found under 

ftp://polar.ncep.noaa.gov/pub/waves/

Look in the latest_run directory for files with the .grb suffix. 

=head1 DIAGNOSTICS

Geo::ReadGRIB may set errors after method calls. These can be seen with the 
getError method. Most common errors will report out of range values for
latitude, longitude, or time. Adjust the $la and $lo and $time variables to 
correct.

=head1 DEPENDENCIES

This program requires the GD module.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this example program.
Please report problems to <Maintainer name(s)>  (<contact address>)
Patches are welcome.

=head1 AUTHOR

Frank Cox  E<lt>frank.l.cox@gmail.comE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009 Frank Cox  E<lt>frank.l.cox@gmail.comE<gt> All rights reserved.

This example program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut



