#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw qw(import);
use File::Raw::Gzip;

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/empty.gz";

# Encode of empty input must produce a valid empty-payload gzip stream.
file_spew($path, '', plugin => 'gzip');
ok(-s $path > 0, 'empty input still produces a gzip frame');

my $back = file_slurp($path, plugin => 'gzip');
is($back, '', 'empty round-trip');

# Same for zlib mode.
my $zpath = "$dir/empty.zlib";
file_spew($zpath, '', plugin => 'gzip', mode => 'zlib');
ok(-s $zpath > 0, 'empty zlib frame produced');
is(file_slurp($zpath, plugin => 'gzip', mode => 'zlib'), '',
    'empty zlib round-trip');

# Raw deflate of empty input is allowed and decodes to empty.
my $rpath = "$dir/empty.raw";
file_spew($rpath, '', plugin => 'gzip', mode => 'raw');
is(file_slurp($rpath, plugin => 'gzip', mode => 'raw'), '',
    'empty raw deflate round-trip');

done_testing;
