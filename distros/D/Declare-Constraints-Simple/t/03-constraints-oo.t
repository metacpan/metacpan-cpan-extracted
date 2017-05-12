#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use Declare::Constraints::Simple
    only => qw(IsA IsClass HasMethods IsObject);

{
    package TestA;
    sub foo { }
    sub bar { }
    package TestB;
    use base 'TestA';
    sub foo { }
}
my $testA = bless {} => 'TestA';
my $testB = bless {} => 'TestB';

my @test_sets = (
    [IsA(qw(TestNone TestA)),       $testA,     1,  'IsA multiple true'],
    [IsA('TestB'),                  $testA,     0,  'IsA false'],
    [IsA('TestA'),                  undef,      0,  'IsA undef'],
    [IsA(),                         $testA,     0,  'IsA empty'],
    [IsA('TestA'),                  'TestB',    1,  'IsA class true'],
    [IsA('TestA'),                  'Foo',      0,  'IsA class unknown'],
    [IsA('TestB'),                  'TestA',    0,  'IsA class false'],

    [IsClass,                       'Foo',      0,  'IsClass false'],
    [IsClass,                       undef,      0,  'IsClass undef'],
    [IsClass,                       'TestA',    1,  'IsClass true'],

    [IsObject,                      undef,      0,  'IsObject undef'],
    [IsObject,                      "foo",      0,  'IsObject string'],
    [IsObject,                      {},         0,  'IsObject hash ref'],
    [IsObject,                      $testA,     1,  'IsObject true'],

    [HasMethods(qw(foo)),           $testA,     1,  'HasMethods true'],
    [HasMethods(qw(foo bar)),       $testA,     1,  'HasMethods multiple true'],
    [HasMethods(qw(foo baz)),       $testA,     0,  'HasMethods half false'],
    [HasMethods(qw(baz)),           $testA,     0,  'HasMethods all false'],
    [HasMethods(qw(bar)),           $testB,     1,  'HasMethods inherited true'],
    [HasMethods(),                  $testB,     1,  'HasMethods no list true'],
    [HasMethods(),                  "foo",      0,  'HasMethods no list no class'],
    [HasMethods(qw(foo)),           undef,      0,  'HasMethods undef'],
);

plan tests => scalar(@test_sets);

for (@test_sets) {
    my ($check, $value, $expect, $title) = @$_;
    my $result = $check->($value);
    is(($result ? 1 : 0), $expect, $title);
}
