#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'tests' => 3;
use Lib::PWQuality;

my $pwq = Lib::PWQuality->new();
isa_ok( $pwq, 'Lib::PWQuality' );
can_ok( $pwq, 'generate' );

my $pass = $pwq->generate(15);

ok(
    defined $pass && length $pass,
    "Generating password with entropy of 15 bits ($pass)",
);

