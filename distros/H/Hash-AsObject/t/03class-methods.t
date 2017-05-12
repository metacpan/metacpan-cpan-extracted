#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'tests' => 5;

use_ok( 'Hash::AsObject' );

eval { Hash::AsObject->foo };
like( $@, qr/Can't invoke class method/, 'forbidden class method call' );

eval { Hash::AsObject->import };
is( $@, '', 'allowed class method call' );

eval {
    my $htemp = Hash::AsObject->new;
    eval { $htemp->DESTROY('all monsters') };
    is( $@, '', '$obj->DESTROY($foo)' );
    eval { $htemp->DESTROY };
    is( $@, '', '$obj->DESTROY'       );
};
