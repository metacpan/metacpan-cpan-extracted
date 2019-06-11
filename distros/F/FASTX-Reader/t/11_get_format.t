use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Reader';

my $basename = "$Bin/../data/test.";

for my $format ('fasta', 'fastq') {
    my $file = $basename . $format;

    # Check required input file
    if (! -e "$file") {
      print STDERR "Skip test: $file not found\n";
      next;
    }
    my $detected_format = FASTX::Reader->getFileFormat("$file");
    ok($format eq $detected_format, "Format detection ok for $format"); 


}

my $detected_format = FASTX::Reader->getFileFormat("$0");
ok(! defined $detected_format, "Format detection ok: undef for non sequence file"); 

done_testing();
