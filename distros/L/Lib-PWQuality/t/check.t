#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'tests' => 5;
use Lib::PWQuality;

my $pwq = Lib::PWQuality->new();
isa_ok( $pwq, 'Lib::PWQuality' );
can_ok( $pwq, 'check' );

my $res = $pwq->check('kewlpass');
my $score = delete $res->{'score'};

is_deeply(
    $res,
    { 'status' => 'SUCCESS' },
    'Successfully Checked crappy password: kewlpass',
);

ok(
    $score < 15,
    "Score is under 15 ($score)",
);

is_deeply(
    $pwq->check( 'foo', 'foo' ),
    { 'status' => 'SAME_PASSWORD', 'score' => -1 },
    'Checking same old and new passwords (error: SAME_PASSWORD)',
);

