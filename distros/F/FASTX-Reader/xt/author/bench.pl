#!/usr/bin/env perl
use 5.010;
use Benchmark qw(:all);

use FindBin qw($Bin);
use lib "$Bin/../../lib/";
use FASTX::Reader;

my $s = "$Bin/../../data/";
my @files = ("$s/comments.fastq",  "$s/test2.fastq", "$s/test.fastq");
unshift(@files, @ARGV);
my $c = 1500;
$c /= 100 if ($ARGV[3]);
foreach my $file (@files) {
	if (! -e "$file") { say STDERR "Skipping $file"; next; }
	say "== $file ==";
	cmpthese($c, {
	    	'Fx' => sub { test_fx($file); },
    		'Fq' => sub { test_fq($file); },
	});

}


sub test_fx {
	my $seq = FASTX::Reader->new({ filename => "$_[0]" });
	my $cmp = '';
	while (my $i = $seq->getRead) {
		$cmp .= $i->{name};
	}
}
sub test_fq {
	my $seq = FASTX::Reader->new({ filename => "$_[0]" });
	my $cmp = '';
	while (my $i = $seq->getFastqRead) {
		$cmp .= $i->{name};
	}
}
