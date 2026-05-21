#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# Ported from JSON-Lines-1.11/t/01-encode.t + 02-decode.t.
# Encode an AoV via spew(plugin => 'jsonl') and verify the bytes can
# be decoded by the reference module (skipped if not installed) -
# wire-compatibility canary.

my $dir = tempdir(CLEANUP => 1);

my @rows = (
    { name => "Gilbert", session => "2013",  score => 24, completed => 1 },
    { name => "Alexa",   session => "2013",  score => 29, completed => 1 },
    { name => "May",     session => "2012B", score => 14, completed => 0 },
    { name => "Deloise", session => "2012A", score => 19, completed => 1 },
);

my $f = "$dir/scores.jsonl";
File::Raw::spew($f, \@rows, plugin => 'jsonl', sort_keys => 1);

# Self check first
is_deeply(File::Raw::slurp($f, plugin => 'jsonl'), \@rows,
          'self round-trip via slurp + spew');

SKIP: {
    eval { require JSON::Lines; 1 }
        or skip 'JSON::Lines not installed', 1;

    my $jl = JSON::Lines->new(canonical => 1);
    my $bytes = File::Raw::slurp($f);
    my @decoded = $jl->decode($bytes);
    is_deeply(\@decoded, \@rows,
              'JSON::Lines decodes our spew(plugin=>jsonl) output');
}

SKIP: {
    eval { require JSON::Lines; 1 }
        or skip 'JSON::Lines not installed', 1;

    # Reverse direction: bytes JSON::Lines produces must decode through
    # our slurp(plugin=>jsonl) too.
    my $jl = JSON::Lines->new(canonical => 1);
    my $bytes = $jl->encode(@rows);
    my $f2 = "$dir/from_jsonlines.jsonl";
    File::Raw::spew($f2, $bytes);
    is_deeply(File::Raw::slurp($f2, plugin => 'jsonl'), \@rows,
              'our slurp decodes JSON::Lines output');
}

done_testing;
