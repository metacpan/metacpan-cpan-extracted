#!/usr/bin/perl

#
# rel2abs.t
#


use strict ;
use Test ;
use Cwd;
use File::PathConvert qw( setfstype rel2abs );

my @data ;

BEGIN {
   @data = (
     # OS       INPUT             BASE                       OUTPUT                   
   );

   plan tests => ( $#data + 1 ) ;
}

my $oldfsspec = '' ;

my $i ;

for ($i = 0 ; $i <= $#data ; ++$i )
{
   my( $fsspec, $in, $base, $expected ) = @{$data[ $i ] } ;
   die '$fsspec undefined'
      unless defined( $fsspec ) ;
   die '$in undefined'
      unless defined( $in ) ;
   die '$base undefined'
      unless defined( $base ) ;
   die '$expected undefined'
      unless defined( $expected ) ;

   if ( $fsspec ne $oldfsspec ) 
   {
      setfstype( $fsspec ) ;
      $oldfsspec= $fsspec ;
   }
   ok( 
      rel2abs($in, $base), 
      $expected, 
      "rel2abs( \"$in\", \"$base\" ) for \"$fsspec\"" 
   ) ;
}
