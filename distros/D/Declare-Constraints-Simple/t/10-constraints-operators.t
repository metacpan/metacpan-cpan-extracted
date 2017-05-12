#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use Declare::Constraints::Simple
    only => qw(And Or XOr Not Matches IsInt IsTrue);

my @test_sets = (
    [Not,                               "foo",      1,  'Not without arg always true'],
    [Not(IsTrue),                       0,          1,  'Not is true'],
    [Not(Not(IsTrue)),                  23,         1,  'Not doubled neutralizes'],
    [Not(IsTrue),                       23,         0,  'Not turns true to false'],

    [XOr(IsTrue,IsInt),                 23,         0,  'XOr false on two true'],
    [XOr(IsTrue,IsInt,Matches(qr//)),   "",         1,  'XOr true on one true'],
    [XOr(IsTrue,IsInt),                 "",         0,  'XOr false on two false'],
    [XOr,                               23,         0,  'XOr empty is false'],

    [Or(IsTrue,IsInt,Matches(qr//)),    "",         1,  'Or true on one true'],
    [Or(IsTrue,IsInt,Matches(qr/x/)),   "x",        1,  'Or true on two true'],
    [Or(IsTrue,IsInt,Matches(qr/x/)),   "",         0,  'Or false on all false'],
    [Or,                                23,         0,  'Or empty is false'],

    [And(IsTrue,IsInt),                 "foo",      0,  'And one true'],
    [And(IsTrue,IsInt),                 23,         1,  'And both true'],
    [And(IsTrue,IsInt),                 "",         0,  'And none true'],
    [And,                               23,         1,  'Or empty is true'],
);

plan tests => scalar(@test_sets);

for (@test_sets) {
    my ($check, $value, $expect, $title) = @$_;
    my $result = $check->($value);
    is(($result ? 1 : 0), $expect, $title);
}
