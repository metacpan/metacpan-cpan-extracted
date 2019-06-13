#!/usr/bin/env perl
#ABSTRACT - ab2fq.pl - A script to convert traces to FASTQ

use 5.012;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use FASTX::Abi;
use File::Basename;
my $fixed_quality = undef;

if (defined $ARGV[0] and ! -e $ARGV[0]) {
	$fixed_quality = shift @ARGV;
	die "Invalid quality: integer > 10 or single char to be supplied ($fixed_quality)\n" if ( (length($fixed_quality) > 1) and $fixed_quality!~/^\d+$/);

}
die "Usage: [FixedQuality] ", basename($0), " FILE1.ab1 FILE2.ab1 .. > reads.fq\n\n" unless defined $ARGV[0];

foreach my $file (@ARGV) {
	if (! -e "$file") {
		say STDERR " * Skipping '$file': not found";
		next;
	}
	my $trace = FASTX::Abi->new({ filename => $file });
	say $trace->get_fastq(undef, $fixed_quality);
}