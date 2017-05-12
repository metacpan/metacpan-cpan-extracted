#!/usr/bin/env perl 
use Test::More tests => 92;
use warnings;
use strict;

my $idx=0;

BEGIN {
    use_ok('MFor');
}

$idx=0;
my @lev1 = qw(q w e r);
MFor->it( @lev1 )->do(sub {
    is( $lev1[ $idx ] , $_[0] , $_[0] );
    $idx++;
});

$idx=0;
@lev1 = qw(1 2 3 4);
my @lev2 = qw(a s d f);

MFor->it( qw(1 2 3 4) )->it( qw(a s d f) )->do(sub {
    is( $lev1[ $idx / 4 ] , $_[0] , 'index 0 for @_ ' . $_[0] );
    is( $lev2[ $idx % 4 ] , $_[1] , 'index 1 for @_ ' . $_[1] );
    $idx++;
});
is( $idx  , 16 , 'get 16 times');

diag 'test for do method with it method';

$idx = 1;
MFor->it({ A => [ qw(1 2 3 4) ] })->do(sub {
        # is( $_[0] , 'A' );
        is( ref $_[0] , 'HASH' , 'get ref hash' );
        my $args = shift;

        my ($key) = keys %$args;
        my ($value) = values %$args;
        is( $key , 'A' , 'right key A' );
        is( $value, $idx++ , 'right value'  );
});


diag 'test for when method';

MFor->it({ A => [ qw(1 2 3 4) ] })->when( qw/A == 1/ )->do(sub {
        is( $_[0]->{A} , 1 , 'when A == 1' );
});

$idx=1;
MFor->it({ A => [ qw(1 2 3 4) ] })->when( qw/A < 3/ )->do(sub {
        ok( $_[0]->{A} < 3 , 'when A < 3' );
        is( $_[0]->{A} ,  $idx , 'get idx: ' . $idx );
        $idx++;
});


diag 'test for two layer hash ref';

my @hash_a = qw(1 2 3 4);
my @hash_b = qw(a b c d);
$idx = 0;
MFor->it({ A => [ @hash_a ] })->it({ B => [ @hash_b ] })->do(sub {
      is( $hash_a[  $idx / 4 ] , $_[0]->{A} ,'get '. $_[0]->{A} );
      is( $hash_b[  $idx % 4 ] , $_[0]->{B} ,'get '. $_[0]->{B} );
      $idx++;
});

$idx = 0;
MFor->it({ A => [ @hash_a ] })->it({ B => [ @hash_b ] })->when( qw/A == 3/  )->do(sub {
      is( $_[0]->{A} , 3 , 'get A == 3');
      $idx++;
});
is( $idx , 4 , 'get 4 times' );


