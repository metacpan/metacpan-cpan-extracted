#!/usr/bin/perl

#
# joinpath.t
#

use strict ;
use Test ;
use Cwd;
use File::PathConvert qw( setfstype joinpath );

my @data ;

BEGIN {
@data = (
# fsspec Output        $volume, $directory, $filename
[ 'VMS', '[d1.d2.d3]', '',      'd1.d2.d3', ''        ]
);
   plan tests => ( $#data + 1 ) ;
}

my $oldfsspec = '' ;

my $i ;
for( $i= 0; $i <= $#data; ++$i ) 
{
   my( $fsspec, $expected, $volume, $directory, $filename ) = @{$data[ $i ]} ;

   die '$fsspec undefined'
      unless defined( $fsspec ) ;
   die '$expected undefined'
      unless defined( $expected ) ;
   die '$volume undefined'
      unless defined( $volume ) ;
   die '$directory undefined'
      unless defined( $directory ) ;
   die '$filename undefined'
      unless defined( $filename ) ;

   if ( $fsspec ne $oldfsspec ) 
   {
      setfstype( $fsspec ) ;
      $oldfsspec= $fsspec ;
   }
   my( $out ) = joinpath( $volume, $directory, $filename );
   ok( 
      $out, 
      $expected, 
      "joinpath( \"$volume\", \"$directory\", \"$filename\" ) ; # for '$fsspec'" 
   ) ;
}
