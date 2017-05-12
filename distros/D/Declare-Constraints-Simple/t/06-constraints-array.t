#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use Declare::Constraints::Simple
    Only => qw( HasArraySize OnArrayElements OnEvenElements OnOddElements
                HasLength IsInt Matches And);

my @test_sets = (
    [HasArraySize,      undef,          0,  'HasArraySize undef'],
    [HasArraySize,      'foo',          0,  'HasArraySize string'],
    [HasArraySize,      [],             0,  'HasArraySize default empty'],
    [HasArraySize,      [1],            1,  'HasArraySize default one element'],
    [HasArraySize,      [1,2],          1,  'HasArraySize default two elements'],
    [HasArraySize(2),   [1],            0,  'HasArraySize(2) one element'],
    [HasArraySize(2),   [1,2],          1,  'HasArraySize(2) two elements'],
    [HasArraySize(2),   [1,2,3],        1,  'HasArraySize(2) three elements'],
    [HasArraySize(2,3), [1,2],          1,  'HasArraySize(2,3) two elements'],
    [HasArraySize(2,3), [1,2,3],        1,  'HasArraySize(2,3) three elements'],
    [HasArraySize(2,3), [1,2,3,4],      0,  'HasArraySize(2,3) four elements'],

    [OnArrayElements(0, IsInt, 1, HasLength),   [1,'2'],    1,  'OnArrayElements two true'],
    [OnArrayElements(0, IsInt, 1, HasLength),   ['f'],      0,  'OnArrayElements only one and false'],
    [OnArrayElements(0, IsInt, 1, HasLength),   [],         1,  'OnArrayElements true on empty list'],
    [OnArrayElements(0, IsInt, 1, HasLength),   [2],        1,  'OnArrayElements one true'],
    [OnArrayElements(0, IsInt, 1, HasLength),   [undef],    0,  'OnArrayElements undef value'],
    [OnArrayElements(0, IsInt, 1, HasLength),   undef,      0,  'OnArrayElements undef'],
    [OnArrayElements(0, IsInt, 1, HasLength),   "foo",      0,  'OnArrayElements string'],

    [OnEvenElements(IsInt),     undef,      0,  'OnEvenElements undef'],
    [OnEvenElements(IsInt),     "foo",      0,  'OnEvenElements string'],
    [OnEvenElements(IsInt),     [],         1,  'OnEvenElements true on empty'],
    [OnEvenElements(IsInt),     [1..3],     1,  'OnEvenElements true'],
    [OnEvenElements(IsInt),     ['a',1],    0,  'OnEvenElements false, odd true'],
    [OnEvenElements(IsInt),     [1,'a'],    1,  'OnEvenElements true, odd false'],

    [OnOddElements(IsInt),      undef,      0,  'OnOddElements undef'],
    [OnOddElements(IsInt),      "foo",      0,  'OnOddElements string'],
    [OnOddElements(IsInt),      [],         1,  'OnOddElements true on empty'],
    [OnOddElements(IsInt),      [1..3],     1,  'OnOddElements true'],
    [OnOddElements(IsInt),      ['a',1],    1,  'OnOddElements true, odd false'],
    [OnOddElements(IsInt),      [1,'a'],    0,  'OnOddElements false, odd true'],
    [And(OnEvenElements(IsInt),OnOddElements(Matches(qr/foo/))),
                                [1,"foob"], 1,  'OnOddElements + OnEvenElements true'],
    [And(OnEvenElements(IsInt),OnOddElements(Matches(qr/foo/))),
                                ["foob",2], 0,  'OnOddElements + OnEvenElements false'],
);

plan tests => scalar(@test_sets);

for (@test_sets) {
    my ($check, $value, $expect, $title) = @$_;
    my $result = $check->($value);
    is(($result ? 1 : 0), $expect, $title);
}
