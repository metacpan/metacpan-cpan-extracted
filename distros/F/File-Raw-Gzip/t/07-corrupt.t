#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw qw(import);
use File::Raw::Gzip;

my $dir = tempdir(CLEANUP => 1);

# Make a real gzip stream, then mangle the payload (skip the 10-byte
# gzip header so we keep the magic bytes intact and trip the CRC /
# deflate checks rather than the header).
my $orig = "lorem ipsum dolor sit amet " x 200;
my $path = "$dir/orig.gz";
file_spew($path, $orig, plugin => 'gzip');
my $gz = do { local $/; open my $fh, '<:raw', $path or die $!; <$fh> };

ok(length($gz) > 50, "starting gzip blob is non-trivial");

# Flip a byte deep in the deflate body.
substr($gz, length($gz) / 2, 1) = chr( (ord(substr($gz, length($gz)/2, 1)) ^ 0xff) & 0xff );

my $bad = "$dir/bad.gz";
{ open my $fh, '>:raw', $bad or die $!; print $fh $gz; close $fh; }

my $err;
eval { file_slurp($bad, plugin => 'gzip'); 1 } or $err = $@;
ok(defined $err, 'corrupt gzip stream croaks');
like($err, qr/File::Raw::Gzip/, 'error message mentions the plugin');

# Truncated input: chop off the last 8 bytes (gzip CRC32 + ISIZE).
my $truncated = "$dir/trunc.gz";
{
    open my $fh, '>:raw', $truncated or die $!;
    print $fh substr($gz, 0, length($gz) - 8);
    close $fh;
}
$err = undef;
eval { file_slurp($truncated, plugin => 'gzip'); 1 } or $err = $@;
ok(defined $err, 'truncated gzip stream croaks');

done_testing;
