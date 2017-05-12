#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use Declare::Constraints::Simple
    only => qw(Matches IsDefined HasLength IsOneOf IsTrue);

my @test_sets = (
    [IsDefined,             "foo",  1, 'IsDefined string'],
    [IsDefined,             23,     1, 'IsDefined number'],
    [IsDefined,             undef,  0, 'IsDefined undef'],
    
    [HasLength,             undef,  0, 'HasLength undef'],
    [HasLength,             "",     0, 'HasLength empty string'],
    [HasLength,             "n",    1, 'HasLength one char'],
    [HasLength(2),          "n",    0, 'HasLength(2) one char'],
    [HasLength(2),          "nm",   1, 'HasLength(2) two chars'],
    [HasLength(2,3),        "nm",   1, 'HasLength(2,3) two chars'],
    [HasLength(2,3),        "nmo",  1, 'HasLength(2,3) three chars'],
    [HasLength(2,3),        "nmop", 0, 'HasLength(2,3) four chars'],

    [IsTrue,                "foo",  1, 'IsTrue true string'],
    [IsTrue,                "",     0, 'IsTrue false string'],
    [IsTrue,                1,      1, 'IsTrue true number'],
    [IsTrue,                0,      0, 'IsTrue false number'],

    [IsOneOf(qw(a b c)),    "a",    1, 'IsOneOf string true'],
    [IsOneOf(qw(a b c)),    "c",    1, 'IsOneOf string true II'],
    [IsOneOf(qw(a b c)),    "n",    0, 'IsOneOf string false'],
    [IsOneOf(1, undef, 2),  0,      0, 'IsOneOf undef false'],
    [IsOneOf(1, undef, 2),  undef,  1, 'IsOneOf undef true'],
    [IsOneOf,               "foo",  0, 'ISOneOf no list false'],

    [Matches(qr/oo/),       "foob", 1, 'Matches string match'],
    [Matches(qr/aa/),       "boor", 0, 'Matches string no-match'],
    [Matches(qr/ii/),       undef,  0, 'Matches undef no-match'],
    [Matches(qr/a/,qr/b/),  "wubr", 1, 'Matches multiple'],
);

my @eval_sets = (
    [sub { Matches() },     'Regexp',
                                'Matches without args raises error'],
    [sub { Matches(23) },   'Regexp',
                                'Matches with non-regexp arg raises error'],
);

plan tests => scalar(@test_sets) + scalar(@eval_sets);

for (@test_sets) {
    my ($check, $value, $expect, $title) = @$_;
    my $result = $check->($value);
    is(($result ? 1 : 0), $expect, $title);
}
for (@eval_sets) {
    my ($check, $expect, $title) = @$_;
    eval { $check->() };
    like($@, qr/$expect/, $title);
}
