#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use Declare::Constraints::Simple
    only => qw(ReturnTrue ReturnFalse);

my @test_sets = (
    [ReturnTrue,        undef,      1,  'ReturnTrue undef'],
    [ReturnTrue,        12,         1,  'ReturnTrue number'],
    [ReturnTrue,        [],         1,  'ReturnTrue array ref'],
    
    [ReturnFalse('x'),  undef,      0,  'ReturnFalse undef'],
    [ReturnFalse('x'),  [],         0,  'ReturnFalse array ref'],
);

plan tests => scalar(@test_sets);

for (@test_sets) {
    my ($check, $value, $expect, $title) = @$_;
    my $result = $check->($value);
    is(($result ? 1 : 0), $expect, $title);
}
