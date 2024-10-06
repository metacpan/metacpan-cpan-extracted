# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl MPGA.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('MPGA') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


is_deeply( [ flow() ], [], 'test flow()' );

my $flow = undef;
is_deeply( [ flow( $flow ) ], [], 'test flow( undef )' );

$flow = 'aaa';
flow( $flow );
is_deeply( [ $flow ], ['aaa'], 'test flow( scalar )' );

$flow = \'aaa';
flow( $flow );
is_deeply( [ $flow ], [\'aaa'], 'test flow( \scalar )' );

my %flow = ( 1 => 2, 'aaa' => 'bbb' );
flow( %flow );
ok( eq_hash( \%flow, { 1 => 2, 'aaa' => 'bbb' } ) , 'test flow( hash )' );

$flow = { 1 => 2, 'aaa' => 'bbb' };
flow( $flow );
ok( eq_hash( $flow, { 1 => 2, 'aaa' => 'bbb' } ) , 'test flow( hash )' );

my @flow = ( 1, 2, 'aaa' );
flow( @flow );
is_deeply( [ @flow ], [1, 2, 'aaa'], 'test flow( array )' );

$flow = [ 1, 2, 'aaa' ];
flow( $flow );
is_deeply( $flow, [], 'test flow( \array )' );

my $arg = [];
$flow = [ $arg, \&fun1, 3, 2, 1 ];
flow( $flow );
is_deeply( $flow, [], 'test flow( fun_return, args )' );
is_deeply( $arg, ['fun1', 1, 2, 3], 'test flow( fun1, args )' );

$arg = {};
$flow = [ $arg, \&fun2, \&fun3 ];
flow( $flow );
is_deeply( $flow, [], 'test flow( fun2, fun3)' );
ok( eq_hash( $arg, { 'fun2' => [\&fun3], 'fun3' => [] } ) , 'test flow( hash )' );



sub fun1 {
  my ( $self, $args, $flow ) = @_;
  my $arg = shift @$args;

  # изменяю аргумент функции
  @$arg = ( 'fun1', @$flow );

  return ['aaa', 'bbb'];
}

sub fun2 {
  my ( $self, $args, $flow ) = @_;
  my $arg = shift @$args;

  # изменяю аргумент функции
  $arg->{fun2} = [ @$flow ];

  return [$arg, 'aaa', 'bbb'];
}

sub fun3 {
  my ( $self, $args, $flow ) = @_;
  my $arg = shift @$args;

  # изменяю аргумент функции
  $arg->{fun3} = [ @$flow ];

  return ['xxx', 'yyy'];
}


