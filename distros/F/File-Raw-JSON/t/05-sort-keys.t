#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);
my $f   = "$dir/s.json";
sub _read { File::Raw::slurp($f) }

my $value = { z => 1, m => 2, a => 3, '_' => 4 };

# sort_keys => 1 should produce deterministic key order regardless of
# Perl's internal hash randomisation
File::Raw::spew($f, $value, plugin => 'json', sort_keys => 1);
my $a = _read();
File::Raw::spew($f, $value, plugin => 'json', sort_keys => 1);
my $b = _read();
is($a, $b, 'sort_keys produces stable bytes across runs');
like($a, qr/^\{"_":4,"a":3,"m":2,"z":1\}$/, 'keys sorted lexically');

# canonical: sort_keys + minified
File::Raw::spew($f, $value, plugin => 'json', canonical => 1);
my $can = _read();
like($can, qr/^\{"_":4,"a":3,"m":2,"z":1\}$/, 'canonical sorts and minifies');

# Nested: sort recurses
my $nested = { z => { y => 1, a => 2 }, a => { c => 3, b => 4 } };
File::Raw::spew($f, $nested, plugin => 'json', sort_keys => 1);
my $sn = _read();
like($sn, qr/"a":\{"b":4,"c":3\}/,  'nested keys sorted');
like($sn, qr/"z":\{"a":2,"y":1\}/,  'sibling keys sorted');

# without sort_keys, key order is arbitrary - just check it parses back
File::Raw::spew($f, $value, plugin => 'json');
is_deeply(File::Raw::slurp($f, plugin => 'json'), $value,
          'unsorted output still round-trips');

done_testing;
