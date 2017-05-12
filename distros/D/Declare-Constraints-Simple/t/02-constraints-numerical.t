#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use Declare::Constraints::Simple
    only => qw(IsNumber IsInt);

my @test_sets = (
    [IsNumber,  undef,  0,  'IsNumber undef'],
    [IsNumber,  "foo",  0,  'IsNumber string'],
    [IsNumber,  [],     0,  'IsNumber array ref'],
    [IsNumber,  23,     1,  'IsNumber 23'],
    [IsNumber,  0xDEAD, 1,  'IsNumber 0xDEAD'],
    [IsNumber,  "23",   1,  'IsNumber "23"'],

    [IsInt,     undef,  0,  'IsInt undef'],
    [IsInt,     "foo",  0,  'IsInt string'],
    [IsInt,     [],     0,  'IsInt array ref'],
    [IsInt,     23,     1,  'IsInt 23'],
    [IsInt,     -23,    1,  'IsInt -23'],
    [IsInt,     11.5,   0,  'IsInt float'],
    [IsInt,     0xDEAD, 1,  'IsInt 0xDEAD (converted)'],
    [IsInt,     "1b2",  0,  'IsInt string between nums'],
    [IsInt,     "b2c",  0,  'IsInt num between strings'],
);

plan tests => scalar(@test_sets);

for (@test_sets) {
    my ($check, $value, $expect, $title) = @$_;
    my $result = $check->($value);
    is(($result ? 1 : 0), $expect, $title);
}
