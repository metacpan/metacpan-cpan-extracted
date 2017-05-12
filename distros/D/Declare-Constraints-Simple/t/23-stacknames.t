#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use Declare::Constraints::Simple-All;

{
    package FooTest;
    sub foo { }
}
my $obj = bless {} => 'FooTest';

my @test_sets = (
    [Matches(qr/foo/),              'bar',          'Matches',              'Matches stackname'],
    [IsDefined,                     undef,          'IsDefined',            'IsDefined stackname'],
    [HasMethods(qw(foo bar)),       $obj,           'HasMethods[bar]',      'HasMethods stackname'],
    [IsArrayRef(IsInt),             [1,2,undef],    'IsArrayRef[2].IsInt',  'IsArrayRef stackname'],
    [IsHashRef(-keys => IsInt),     {foo => 23},    'IsHashRef[key foo].IsInt',   
                                                        'IsHashRef key stackname'],
    [IsHashRef(-values => IsInt),   {foo => 'bar'}, 'IsHashRef[val foo].IsInt',   
                                                        'IsHashRef val stackname'],
    [HasAllKeys(qw(foo bar)),       {foo => 23},    'HasAllKeys[bar]',      'HasAllKeys stackname'],
    [OnHashKeys(foo => IsInt),      {foo => 'bar'}, 'OnHashKeys[foo].IsInt',
                                                        'OnHashKeys stackname'],
    [Message('foo', IsInt),         'foobar',       'Message.IsInt',        'Message stackname'],
    [HasAllKeys(']Woot['),          {},             'HasAllKeys[\]Woot\[]', 'stack info escaped'],
);

plan tests => scalar(@test_sets);

for (@test_sets) {
    my ($check, $value, $path, $title) = @$_;
    my $result = $check->($value);
    is($result->path, $path, $title);
}
