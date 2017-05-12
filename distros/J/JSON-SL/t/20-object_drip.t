#!/usr/bin/perl
use strict;
use warnings;

use JSON::SL;
use Test::More;

my $sl = JSON::SL->new();
$sl->object_drip(1);

my $json = <<'EOJ';
[
    [
        {
            "key1" : "foo",
            "key2" : "bar",
            "key3" : "baz"
        }
    ]
EOJ
my @res = $sl->feed($json);

my $expected = [
    {
        Value => "foo",
        Path => '/0/0/key1',
    },
    {
        Value => "bar",
        Path => '/0/0/key2',
    },
    {
        Value => "baz",
        Path => '/0/0/key3'
    },
    {
        Value => {},
        Path => '/0/0'
    },
    {
        Value => [],
        Path => '/0'
    }
];

is_deeply(\@res, $expected, "Got expected results for object drip...");
done_testing();

