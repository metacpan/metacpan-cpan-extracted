#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# slurp(plugin => 'jsonl') and each_line(plugin => 'jsonl') + collect
# should produce identical results for any input.

my $dir = tempdir(CLEANUP => 1);

my @samples = (
    [ 'vanilla NDJSON',       qq({"a":1}\n{"b":2}\n{"c":3}\n) ],
    [ 'pretty multi-line',    qq({\n  "a":1\n}\n[\n  1,\n  2\n]\n) ],
    [ 'concat no newlines',   q|{"a":1}{"b":2}{"c":3}| ],
    [ 'mixed obj and arr',    qq([1,2]\n{"a":1}\n[3,4]\n{"b":2}\n) ],
    [ 'trailing whitespace',  qq({"a":1}\n\n   \n) ],
);

for my $s (@samples) {
    my ($name, $bytes) = @$s;
    my $f = "$dir/eq.jsonl";
    File::Raw::spew($f, $bytes);

    my $slurped = File::Raw::slurp($f, plugin => 'jsonl');
    my @streamed;
    File::Raw::each_line($f, sub { push @streamed, $_[0] }, plugin => 'jsonl');

    is_deeply(\@streamed, $slurped, "$name: each_line matches slurp");
}

done_testing;
