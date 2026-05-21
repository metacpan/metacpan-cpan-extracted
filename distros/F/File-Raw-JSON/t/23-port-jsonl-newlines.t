#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# Ported from JSON-Lines-1.11/t/04-jsonl.t (vanilla NDJSON shape).
# Backwards compatibility with strict producers: one compact value per
# line, trailing newline. Should decode identically to the multi-line /
# concat cases.

my $dir = tempdir(CLEANUP => 1);

my @data = (
    { name => "Gilbert", session => "2013",  score => 24, completed => 1 },
    { name => "Alexa",   session => "2013",  score => 29, completed => 1 },
    { name => "May",     session => "2012B", score => 14, completed => 0 },
    { name => "Deloise", session => "2012A", score => 19, completed => 1 },
);

# Build the canonical NDJSON file ourselves (one compact value per
# line, trailing newline).
my $f = "$dir/scores.jsonl";
File::Raw::spew($f, \@data, plugin => 'jsonl', sort_keys => 1);

# Manual byte check
my $bytes = File::Raw::slurp($f);
like($bytes, qr/\A\{[^\n]+\}\n\{[^\n]+\}\n\{[^\n]+\}\n\{[^\n]+\}\n\z/,
     'four compact lines with trailing newline');

# Decode round-trip
my $back = File::Raw::slurp($f, plugin => 'jsonl');
is(scalar @$back, 4, 'four records');
is_deeply($back->[0], $data[0], 'Gilbert intact');
is_deeply($back->[3], $data[3], 'Deloise intact');

# Streaming yields the same
my @stream;
File::Raw::each_line($f, sub { push @stream, { %{$_[0]} } }, plugin => 'jsonl');
is_deeply(\@stream, $back, 'each_line == slurp on vanilla NDJSON');

done_testing;
