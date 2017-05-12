#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use Declare::Constraints::Simple
    only => qw(HasAllKeys OnHashKeys Matches IsInt);

my @test_sets = (
    [HasAllKeys(qw(foo bar)),       {foo => 1, baz => 2},   0,  'HasAllKeys one missing'],
    [HasAllKeys(qw(foo bar)),       {foo => 1, bar => 2},   1,  'HasAllKeys true'],
    [HasAllKeys(qw(foo bar)),       undef,                  0,  'HasAllKeys undef'],
    [HasAllKeys(qw(foo bar)),       [],                     0,  'HasAllKeys array ref'],
    [HasAllKeys(qw(foo bar)),       "foo",                  0,  'HasAllKeys string'],

    [ OnHashKeys(foo => IsInt, bar => Matches(qr/x/)),
      { foo => 12, bar => "fox" },                          1,  'OnHashKeys both true'],
    [ OnHashKeys(foo => IsInt, bar => Matches(qr/x/)),
      { foo => 23, bar => 5 },                              0,  'OnHashKeys one false'],
    [ OnHashKeys(foo => IsInt, bar => Matches(qr/x/)),
      { foo => 23 },                                        1,  'OnHashKeys one missing true'],
    [ OnHashKeys(foo => IsInt),     undef,                  0,  'OnHashKeys undef'],
    [ OnHashKeys(foo => IsInt),     [],                     0,  'OnHashKeys array ref'],
    [ OnHashKeys(foo => [IsInt, Matches(qr/3/)]),
      { foo => 23 },                                        1,  'OnHashKeys list true'],
    [ OnHashKeys(foo => [IsInt, Matches(qr/3/)]),
      { foo => 5 },                                         0,  'OnHashKeys list false'],
);

plan tests => scalar(@test_sets);

for (@test_sets) {
    my ($check, $value, $expect, $title) = @$_;
    my $result = $check->($value);
    is(($result ? 1 : 0), $expect, $title);
}
