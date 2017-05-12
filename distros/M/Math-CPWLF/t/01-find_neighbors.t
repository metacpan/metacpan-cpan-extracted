use warnings;
use strict;

use Test::More 'no_plan';

use Math::CPWLF;

my @tests =
   (

   [ 'none',                      [ undef, undef ],  [ ],     1,   0, -1 ],

   [ 'one - direct',              [ 0, 0 ],          [ 1 ],   1,   0, 0 ],
   [ 'one - left out of bounds',  [ 0, 0 ],          [ 1 ],   0,   0, 0 ],
   [ 'one - right out of bounds', [ 0, 0 ],          [ 1 ],   2,   0, 0 ],

   [ 'two - left direct',         [ 0, 1 ],          [ 1,2 ], 1,   0, 1 ],
   [ 'two - right direct',        [ 0, 1 ],          [ 1,2 ], 2,   0, 1 ],
   [ 'two - left out of bounds',  [ 0, 1 ],          [ 1,2 ], 0,   0, 1 ],
   [ 'two - right out of bounds', [ 0, 1 ],          [ 1,2 ], 3,   0, 1 ],
   [ 'two - between',             [ 0, 1 ],          [ 1,2 ], 1.5, 0, 1 ],

   [ 'three - left direct',         [ 0, 1 ],        [ 1,2,3 ], 1,   0, 2 ],
   [ 'three - middle direct',       [ 0, 1 ],        [ 1,2,3 ], 2,   0, 2 ],
   [ 'three - right direct',        [ 1, 2 ],        [ 1,2,3 ], 3,   0, 2 ],
   [ 'three - left out of bounds',  [ 0, 1 ],        [ 1,2,3 ], 0,   0, 2 ],
   [ 'three - right out of bounds', [ 1, 2 ],        [ 1,2,3 ], 4,   0, 2 ],
   [ 'three - between bottom',      [ 0, 1 ],        [ 1,2,3 ], 1.5, 0, 2 ],
   [ 'three - between top',         [ 1, 2 ],        [ 1,2,3 ], 2.5, 0, 2 ],

   );
   
for my $t ( @tests )
   {
   
   my $name = shift @{ $t };
   my $exp  = shift @{ $t };
   
   my @got = Math::CPWLF::_binary_search( @{ $t } );
   
   is_deeply( \@got, $exp, $name );
   
   }