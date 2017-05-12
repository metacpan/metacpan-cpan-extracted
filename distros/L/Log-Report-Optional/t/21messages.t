#!/usr/bin/env perl
# Test the minimal message

use Test::More tests => 7;

use Log::Report::Minimal 'domoor';

is(__"aap", 'aap', '__');
is(__"aap {v}", 'aap {v}', '__ no interpol');
is(__x("aap{v}noot", v => ' mies '), 'aap mies noot', '__x');
is(__xn("one {file}", "{_count} files", 3, file => 'fn'), "3 files", '__xn');
is(__nx("one {file}", "{_count} files", 1, file => 'fn'), "one fn", '__nx');

my @x = N__w"one two three";
cmp_ok(scalar @x, '==', 3, 'N__w');
is($x[-1], 'three');
