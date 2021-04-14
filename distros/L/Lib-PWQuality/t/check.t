#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'tests' => 4;
use Lib::PWQuality;

my $pwq = Lib::PWQuality->new();
isa_ok( $pwq, 'Lib::PWQuality' );
can_ok( $pwq, 'check' );

is_deeply(
    $pwq->check('kewlpass'),
    { 'status' => 'SUCCESS', 'score' => 12 },
    'Checking crappy password: kewlpass (score: 12)',
);

is_deeply(
    $pwq->check( 'foo', 'foo' ),
    { 'status' => 'SAME_PASSWORD', 'score' => -1 },
    'Checking same old and new passwords (error: SAME_PASSWORD)',
);

