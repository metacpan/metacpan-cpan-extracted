#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);
my $f   = "$dir/p.json";
sub _read { File::Raw::slurp($f) }

# Default: minified
File::Raw::spew($f, {a=>1,b=>2}, plugin => 'json', sort_keys => 1);
is(_read(), '{"a":1,"b":2}', 'no pretty -> minified');

# pretty + indent=>2 -> 2-space indent
File::Raw::spew($f, {a=>1,b=>2}, plugin => 'json', sort_keys => 1, pretty => 1, indent => 2);
my $p2 = _read();
like($p2, qr/\n  "a": 1/,           'pretty indent=2 produces 2 leading spaces');
like($p2, qr/\n}\z|\n}\n/,          'closing brace on own line');

# pretty + indent=>4 -> 4-space indent
File::Raw::spew($f, {a=>1,b=>2}, plugin => 'json', sort_keys => 1, pretty => 1, indent => 4);
my $p4 = _read();
like($p4, qr/\n    "a": 1/,         'pretty indent=4 produces 4 leading spaces');

# Other indent values croak
eval { File::Raw::spew($f, {a=>1}, plugin => 'json', pretty => 1, indent => 3) };
like($@, qr/indent must be 2 or 4/, 'indent=3 rejected');

eval { File::Raw::spew($f, {a=>1}, plugin => 'json', pretty => 1, indent => 8) };
like($@, qr/indent must be 2 or 4/, 'indent=8 rejected');

done_testing;
