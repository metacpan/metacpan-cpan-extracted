#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw qw(import);
use File::Raw::Gzip;

# 5 MB random blob (the plan calls for 50 MB but that's wasteful for
# CPAN testers; reduced. Set FILE_RAW_GZIP_LARGE_MB to override).
my $mb = $ENV{FILE_RAW_GZIP_LARGE_MB} || 5;
my $size = $mb * 1024 * 1024;

my $dir = tempdir(CLEANUP => 1);

# Build deterministic-looking pseudo-random data without depending on
# Perl's rand() seed to keep memory pressure predictable.
my $payload = '';
my $seed = 0xabcd1234;
{
    my $s = $seed;
    while (length($payload) < $size) {
        $s = ($s * 1103515245 + 12345) & 0x7fffffff;
        $payload .= pack('N', $s);
    }
    substr($payload, $size) = '' if length($payload) > $size;
}
is(length($payload), $size, "built ${mb} MB payload");

my $path = "$dir/large.gz";
file_spew($path, $payload, plugin => 'gzip');
ok(-s $path > 0, "large gzip produced (-s = " . (-s $path) . ")");

my $back = file_slurp($path, plugin => 'gzip');
is(length($back), $size, "decoded length matches");
ok($back eq $payload, "decoded content matches");

done_testing;
