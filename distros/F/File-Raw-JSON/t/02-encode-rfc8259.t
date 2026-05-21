#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# RFC 8259 primitives, encode side. Exact byte output where determined.
#
# NB: spew() options are passed at the call site as a literal list.
# A helper that takes %opts and re-splices them via spew(...,%opts)
# trips a Perl optimizer quirk where the trailing hash flattens in
# scalar context and adds a phantom arg. Pre-flattening the helper
# avoids it.

my $dir = tempdir(CLEANUP => 1);
my $f   = "$dir/out.json";

sub _read { File::Raw::slurp($f) }

# Defaults
File::Raw::spew($f, undef, plugin => 'json');         is(_read(), 'null',  'undef -> null');
File::Raw::spew($f, 42,    plugin => 'json');         is(_read(), '42',    'integer');
File::Raw::spew($f, -7,    plugin => 'json');         is(_read(), '-7',    'negative integer');
File::Raw::spew($f, "hello", plugin => 'json');       is(_read(), '"hello"', 'string');
File::Raw::spew($f, "",      plugin => 'json');       is(_read(), '""',    'empty string');

File::Raw::spew($f, [],         plugin => 'json');    is(_read(), '[]',    'empty array');
File::Raw::spew($f, {},         plugin => 'json');    is(_read(), '{}',    'empty object');
File::Raw::spew($f, [1,2,3],    plugin => 'json');    is(_read(), '[1,2,3]', 'integer array');

# NB. Bind sentinels to scalars first - File::Raw's spew call-checker
# in void context interacts badly with inline sub calls in the arg
# list (the constant-sub return is elided), turning a 4-arg call into
# 3 args and causing a spurious "odd number of options" croak.
my $true  = File::Raw::JSON::Boolean::TRUE;
my $false = File::Raw::JSON::Boolean::FALSE;
File::Raw::spew($f, $true,  plugin => 'json'); is(_read(), 'true',  'true sentinel');
File::Raw::spew($f, $false, plugin => 'json'); is(_read(), 'false', 'false sentinel');

# Sort_keys gives deterministic order
File::Raw::spew($f, {a=>1,b=>2,c=>3}, plugin => 'json', sort_keys => 1);
is(_read(), '{"a":1,"b":2,"c":3}', 'sort_keys produces stable output');

# String escapes
File::Raw::spew($f, "with\nnewline", plugin => 'json'); is(_read(), '"with\\nnewline"', 'newline escaped');
File::Raw::spew($f, "with\"quote",   plugin => 'json'); is(_read(), '"with\\"quote"',   'quote escaped');
File::Raw::spew($f, "back\\slash",   plugin => 'json'); is(_read(), '"back\\\\slash"', 'backslash escaped');

# Round-trip floats. Use 0.5 (exactly representable in IEEE 754
# double) so this stays bit-exact on long-double / quadmath NV Perls
# where the JSON-double round-trip would otherwise be visibly lossy.
File::Raw::spew($f, 0.5, plugin => 'json');
my $back = File::Raw::slurp($f, plugin => 'json');
cmp_ok($back, '==', 0.5, 'float round-trips');

done_testing;
