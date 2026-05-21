#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Compress::Gzip qw(gzip);
use File::Raw::Gzip;

my $dir = tempdir(CLEANUP => 1);

my $payload = join("\n", map { "line $_" } 1 .. 200) . "\n";
my $path    = "$dir/many.gz";
gzip(\$payload, $path) or die "gzip failed";

# Callback that dies on the 50th line should propagate, and we should
# not have seen any line beyond the death point.
my $seen = 0;
eval {
    File::Raw::each_line($path, sub {
        $seen++;
        die "stop at $seen\n" if $seen == 50;
    }, plugin => 'gzip');
};
my $err = $@;

like($err, qr/^stop at 50/, 'callback exception propagated');
is($seen, 50,               'callback fired exactly through the dying line');

done_testing;
