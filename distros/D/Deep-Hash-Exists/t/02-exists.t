#!perl -T
use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util;
use Test::More tests => 18;

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

ok( exists( $hash_ref->{'A'} ), q(Test HASH: Key 'A' is exists) );
ok( exists( $hash_ref->{'B'} ), q(Test HASH: Key 'B' is exists) );
ok( Scalar::Util::reftype $hash_ref->{'B'} ne 'HASH', q(Test HASH: Value of key 'B' isn't 'HASH') );
ok( exists( $hash_ref->{'C'}{'one'} ), q(Test HASH: Key 'C'->'one' is exists) );
ok( exists( $hash_ref->{'C'}{$arr_ref} ), q(Test HASH: Key 'C'->$arr_ref is exists) );
ok( ! exists( $hash_ref->{'C'}{'three'} ), q(Test HASH: Key 'C'->'three' isn't exists) );
ok( ! exists( $hash_ref->{'C'}{'three'}{'PI'}{'0'} ), q(Test HASH: Key 'C'->'three'->'PI'->'0' isn't exists) );
ok( exists( $hash_ref->{'C'}{'three'} ), q(Test HASH: Key 'C'->'three' now exists) );
like( Dumper( $hash_ref ), qr(PI), q(Test HASH: Subroutine create new keys) );

my $obj = bless {
            A => 'one',
            B => [ 'one', 'two' ],
            C => { 
                'one' => 1, 
                'two' => 2, 
                $arr_ref => 3
            },
        }, "AnySuperClass::Test";

ok( exists( $obj->{'A'} ), q(Test object: Key 'A' is exists) );
ok( exists( $obj->{'B'} ), q(Test object: Key 'B' is exists) );
ok( Scalar::Util::reftype $obj->{'B'} ne 'HASH', q(Test object: Value of key 'B' isn't 'HASH') );
ok( exists( $obj->{'C'}{'one'} ), q(Test object: Key 'C'->'one' is exists) );
ok( exists( $obj->{'C'}{$arr_ref} ), q(Test object: Key 'C'->$arr_ref is exists) );
ok( ! exists( $obj->{'C'}{'three'} ), q(Test object: Key 'C'->'three' isn't exists) );
ok( ! exists( $obj->{'C'}{'three'}{'PI'}{'0'} ), q(Test object: Key 'C'->'three'->'PI'->'0' isn't exists) );
ok( exists( $obj->{'C'}{'three'} ), q(Test object: Key 'C'->'three' now exists) );
like( Dumper( $obj ), qr(PI), q(Test object: Subroutine create new keys) );
