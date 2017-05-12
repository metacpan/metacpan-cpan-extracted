#!perl -w
#______________________________________________________________________
# Test drawing.
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

use Math::Zap::Draw;
use Math::Zap::Cube unit=>'cu';
use Math::Zap::Triangle;
use Math::Zap::Vector;

use Test::Simple tests=>1;

#_ Draw _______________________________________________________________
# Draw this set of objects.
#______________________________________________________________________

$l = 
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

->print;

$L = <<'END'; 
#!perl -w
use Math::Zap::Draw;
use Math::Zap::Triangle;
use Math::Zap::Vector;

draw
->from    (vector(10, 10, 10))
->to      (vector(0, 0, 0))
->horizon (vector(1, 0.5, 0))
->light   (vector(20, 30, -20))
  ->object(triangle(vector(0, 0, 0), vector(8, 0, 0), vector(0, 8, 0)), 'red')
  ->object(triangle(vector(0, 0, 0), vector(0, 0, 8), vector(0, 8, 0)), 'green')
  ->object(triangle(vector(-2.5, 0, -2.5), vector(9.5, 0, -2.5), vector(-2.5, 0, 9.5)), 'blue')
  ->object(triangle(vector(0, 0, 0), vector(8, 0, 0), vector(0, -8, 0)), 'pink')
  ->object(triangle(vector(0, 0, 0), vector(0, 0, 8), vector(0, -8, 0)), 'orange')
  ->object(triangle(vector(3, 5, 1), vector(5, 5, 1), vector(3, 7, 1)), 'lightblue')
  ->object(triangle(vector(5, 7, 1), vector(5, 5, 1), vector(3, 7, 1)), 'lightblue')
  ->object(triangle(vector(3, 5, 3), vector(5, 5, 3), vector(3, 7, 3)), 'lightblue')
  ->object(triangle(vector(5, 7, 3), vector(5, 5, 3), vector(3, 7, 3)), 'lightblue')
  ->object(triangle(vector(3, 5, 1), vector(3, 7, 1), vector(3, 5, 3)), 'lightblue')
  ->object(triangle(vector(3, 7, 3), vector(3, 7, 1), vector(3, 5, 3)), 'lightblue')
  ->object(triangle(vector(5, 5, 1), vector(5, 7, 1), vector(5, 5, 3)), 'lightblue')
  ->object(triangle(vector(5, 7, 3), vector(5, 7, 1), vector(5, 5, 3)), 'lightblue')
  ->object(triangle(vector(3, 5, 1), vector(3, 5, 3), vector(5, 5, 1)), 'lightblue')
  ->object(triangle(vector(5, 5, 3), vector(3, 5, 3), vector(5, 5, 1)), 'lightblue')
  ->object(triangle(vector(3, 7, 1), vector(3, 7, 3), vector(5, 7, 1)), 'lightblue')
  ->object(triangle(vector(5, 7, 3), vector(3, 7, 3), vector(5, 7, 1)), 'lightblue')
->done;
END

ok($l eq $L);
