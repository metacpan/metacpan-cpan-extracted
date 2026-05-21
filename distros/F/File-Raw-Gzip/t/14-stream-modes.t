#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Compress::Gzip    qw(gzip);
use IO::Compress::Deflate qw(deflate);
use File::Raw qw(import);
use File::Raw::Gzip;

my $dir = tempdir(CLEANUP => 1);

my @lines = ('alpha', 'beta', 'gamma', 'delta');
my $payload = join("\n", @lines) . "\n";

# zlib-wrapped (RFC 1950) inside a file.
my $zlib_path = "$dir/zlib.bin";
deflate(\$payload, $zlib_path) or die "deflate failed";

my @seen;
File::Raw::each_line($zlib_path, sub { push @seen, $_ },
                     plugin => 'gzip', mode => 'zlib');
is_deeply(\@seen, \@lines, 'stream decode under mode=zlib');

# Raw deflate (RFC 1951): IO::Compress::RawDeflate
require IO::Compress::RawDeflate;
my $raw_path = "$dir/raw.bin";
IO::Compress::RawDeflate::rawdeflate(\$payload, $raw_path)
    or die "rawdeflate failed";

@seen = ();
File::Raw::each_line($raw_path, sub { push @seen, $_ },
                     plugin => 'gzip', mode => 'raw');
is_deeply(\@seen, \@lines, 'stream decode under mode=raw');

# auto: gzip stream, no mode given -> default decode is auto.
my $gz_path = "$dir/auto.gz";
gzip(\$payload, $gz_path) or die "gzip failed";
@seen = ();
File::Raw::each_line($gz_path, sub { push @seen, $_ }, plugin => 'gzip');
is_deeply(\@seen, \@lines, 'stream decode auto-detects gzip header');

done_testing;
