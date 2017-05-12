#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use Declare::Constraints::Simple
    only => qw(
                IsRefType IsScalarRef IsCodeRef IsArrayRef IsHashRef IsRegex 
                IsInt Matches
              );

my @test_sets = (
    [IsRefType(qw(CODE ARRAY)),         [],                 1,  'IsRefType array true'],
    [IsRefType(qw(CODE ARRAY)),         sub {},             1,  'IsRefType code true'],
    [IsRefType(qw(CODE HASH)),          [],                 0,  'IsRefType array false'],
    [IsRefType(qw(CODE ARRAY)),         "foo",              0,  'IsRefType no ref'],
    [IsRefType(qw(CODE ARRAY)),         undef,              0,  'IsRefType undef'],
    [IsRefType(qw(Regexp)),             qr/x/,              1,  'IsRefType regex true'],
    [IsRefType(qw(Foo)),                bless({}, 'Foo'),   1,  'IsRefType blessed'],

    [IsScalarRef,                       "foo",              0,  'IsScalarRef scalar false'],
    [IsScalarRef,                       \"foo",             1,  'IsScalarRef true'],
    [IsScalarRef,                       {},                 0,  'IsScalarRef hash ref'],
    [IsScalarRef,                       undef,              0,  'IsScalarRef undef'],
    [IsScalarRef(IsInt),                "foo",              0,  'IsScalarRef nested string false'],
    [IsScalarRef(IsInt),                23,                 0,  'IsScalarRef nested number false'],
    [IsScalarRef(IsInt),                \"foo",             0,  'IsScalarRef nested ref false'],
    [IsScalarRef(IsInt),                \"12",              1,  'IsScalarRef nested int true'],
    [IsScalarRef(IsInt),                undef,              0,  'IsScalarRef nested undef'],
    [IsScalarRef(IsInt),                \undef,             0,  'IsScalarRef nested undef ref'],
    [IsScalarRef(IsInt,Matches(qr/2/)), \"12",              1,  'IsScalarRef nested two both'],
    [IsScalarRef(IsInt,Matches(qr/2/)), \"33",              0,  'IsScalarRef nested two one false'],
    [IsScalarRef(IsInt,Matches(qr/2/)), \"foo",             0,  'IsScalarRef nested two both false'],
    [IsScalarRef(IsInt,Matches(qr/2/)), undef,              0,  'IsScalarRef nested two undef'],
    [IsScalarRef(IsInt,Matches(qr/2/)), \undef,             0,  'IsScalarRef nested two undef ref'],
   
    [IsCodeRef,                         undef,              0,  'IsCodeRef undef'],
    [IsCodeRef,                         [],                 0,  'IsCodeRef array ref'],
    [IsCodeRef,                         "foo",              0,  'IsCodeRef string'],
    [IsCodeRef,                         sub {},             1,  'IsCodeRef true'],

    [IsArrayRef,                        undef,              0,  'IsArrayRef undef'],
    [IsArrayRef,                        {},                 0,  'IsArrayRef hash ref'],
    [IsArrayRef,                        "foo",              0,  'IsArrayRef string'],
    [IsArrayRef,                        [],                 1,  'IsArrayRef true'],
    [IsArrayRef(IsInt),                 [1..3],             1,  'IsArrayRef of IsInt true'],
    [IsArrayRef(IsInt),                 undef,              0,  'IsArrayRef of IsInt undef'],
    [IsArrayRef(IsInt),                 [qw(1 2 foo 3)],    0,  'IsArrayRef of IsInt one false'],
    [IsArrayRef(IsInt),                 [qw(a b c)],        0,  'IsArrayRef of IsInt all false'],
    [IsArrayRef(IsArrayRef),            [[],[]],            1,  'IsArrayRef of IsArrayRef true'],
    [IsArrayRef(IsInt),                 [undef],            0,  'IsArrayRef of IsInt undef in array'],

    [IsHashRef,                         undef,              0,  'IsHashRef undef'],
    [IsHashRef,                         "foo",              0,  'IsHashRef string'],
    [IsHashRef,                         {},                 1,  'IsHashRef true'],
    [IsHashRef(-values => IsInt),       {foo => "bar"},     0,  'IsHashRef IsInt vals false'],
    [IsHashRef(-values => IsInt),       {foo => 23},        1,  'IsHashRef IsInt vals true'],
    [IsHashRef(-values => [IsInt]),     {foo => 23},        1,  'IsHashRef IsInt vals list true'],
    [IsHashRef(-keys => IsInt),         {foo => "bar"},     0,  'IsHashRef IsInt keys false'],
    [IsHashRef(-keys => IsInt),         {123 => "bar"},     1,  'IsHashRef IsInt keys true'],
    [IsHashRef(-keys => [IsInt]),       {123 => "bar"},     1,  'IsHashRef IsInt keys list true'],

    [IsRegex,                           undef,              0,  'IsRegex undef'],
    [IsRegex,                           "foo",              0,  'IsRegex string'],
    [IsRegex,                           [],                 0,  'IsRegex array ref'],
    [IsRegex,                           qr/foo/,            1,  'IsRegex true'],
);

plan tests => scalar(@test_sets);

for (@test_sets) {
    my ($check, $value, $expect, $title) = @$_;
    my $result = $check->($value);
    is(($result ? 1 : 0), $expect, $title);
}
