# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl MPGA.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 14;
BEGIN { use_ok('MPGA') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


is_deeply( [ chunk() ], [], 'test chunk()' );

my $reverse_flow = undef;
is_deeply( [ chunk( $reverse_flow ) ], [], 'test chunk( undef )' );

$reverse_flow = 'aaa';
is_deeply( [ chunk( $reverse_flow ) ], [], 'test chunk( scalar )' );

my @reverse_flow = ( 1, 2, 'aaa' );
is_deeply( [ chunk( @reverse_flow ) ], [], 'test chunk( array )' );

my %reverse_flow = ( 1 => 2, 'aaa' => 'bbb' );
is_deeply( [ chunk( %reverse_flow ) ], [], 'test chunk( hash )' );

$reverse_flow = { 1 => 2, 'aaa' => 'bbb' };
is_deeply( [ chunk( $reverse_flow ) ], [], 'test chunk( \hash )' );

$reverse_flow = [];
is_deeply( [ chunk( $reverse_flow ) ], [undef, undef], 'test chunk( [] )' );

$reverse_flow = [ 1 ];
is_deeply( [ chunk( $reverse_flow ) ], [undef, [1]], 'test chunk( [scalar] )' );

$reverse_flow = [ 3, 2, 1 ];
is_deeply( [ chunk( $reverse_flow ) ], [undef, [1, 2, 3]], 'test chunk( [scalar, scalar, scalar] )' );

$reverse_flow = [ 1, \&fun1 ];
is_deeply( [ chunk( $reverse_flow ) ] , [\&fun1, undef], 'test chunk( [scalar, fun] )' );
is_deeply( $reverse_flow , [ 1 ] , 'test flow after chunk( [scalar, fun] )' );

$reverse_flow = [ \&fun1, 3, 2, 1 ];
is_deeply( [ chunk( $reverse_flow ) ], [\&fun1, [1, 2, 3]], 'test chunk( [fun, @scalar] )' );

$reverse_flow = [ \&fun1, 5, 4, \&fun1, 3, 2, 1 ];
chunk( $reverse_flow );
is_deeply( $reverse_flow , [ \&fun1, 5, 4 ] , 'test flow after chunk( [fun, @scalar] )' );




sub fun1 {
  my ( $self, $args, $flow ) = @_;
  #my $obj = shift @$args;

  return 'ccc';
}

