#!/usr/bin/env perl
#ABSTRACT - ab2fq.pl - A script to convert traces to FASTQ

use 5.012;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use FASTX::Abi;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
my $force_het = 0;
my $opt_verbose = 0;
my $opt_quality	= undef;
my $opt_min_quality = 40;
GetOptions(
	'force' => \$force_het,
	'verbose' => \$opt_verbose,
	'q|min-qual=f' => \$opt_min_quality,
	'opt-quality=f' => \$opt_quality,
);

unless (defined $ARGV[0]) {
  die "Usage: ", basename($0),
   " [FixedQuality] FILE1.ab1 FILE2.ab1 .. > reads.fq\n\n";
}


foreach my $file (@ARGV) {
	if (! -e "$file") {
		say STDERR " * Skipping '$file': not found";
		next;
	}
	my $trace = FASTX::Abi->new({ 
		filename => $file,
		trim_ends => 1,
		min_qual => $opt_min_quality,

	});


 	say $trace->get_fastq(undef, $opt_quality);
	say Dumper $trace if ($ARGV[-1] eq '-v');
}
