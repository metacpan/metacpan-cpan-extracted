#!perl -T

use warnings;
use strict;

use Test::More tests => 13;

use lib 'lib';
use Math::Function::Roots qw(bisection epsilon last_iter max_iter);

epsilon( 0 );
is( epsilon(), 0, "epsilon: set/get" );

epsilon( -1 );
is( epsilon(), 0, "epsilon: minimum" );

ok( bisection( sub{ shift() + 1 }, -5, 10 ) eq -1, "bisection: linear equation" );
# is( last_iter(), 54 ); # Unkown depending on architecture
# Root of f(x) = x+1 should be -1 

ok( bisection( sub{ my $x = shift; $x**2 - 25}, -10, -1 ) eq -5, "bisection: negative root of x**2-25");


max_iter( 5 );
is( max_iter(), 5, "max_iter: set/get");
{ 
    $SIG{__WARN__} = sub {};
    bisection( sub{ my $x = shift; $x**2 - 25}, -10, -1 );
    $SIG{__WARN__} = '';
}



is( last_iter(), 5 );

# shouldn't execute with bad a/b
eval { bisection( sub {shift()}, 1, 2 ) };
like( $@, qr/^Bad range/, "bisection: bad range" );

# test finding perfect exit value
is( bisection( sub{ shift() - 1}, 0, 4 ), 1, "bisection: perfect exit");
is( last_iter(), 2, "perfect exit takes 2 iterations");


# Test standard use with normal epsilon
max_iter(50_000);
my $e_test = .0001;
cmp_ok( abs( 
	 bisection( sub{ 2*shift()+2 }, -10, 10, epsilon => $e_test ) 
	 + 1 ), '<=', $e_test, "normal bisection" );
# These two test should have the same answer, testing the two ways
# of setting epsilon, global and local
epsilon( $e_test );
cmp_ok( abs( 
	 bisection( sub{ 2*shift()+2 }, -10, 10 ) 
	 + 1 ), '<=', $e_test, "normal bisection" );


# Same as the above max_iter test, just testing the other
# way max_iter can be set
{ 
    $SIG{__WARN__} = sub {};
    bisection( sub{ my $x = shift; $x**2 - 25}, -10, -1, max_iter => 5 );
    $SIG{__WARN__} = '';
}
is( last_iter(), 5 );

# The global max_iter should not have been touched
is( max_iter(), 50_000, "global max_iter unchanged" );


TODO: {
    local $TODO = "Would like to handle sub references as below with the same prototype as above";

    sub times2{
	2*shift();
    }
    #Need to be commented out because prototype checking happens at compile time
    #is( bisection( \&times2, -5, 5 ), 0, "sub reference test");
    
    my $ref = sub {2*shift()};
    
    #is( bisection( $ref, -5, 5 ), 0, "sub ref 2");
    
    $ref = \&times2;
    
    #is( bisection( $ref, -5, 5 ), 0, "sub ref 3");

};
