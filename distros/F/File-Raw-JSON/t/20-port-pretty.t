#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# Ported from JSON-Lines-1.11/t/05-pretty.t
# Pretty-printed multi-line JSONL must decode back to the same
# structure. JSON::Lines's $LINES regex handles this; our brace-
# balancer must too.

my $dir = tempdir(CLEANUP => 1);

my @data = (
    [qw/a b c/],
    [{"one" => "one"}, {"two" => "two"}, ["three", "three"]],
    [{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
);

# Pretty-printed bytes (4-space indent here, mirroring the original test
# fixture which used JSON::PP's default 3-space indent — yyjson only
# does 2 or 4, and the brace-balancer is indent-agnostic anyway).
my $bytes = q|[
    "a",
    "b",
    "c"
]
[
    {
        "one" : "one"
    },
    {
        "two" : "two"
    },
    [
        "three",
        "three"
    ]
]
[
    {
        "four" : "four"
    },
    {
        "five" : "five"
    },
    [
        "six",
        "six"
    ]
]
|;

my $f = "$dir/pretty.jsonl";
File::Raw::spew($f, $bytes);
my $back = File::Raw::slurp($f, plugin => 'jsonl');

is(scalar @$back, 3, 'three records recovered from pretty-printed JSONL');
is_deeply($back, \@data, 'pretty-printed multi-line records decode correctly');

# each_line yields the same
my @stream;
File::Raw::each_line($f, sub { push @stream, $_[0] }, plugin => 'jsonl');
is_deeply(\@stream, \@data, 'each_line streams pretty-printed records');

done_testing;
