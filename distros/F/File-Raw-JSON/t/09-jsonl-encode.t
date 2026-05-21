#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

# Encode AoV -> one JSON value per line, default \n terminator.
my $f = "$dir/e.jsonl";
File::Raw::spew($f, [{a=>1}, {b=>2}, {c=>3}], plugin => 'jsonl', sort_keys => 1);
is(File::Raw::slurp($f), qq({"a":1}\n{"b":2}\n{"c":3}\n),
   'minified one-per-line with newline terminators');

# Round-trip
is_deeply(File::Raw::slurp($f, plugin => 'jsonl'),
          [{a=>1},{b=>2},{c=>3}],
          'jsonl encode -> decode round-trip');

# Empty AoV -> empty file
my $f2 = "$dir/empty.jsonl";
File::Raw::spew($f2, [], plugin => 'jsonl');
is(File::Raw::slurp($f2), '', 'empty AoV -> empty file');

# Custom EOL
my $f3 = "$dir/crlf.jsonl";
File::Raw::spew($f3, [{a=>1},{b=>2}], plugin => 'jsonl', eol => "\r\n", sort_keys => 1);
is(File::Raw::slurp($f3), qq({"a":1}\r\n{"b":2}\r\n), 'CRLF eol');

# Non-arrayref payload croaks
my $f4 = "$dir/bad.jsonl";
eval { File::Raw::spew($f4, "not an array", plugin => 'jsonl') };
like($@, qr/arrayref/, 'scalar payload rejected');

eval { File::Raw::spew($f4, {a=>1}, plugin => 'jsonl') };
like($@, qr/arrayref/, 'hashref payload rejected');

# Append builds up records cleanly
my $f5 = "$dir/append.jsonl";
File::Raw::spew  ($f5, [{a=>1}], plugin => 'jsonl', sort_keys => 1);
File::Raw::append($f5, [{b=>2}], plugin => 'jsonl', sort_keys => 1);
File::Raw::append($f5, [{c=>3}], plugin => 'jsonl', sort_keys => 1);
my $back = File::Raw::slurp($f5, plugin => 'jsonl');
is_deeply($back, [{a=>1},{b=>2},{c=>3}], 'append accumulates records');

done_testing;
