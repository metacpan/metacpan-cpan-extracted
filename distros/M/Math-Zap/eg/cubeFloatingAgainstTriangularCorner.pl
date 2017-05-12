#!perl -w
#______________________________________________________________________
# Draw cube floating against triangular corner in 3d with shadows.
# Perl License.
# PhilipRBrenan@yahoo.com, 2004.
#______________________________________________________________________

use Math::Zap::Draw;
use Math::Zap::Color;
use Math::Zap::Cube unit=>-cu;
use Math::Zap::Triangle;
use Math::Zap::Vector;

#_ Draw _______________________________________________________________
# Draw this set of objects.
#______________________________________________________________________

draw 
  ->from    (vector( 10,   10,  10))
  ->to      (vector(  0,    0,   0))
  ->horizon (vector(  1,  0.5,   0))
  ->light   (vector( 20,   30, -20))

    ->object(triangle(vector( 0,  0,  0), vector( 8,  0,  0), vector( 0,  8,  0)),                         'red')
    ->object(triangle(vector( 0,  0,  0), vector( 0,  0,  8), vector( 0,  8,  0)),                         'green')
    ->object(triangle(vector( 0,  0,  0), vector(12,  0,  0), vector( 0,  0, 12)) - vector(2.5,  0,  2.5), 'blue')
    ->object(triangle(vector( 0,  0,  0), vector( 8,  0,  0), vector( 0, -8,  0)),                         'pink')
    ->object(triangle(vector( 0,  0,  0), vector( 0,  0,  8), vector( 0, -8,  0)),                         'orange')
    ->object(cu()*2+vector(3,5,1), 'lightblue')

->done; 

