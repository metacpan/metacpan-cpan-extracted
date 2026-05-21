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
my $payload = join('', map { chr(int(rand(256))) } 1 .. 16384);

# gzip-wrapped, decoded via plugin.
{
    my $p = "$dir/foreign.gz";
    IO::Compress::Gzip::gzip(\$payload, $p) or die "gzip: $!";
    my $back = file_slurp($p, plugin => 'gzip', mode => 'gzip');
    is($back, $payload, 'foreign IO::Compress::Gzip output decodes (mode=gzip)');
}

# zlib-wrapped, decoded via plugin.
{
    my $p = "$dir/foreign.zlib";
    IO::Compress::Deflate::deflate(\$payload, $p) or die "deflate: $!";
    my $back = file_slurp($p, plugin => 'gzip', mode => 'zlib');
    is($back, $payload, 'foreign IO::Compress::Deflate output decodes (mode=zlib)');
}

done_testing;
