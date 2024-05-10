#! perl

# Version 1.02 (and maybe earlier) didn't return the correct value the
# first time an object at a lower level was returned for an immutable,
# recursive, copied wrapper.

use v5.10;
use Test2::V0;
use Scalar::Util 'refaddr';
use Hash::Wrap {
    -immutable => 1,
    -recurse   => -1,
    -copy      => !!1,
};


my $obj     = wrap_hash( { a => { b => { c => 1 } } } );
my @refaddr = map { refaddr( $_ ) // 'none' } (
    #
    $obj,             # [0]
    $obj->a,          # [1]
    $obj->a,          # [2]
    $obj->a->b,       # [3]
    $obj->a->b,       # [4]
    $obj->a->b->c,    # [5]
);


isnt( $refaddr[0], $refaddr[1], 'obj != obj->a(1)' );

is( $refaddr[1], $refaddr[2], 'obj->a(1) == obj->a(2)' );
isnt( $refaddr[2], $refaddr[3], 'obj->a(1) != obj->a->b(1)' );
is( $refaddr[3], $refaddr[4], 'obj->a->b(1) == obj->a->b(2)' );
isnt( $refaddr[4], $refaddr[5], 'obj->a->b(2) != obj->a->b->c' );

done_testing;
