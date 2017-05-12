#!perl -T

use warnings;
use strict;

use Test::More tests => 2;

use lib 'lib';
use Math::Function::Roots qw(fixed_point epsilon last_iter max_iter);

epsilon( 0 );

ok( fixed_point( sub { -.5*shift() + 1.5 }, 10 ) eq 1, "fixed-point of f(x)=-.5+1.5 found in ".last_iter() );
# f(x) = -.5x + 1.5 has a fixed point at 1

max_iter( 5 );
{ $SIG{__WARN__} = sub {};
  fixed_point( sub{ -.5*shift() + 1.5 }, 10 ) ;
}
is( last_iter(), 5, "Number of iteration run" );
