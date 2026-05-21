#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

eval { require IO::Compress::Gzip;    1 } or plan skip_all => 'IO::Compress::Gzip missing';
eval { require IO::Compress::Deflate; 1 } or plan skip_all => 'IO::Compress::Deflate missing';

use File::Raw qw(import);
use File::Raw::Gzip;

my $dir = tempdir(CLEANUP => 1);
my $payload = "auto-detect me\n" x 100;

# Auto mode should decode both flavours without the caller setting `mode`.
my $gz_path = "$dir/auto.gz";
IO::Compress::Gzip::gzip(\$payload, $gz_path) or die "gzip: $!";
is(file_slurp($gz_path, plugin => 'gzip'), $payload,
    'auto mode decodes gzip-headered stream');

my $zlib_path = "$dir/auto.zlib";
IO::Compress::Deflate::deflate(\$payload, $zlib_path) or die "deflate: $!";
is(file_slurp($zlib_path, plugin => 'gzip', mode => 'auto'), $payload,
    'mode=auto decodes zlib-headered stream');

done_testing;
