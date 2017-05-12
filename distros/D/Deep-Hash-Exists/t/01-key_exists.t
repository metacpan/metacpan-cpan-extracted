#!perl -T
use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 18;

use Deep::Hash::Exists qw( key_exists );

my $arr_ref = [];
my $hash_ref = {
        A => 'one',
        B => [ 'one', 'two' ],
        C => { 
            'one' => 1, 
            'two' => 2, 
            $arr_ref => 3
        },
};

ok( key_exists( $hash_ref, [ 'A' ] ), q(Test HASH: Key 'A' is exists) );
ok( key_exists( $hash_ref, [ 'B' ] ), q(Test HASH: Key 'B' is exists) );
ok( ! key_exists( $hash_ref, [ 'B', '0' ] ), q(Test HASH: Key 'B'->'0' isn't exists) );
ok( key_exists( $hash_ref, [ 'C', 'one' ] ), q(Test HASH: Key 'C'->'one' is exists) );
ok( key_exists( $hash_ref, [ 'C', $arr_ref ] ), q(Test HASH: Key 'C'->$arr_ref is exists) );
ok( ! key_exists( $hash_ref, [ 'C', 'three' ] ), q(Test HASH: Key 'C'->'three' isn't exists) );
ok( ! key_exists( $hash_ref, [ 'C', 'three', 'PI', '0' ] ), q(Test HASH: Key 'C'->'three'->'PI'->'0' isn't exists) );
ok( ! key_exists( $hash_ref, [ 'C', 'three' ] ), q(Test HASH: Key 'C'->'three' still isn't exists) );
unlike( Dumper( $hash_ref ), qr(PI), q(Test HASH: Subroutine does not create new keys) );

my $obj = bless {%$hash_ref}, "AnySuperClass::Test";

ok( key_exists( $obj, [ 'A' ] ), q(Test object: Key 'A' is exists) );
ok( key_exists( $obj, [ 'B' ] ), q(Test object: Key 'B' is exists) );
ok( ! key_exists( $obj, [ 'B', '0' ] ), q(Test object: Key 'B'->'0' isn't exists) );
ok( key_exists( $obj, [ 'C', 'one' ] ), q(Test object: Key 'C'->'one' is exists) );
ok( key_exists( $obj, [ 'C', $arr_ref ] ), q(Test object: Key 'C'->$arr_ref is exists) );
ok( ! key_exists( $obj, [ 'C', 'three' ] ), q(Test object: Key 'C'->'three' isn't exists) );
ok( ! key_exists( $obj, [ 'C', 'three', 'PI', '0' ] ), q(Test object: Key 'C'->'three'->'PI'->'0' isn't exists) );
ok( ! key_exists( $obj, [ 'C', 'three' ] ), q(Test object: Key 'C'->'three' still isn't exists) );
unlike( Dumper( $obj ), qr(PI), q(Test object: Subroutine does not create new keys) );
