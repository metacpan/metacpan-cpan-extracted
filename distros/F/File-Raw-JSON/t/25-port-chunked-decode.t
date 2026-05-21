#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# Derived from JSON::Lines's _buffer / clear_buffer / remaining
# semantics. JSON::Lines buffers incomplete JSON across decode() calls;
# our STREAM dispatch buffers across chunks (read() boundaries).
#
# Two angles:
#   1. The brace-balancer + stream accumulator handle a value split
#      across many chunks (worst case: the read happened to land
#      inside a string that contained an unbalanced brace).
#   2. Our slurp(plugin=>jsonl) yields the same record count regardless
#      of where the producer placed newlines.

my $dir = tempdir(CLEANUP => 1);

# Build a fixture where one of the records has braces inside its
# string field, and concatenate three values onto one line followed by
# the buffered one on the next.
my $value_with_braces = q|{"type":"trace","content":"{ inner } { more {} }"}|;
my $bytes =
      qq|{"a":1}\n|                # line 1
    . qq|$value_with_braces\n|     # line 2
    . qq|{"b":2}{"c":3}{"d":4}\n|  # line 3 - three on one line
    . qq|{\n  "pretty": true,\n  "nested": [1,2,3]\n}\n|;  # line 4-7 - pretty

my $f = "$dir/chunked.jsonl";
File::Raw::spew($f, $bytes);

my $expected = [
    { a => 1 },
    { type => 'trace', content => '{ inner } { more {} }' },
    { b => 2 }, { c => 3 }, { d => 4 },
    { pretty => File::Raw::JSON::Boolean::TRUE, nested => [1,2,3] },
];

# slurp recovers all six values correctly
my $slurped = File::Raw::slurp($f, plugin => 'jsonl');
is(scalar @$slurped, 6, 'six records via slurp');
is_deeply($slurped->[0], { a => 1 },                                 'a=1');
is($slurped->[1]{content}, '{ inner } { more {} }',                  'braces in string preserved');
is_deeply($slurped->[2], { b => 2 },                                 'b=2');
is_deeply($slurped->[3], { c => 3 },                                 'c=3');
is_deeply($slurped->[4], { d => 4 },                                 'd=4');
is_deeply($slurped->[5]{nested}, [1,2,3],                            'pretty multiline value');

# each_line yields the same sequence
my @stream;
File::Raw::each_line($f, sub { push @stream, $_[0] }, plugin => 'jsonl');
is(scalar @stream, 6, 'six records via each_line');
is($stream[1]{content}, '{ inner } { more {} }',
   'string-internal braces survive chunk-by-chunk streaming');
is_deeply($stream[5]{nested}, [1,2,3],
          'pretty multiline value survives streaming across newlines');

done_testing;
