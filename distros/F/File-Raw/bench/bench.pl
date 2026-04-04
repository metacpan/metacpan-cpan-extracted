#!/usr/bin/env perl
#
# bench.pl - Run all File::Raw benchmarks
#
use strict;
use warnings;
use FindBin;

my @benches = qw(slurp.pl spew.pl lines.pl stat.pl path.pl mmap.pl);

for my $bench (@benches) {
    my $path = "$FindBin::Bin/$bench";
    print "\n", "=" x 60, "\n";
    print "Running: $bench\n";
    print "=" x 60, "\n\n";
    system($^X, $path) == 0 or warn "Failed: $bench\n";
}
