#!/usr/bin/env perl

use v5.12;
use warnings;
use lib 'lib';
use FindBin '$RealBin';
use Term::ANSIColor qw(:constants);
# Check if blib directories exist and add them to @INC if found
BEGIN {
   my $RealBin = $FindBin::RealBin;
   my $parent_dir = "$RealBin/..";
   if (-d "$parent_dir/blib/lib") {
        print STDERR BLUE, "Adding ../blib/lib to @INC\n", RESET;
       unshift @INC, "$parent_dir/blib/lib";
   }
   if (-d "$parent_dir/blib/arch") {
       print STDERR BLUE, "Adding ../blib/arch to @INC\n", RESET;
       unshift @INC, "$parent_dir/blib/arch";
   }
}

print STDERR GREEN "EXAMPLE USING THIS MODULE: FASTX::XS\n", RESET;

use FASTX::XS;

my $file = $ARGV[0] || 't/test.fq.gz';
if (!-e $file) {
    die "File not found: $file\n";
}

my $parser = FASTX::XS->new($file);

my $seq_count = 0;
my $total_length = 0;

while (my $seq = $parser->next_seq()) {
    $seq_count++;
    $total_length += length($seq->{seq});
}

print "Filename:        $file\n";
print "Total sequences: $seq_count\n";
print "Total length:    $total_length\n";
