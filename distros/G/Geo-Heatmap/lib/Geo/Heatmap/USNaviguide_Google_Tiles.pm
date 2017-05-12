package Geo::Heatmap::USNaviguide_Google_Tiles ;
# Calculate tile characteristics given a bounding box of coordinates and a zoom...
# Author. John D. Coryat 01/2008...
# USNaviguide LLC.
# Published under Apache 2.0 license.
# Adapted from: Google Maps API Javascript...
##
# In order to correctly locate objects of interest on a Custom Map Overlay Google Maps, 
# the characteristics of each tile to build are required.
##
# Google_Tiles					# Calculate all tiles for a bounding box and zoom
# Google_Tile_Factors				# Calculate the factors needed ( Zoom, Tilesize )
# Google_Tile_Calc				# Calculate a single tile features from a tile name and zoom
# Google_Tile_to_Pix				# Calculate tile name to pixel
# Google_Coord_to_Pix				# Calculate coordinate to Pixel
# Google_Pix_to_Tile				# Calculate a tile name from a pixel location and zoom

require 5.003 ;
use strict ;
use Math::Trig ;

BEGIN {
 use Exporter ;
 use vars qw ( $VERSION @ISA @EXPORT) ;
 $VERSION	= 1.0 ;
 @ISA		= qw ( Exporter ) ;
 @EXPORT	= qw ( 
 Google_Tiles
 Google_Tile_Factors
 Google_Tile_Calc
 Google_Tile_to_Pix
 Google_Coord_to_Pix
 Google_Pix_to_Tile
 ) ;
}

#
# Call as: <array of Hashes> = &Google_Tiles(<LatitudeS>, <LongitudeW>, <LatitudeN>, <LongitudeE>, <Zoom>, [<option: tileSize>], [<option: Partial/Whole>]) ;
# Partial/Whole option: (Default: Partial)
#	Partial: Include the edge to create partial tiles
#       Whole: Include only tiles that are contained by the bounds
#
#          Returned Array Specifications:
#            Each element is a reference to a Hash:
#              NAMEY - Tile Name y
#              NAMEX - Tile Name x
#              PYS - Pixel South
#              PXW - Pixel West
#              PYN - Pixel North
#              PXE - Pixel East
#              LATS - South Latitude
#              LNGW - West Longitude
#              LATN - North Latitude
#              LNGE - East Longitude
#
#          Note: X is width, Y is height...
#

sub Google_Tiles
{
 my $latS	= shift ;
 my $lngW	= shift ;
 my $latN	= shift ;
 my $lngE	= shift ;
 my $zoom	= shift ;
 my $tileSize	= shift ;
 my $parwho	= shift ;
 my $ty		= 0 ;
 my $tx		= 0 ;
 my @ret	= ( ) ;
 my %first	= ( ) ;				# First Results Hash
 my %last	= ( ) ;				# Last Results Hash

 my $value	= &Google_Tile_Factors($zoom, $tileSize) ; # Calculate Tile Factors

 if (!defined($parwho) or !$parwho)
 {
  $parwho = 'Partial' ;
 }

 # NW: Convert Coordinates to Pixels...

 ($first{'NORTH'},$first{'WEST'}) = &Google_Coord_to_Pix( $value, $latN, $lngW ) ;

 # Convert Pixels to Tile Name...

 ($first{'NAMEY'},$first{'NAMEX'}) = &PixtoTileName( $value, $first{'NORTH'}, $first{'WEST'}, 'N', 'W', $parwho ) ;

 # SE: Convert Coordinates to Pixels...

 ($last{'SOUTH'},$last{'EAST'}) = &Google_Coord_to_Pix( $value, $latS, $lngE ) ;

 # Convert Pixels to Tile Name...

 ($last{'NAMEY'},$last{'NAMEX'}) = &PixtoTileName( $value, $last{'SOUTH'}, $last{'EAST'}, 'S', 'E', $parwho ) ;

 # Calculate tile values for all tiles...

 if ( $first{'NAMEX'} > $last{'NAMEX'} )			# Across the date line
 {
  for ( $ty = $first{'NAMEY'} ; $ty <= $last{'NAMEY'} ; $ty++ )
  {
   for ( $tx = $first{'NAMEX'} ; $tx <= $$value{'max'} ; $tx++ )
   {
    push( @ret, {&Google_Tile_Calc( $value, $ty, $tx)} ) ;
   }
   for ( $tx = 0 ; $tx <= $last{'NAMEX'} ; $tx++ )
   {
    push( @ret, {&Google_Tile_Calc( $value, $ty, $tx)} ) ;
   }
  }
 } else
 {
  for ( $ty = $first{'NAMEY'} ; $ty <= $last{'NAMEY'} ; $ty++ )
  {
   for ( $tx = $first{'NAMEX'} ; $tx <= $last{'NAMEX'} ; $tx++ )
   {
    push( @ret, {&Google_Tile_Calc( $value, $ty, $tx)} ) ;
   }
  }
 }

 $ret[0]{'NORTH'} = $first{'NORTH'} ;
 $ret[0]{'WEST'} = $first{'WEST'} ;

 $ret[$#ret]{'SOUTH'} = $last{'SOUTH'} ;
 $ret[$#ret]{'EAST'} = $last{'EAST'} ;
 
 return ( @ret ) ;
}

# Calculate Tile Factors...

sub Google_Tile_Factors
{
 my $zoom	= shift ;
 my $tileSize	= shift ;
 my %value	= ( ) ;

 # Validate and correct input parameters...

 if ( !defined($zoom) or $zoom < 0 )
 {
  $zoom	= 0 ;
 }

 if ( !defined($tileSize) or !$tileSize )
 {
  $tileSize	= 256 ;
 }

 # Calculate Values...

 $value{'zoom'}	= $zoom ;
 $value{'PI'}	= 3.1415926536 ;
 $value{'bc'}	= 2 * $value{'PI'} ;
 $value{'Wa'}	= $value{'PI'} / 180 ;
 $value{'cp'}	= 2 ** ($value{'zoom'} + 8) ;
 $value{'max'}	= (2 ** $value{'zoom'}) - 1 ;		# Maximum Tile Number
 $value{'pixLngDeg'}= $value{'cp'} / 360;
 $value{'pixLngRad'}= $value{'cp'} / $value{'bc'} ;
 $value{'bmO'}	= $value{'cp'} / 2 ;
 $value{'tileSize'} = $tileSize ;

 return \%value ;
}

# Calculate tile values from Name...

sub Google_Tile_Calc
{
 my %result	= ( ) ;
 my $value	= shift ;
 $result{'NAMEY'} = shift ;
 $result{'NAMEX'} = shift ;

 # Convert Tile Name to Pixels...

 ($result{'PYN'},$result{'PXW'}) = &Google_Tile_to_Pix( $value, $result{'NAMEY'}, $result{'NAMEX'} ) ;

 # Convert Pixels to Coordinates (Upper Left Corner)...

 ($result{'LATN'},$result{'LNGW'}) = &PixtoCoordinate( $value, $result{'PYN'}, $result{'PXW'} ) ;

 $result{'PYS'} = $result{'PYN'} + 255 ;
 $result{'PXE'} = $result{'PXW'} + 255 ;

 # Convert Pixels to Coordinates (Lower Right Corner)...

 ($result{'LATS'},$result{'LNGE'}) = &PixtoCoordinate( $value, $result{'PYS'}, $result{'PXE'} ) ;

 return %result ;
}

# Calculate a tile name from a pixel location and zoom...

sub Google_Pix_to_Tile
{
 my $value	= shift ;
 my $ty		= shift ;
 my $tx		= shift ;

 # Convert Pixels to Tile Name...

 ($ty,$tx) = &PixtoTileName( $value, $ty, $tx, 'N', 'W', 'Partial' ) ;

 return ( $ty,$tx ) ;
}

# Translate a coordinate to a pixel location...

sub Google_Coord_to_Pix
{
 my $value	= shift ;
 my $lat	= shift ;
 my $lng	= shift ;
 my @d		= ( ) ; 
 my $e		= 0 ;

 $d[1] = sprintf("%0.0f", $$value{'bmO'} + $lng * $$value{'pixLngDeg'} ) ;

 $e = sin($lat * $$value{'Wa'}) ;

 if( $e > 0.99999 )
 {
  $e = 0.99999 ;
 }

 if( $e < -0.99999 )
 {
  $e = -0.99999 ;
 }

 $d[0] = sprintf("%0.0f", $$value{'bmO'} + 0.5 * log((1 + $e) / (1 - $e)) * (-1) * $$value{'pixLngRad'} ) ;

 return (@d) ;
}

# Translate a pixel location to a tile name...

sub PixtoTileName
{
 my $value	= shift ;
 my $y		= shift ;
 my $x		= shift ;
 my $yd		= shift ;				# Y Direction: N or S
 my $xd		= shift ;				# X Direction: W or E
 my $parwho	= shift ;				# Partial / Whole
 my $yn		= 0 ;					# Y Name
 my $xn		= 0 ;					# X Name

 $yn = int( $y / $$value{'tileSize'} ) ;		# Round Down
 $xn = int( $x / $$value{'tileSize'} ) ;		# Round Down

 if ( $parwho ne 'Partial' )
 {
  if ( $yd eq 'N' )
  {
   $yn++ ;
  } else
  {
   $yn-- ;
  }
  if ( $xd eq 'W' )
  {
   $xn++ ;
  } else
  {
   $xn-- ;
  }
 }

 # Make sure tile numbers are sane...

 if ( $yn > $$value{'max'} )
 {
  $yn = $$value{'max'} ;
 } elsif ( $yn < 0 )
 {
  $yn = 0 ;
 }

 if ( $xn > $$value{'max'} )
 {
  $xn = $$value{'max'} ;
 } elsif ( $xn < 0 )
 {
  $xn = 0 ;
 }

 return( $yn, $xn ) ; 
}

# Translate a tile name to a pixel location...

sub Google_Tile_to_Pix
{
 my $value	= shift ;
 my $y		= shift ;
 my $x		= shift ;
 return( (sprintf("%0.0f", $y * $$value{'tileSize'} ), sprintf("%0.0f", $x * $$value{'tileSize'} )) ) ; 
}

# Translate a pixel location to a coordinate...

sub PixtoCoordinate
{
 my $value	= shift ;
 my $y		= shift ;
 my $x		= shift ;
 my @d		= ( ) ;
 my $e		= (($y - $$value{'bmO'}) / $$value{'pixLngRad'}) * (-1) ;

 $d[1]	= sprintf("%0.6f",($x - $$value{'bmO'}) / $$value{'pixLngDeg'}) ;

 $d[0]	= sprintf("%0.6f", (2 * atan(exp($e)) - $$value{'PI'} / 2) / $$value{'Wa'}) ;
 return (@d);
}

1;

__END__

=head1 SYNOPSIS

#!/usr/bin/perl -w
# Test Program:

# Google Tile Calculator Test Program...
# Author. John D. Coryat 01/2008 USNaviguide LLC

use strict;
use USNaviguide_Google_Tiles ;

my $latS        = 34.177442 ;
my $lngW        = -91.318359 ;
my $latN        = 35.797300 ;
my $lngE        = -88.681641 ;
my $zoom        = 8 ;
my $x           = '' ;
my %tile        = ( ) ;
my $i           = 0 ;

my @d = &Google_Tiles($latS, $lngW, $latN, $lngE, $zoom,0,'Whole');

print "Total: " . scalar(@d) . "\n" ;

for ( $i = 0; $i <= $#d; $i++ )
{
 print "Tile # $i Y: $d[$i]{'NAMEY'} X: $d[$i]{'NAMEX'}\n" ;

 %tile = %{$d[$i]} ;

 foreach $x (sort keys %tile)
 {
  print "\t$x: $tile{$x}\n" ;
 }
}

=cut
