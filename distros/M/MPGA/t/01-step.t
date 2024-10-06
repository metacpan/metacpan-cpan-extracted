# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl MPGA.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 21;
BEGIN { use_ok('MPGA') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


is_deeply( [ step() ], [], 'test step()' );

my $reverse_flow = undef;
is_deeply( [ step( $reverse_flow ) ], [], 'test step( undef )' );

$reverse_flow = 'aaa';
step( $reverse_flow );
is_deeply( [ $reverse_flow ], ['aaa'], 'test step( scalar )' );

$reverse_flow = \'aaa';
step( $reverse_flow );
is_deeply( [ $reverse_flow ], [\'aaa'], 'test step( \scalar )' );

my %reverse_flow = ( 1 => 2, 'aaa' => 'bbb' );
step( %reverse_flow );
ok( eq_hash( \%reverse_flow, { 1 => 2, 'aaa' => 'bbb' } ) , 'test step( hash )' );

$reverse_flow = { 1 => 2, 'aaa' => 'bbb' };
step( $reverse_flow );
ok( eq_hash( $reverse_flow, { 1 => 2, 'aaa' => 'bbb' } ) , 'test step( hash )' );

my @reverse_flow = ( 1, 2, 'aaa' );
step( @reverse_flow );
is_deeply( [ @reverse_flow ], [1, 2, 'aaa'], 'test step( array )' );

$reverse_flow = [ 1, 2, 'aaa' ];
step( $reverse_flow );
is_deeply( $reverse_flow, [], 'test step( \array )' );

$reverse_flow = [ \&fun_return, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, [3, 2, 1], 'test step( fun_return, args )' );

$reverse_flow = [ 'ccc', 'bbb', 'aaa', \&fun_return, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, ['ccc', 'bbb', 'aaa', 3, 2, 1], 'test step( fun_return, args )' );

$reverse_flow = [ \&fun_return_undef, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, [3, 2, 1], 'test step( fun_return_undef, args )' );

$reverse_flow = [ 'ccc', 'bbb', 'aaa', \&fun_return_undef, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, ['ccc', 'bbb', 'aaa', 3, 2, 1], 'test step( fun_return_undef, args )' );

$reverse_flow = [ 'ccc', 'bbb', 'aaa', \&fun_return_scalar, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, ['ccc', 'bbb', 'aaa', 'xxx', 3, 2, 1], 'test step( fun_return_scalar, args )' );

$reverse_flow = [ 'ccc', 'bbb', 'aaa', \&fun_return_scalar_ref, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, ['ccc', 'bbb', 'aaa', \'xxx', 3, 2, 1], 'test step( fun_return_scalar_ref, args )' );

$reverse_flow = [ 'ccc', 'bbb', 'aaa', \&fun_return_hash, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, ['ccc', 'bbb', 'aaa', 1, 3, 2, 1], 'test step( fun_return_hash, args )' );

$reverse_flow = [ 'ccc', 'bbb', 'aaa', \&fun_return_hash_ref, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, ['ccc', 'bbb', 'aaa', { 'xxx' => 'yyy' }, 3, 2, 1], 'test step( fun_return_hash_ref, args )' );

$reverse_flow = [ 'ccc', 'bbb', 'aaa', \&fun_return_array, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, ['ccc', 'bbb', 'aaa', 3, 3, 2, 1], 'test step( fun_return_array, args )' );

$reverse_flow = [ 'ccc', 'bbb', 'aaa', \&fun_return_array_ref, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, ['ccc', 'bbb', 'aaa', 'zzz', 'yyy', 'xxx', 3, 2, 1], 'test step( fun_return_array_ref, args )' );

$reverse_flow = [ 'ccc', 'bbb', 'aaa', \&fun_modifying_flow, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, ['xxx', 'yyy', 'zzz', 3, 2, 1], 'test step( fun_modifying_flow, args )' );

$reverse_flow = [ 'ccc', 'bbb', 'aaa', \&fun_clear_flow, 3, 2, 1 ];
step( $reverse_flow );
is_deeply( $reverse_flow, [3, 2, 1], 'test step( fun_clear_flow, args )' );




sub fun_return {
  my ( $self, $args, $flow ) = @_;

  return;
}


sub fun_return_undef {
  my ( $self, $args, $flow ) = @_;

  return undef;
}


sub fun_return_scalar {
  my ( $self, $args, $flow ) = @_;

  my $str = 'xxx';

  return $str;
}


sub fun_return_scalar_ref {
  my ( $self, $args, $flow ) = @_;

  my $str = 'xxx';

  return \$str;
}


sub fun_return_hash {
  my ( $self, $args, $flow ) = @_;

  my %h = ( 'xxx' => 'yyy' );

  return %h;
}


sub fun_return_hash_ref {
  my ( $self, $args, $flow ) = @_;

  my $h = { 'xxx' => 'yyy' };

  return $h;
}


sub fun_return_array {
  my ( $self, $args, $flow ) = @_;

  my @arr = ('xxx', 'yyy', 'zzz');

  return @arr;
}


sub fun_return_array_ref {
  my ( $self, $args, $flow ) = @_;

  my $arr = ['xxx', 'yyy', 'zzz'];

  return $arr;
}


sub fun_modifying_flow {
  my ( $self, $args, $flow ) = @_;

  @$flow = ('xxx', 'yyy', 'zzz');

  return;
}


sub fun_clear_flow {
  my ( $self, $args, $flow ) = @_;

  @$flow = ();

  return;
}


