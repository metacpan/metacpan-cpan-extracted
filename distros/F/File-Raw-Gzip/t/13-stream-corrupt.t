#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Compress::Gzip qw(gzip);
use File::Raw::Gzip;

my $dir = tempdir(CLEANUP => 1);

# Make a real gzip then chew up bytes in the deflate body.
my $payload = join("\n", map { "x" x 64 . " line $_" } 1 .. 4000) . "\n";
my $path    = "$dir/bad.gz";
gzip(\$payload, $path) or die "gzip failed";

# Corrupt mid-file: read all, smear bytes around offset 1000, write back.
open my $fh, '<:raw', $path or die $!;
my $bytes = do { local $/; <$fh> };
close $fh;

substr($bytes, 1000, 32) = "\x00" x 32;

open my $wh, '>:raw', $path or die $!;
print $wh $bytes;
close $wh;

eval { File::Raw::each_line($path, sub { 1 }, plugin => 'gzip') };
my $err = $@;
ok($err,                        'corrupt input raises an error');
like($err, qr/File::Raw::Gzip/, 'error labelled with our package');

done_testing;
