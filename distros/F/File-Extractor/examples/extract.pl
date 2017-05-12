#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;
use File::Basename;
use File::Extractor;

my $extractor = File::Extractor->loadDefaultLibraries;

for my $file (@ARGV) {
    my $fh = IO::File->new($file, 'r') or next;
    my %keywords = $extractor->getKeywords($fh);
    print basename($file), ":\n";
    dump \%keywords;
}
