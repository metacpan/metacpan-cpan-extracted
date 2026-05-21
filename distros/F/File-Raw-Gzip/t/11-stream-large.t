#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Compress::Gzip qw(gzip);
use File::Raw::Gzip;

my $mb   = $ENV{FILE_RAW_GZIP_LARGE_MB} || 4;
my $rows = $mb * 4096;          # ~4 MB of plaintext at ~256 B/line

my $dir = tempdir(CLEANUP => 1);

# Deterministic-ish payload: line N is 'row=N ' + 250 bytes of pattern.
my $pat = join('', map { chr(0x40 + ($_ % 26)) } 0 .. 249);
my @lines = map { "row=$_ $pat" } 1 .. $rows;
my $payload = join("\n", @lines) . "\n";

my $path = "$dir/big.gz";
gzip(\$payload, $path) or die "gzip failed";

my $count = 0;
my ($first, $last);
File::Raw::each_line($path, sub {
    $count++;
    $first = $_ if $count == 1;
    $last  = $_;
}, plugin => 'gzip');

is($count, $rows, "saw $rows lines");
is($first, "row=1 $pat",     'first line correct');
is($last,  "row=$rows $pat", 'last line correct');

done_testing;
