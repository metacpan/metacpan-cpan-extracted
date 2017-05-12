#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use Hash::Dispatch;

my ( $dispatch, $result );

$dispatch = Hash::Dispatch->dispatch(
    '' => sub {
        return '';
    },

    'blank' => '',

    'result' => sub {
        return 'result';
    },

    qr/^(re)/ => sub {
        return 're';
    },

    'result0' => 'result',

    'tluser' => 'result',

    'loop' => 'loop0',
    'loop0' => 'loop1',
    'loop1' => 'loop',

    'selfloop' => 'selfloop',

    404 => undef,
);

ok( $dispatch );

$result = $dispatch->dispatch( '' );
is( $result->value->(), '' );

$result = $dispatch->dispatch( 'blank' );
is( $result->value->(), '' );

ok( !$dispatch->dispatch( 'xyzzy' ) );

$result = $dispatch->dispatch( 'result' );
is( $result->value->(), 'result' );

$result = $dispatch->dispatch( 're' );
is( $result->value->(), 're' );
cmp_deeply( [ $result->captured ], [ 're' ] );

$result = $dispatch->dispatch( 'regularexpression' );
is( $result->value->(), 're' );
cmp_deeply( [ $result->captured ], [ 're' ] );

$result = $dispatch->dispatch( 'result0' );
is( $result->value->(), 're' );
cmp_deeply( [ $result->captured ], [ 're' ] );

$result = $dispatch->dispatch( 'tluser' );
is( $result->value->(), 'result' );

throws_ok { $dispatch->dispatch( 'loop' ) } qr/^\Q*** Dispatch loop detected on query (loop => loop1)\E/;

throws_ok { $dispatch->dispatch( 'selfloop' ) } qr/^\Q*** Dispatch loop detected on query (selfloop => selfloop)\E/;

ok( !$dispatch->dispatch( 404 ) );

done_testing;

