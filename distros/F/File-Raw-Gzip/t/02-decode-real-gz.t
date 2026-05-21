#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

eval { require IO::Compress::Gzip; 1 }
    or plan skip_all => 'IO::Compress::Gzip not available';

use File::Raw qw(import);
use File::Raw::Gzip;

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/sample.gz";

my $plain = "The quick brown fox jumps over the lazy dog.\n" x 50;
IO::Compress::Gzip::gzip(\$plain, $path)
    or die "IO::Compress::Gzip failed";

# Default decode mode is 'auto' -- should pick up gzip header.
my $back = file_slurp($path, plugin => 'gzip');
is($back, $plain, 'IO::Compress::Gzip output decodes via plugin (auto mode)');

# Explicit gzip mode also works.
my $back2 = file_slurp($path, plugin => 'gzip', mode => 'gzip');
is($back2, $plain, 'IO::Compress::Gzip output decodes via plugin (mode=gzip)');

done_testing;
