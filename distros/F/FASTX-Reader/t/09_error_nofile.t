use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;
use Data::Dumper;
use FASTX::Reader;
my $seq = "$Bin/../data/not_found_test.fasta";

# Check required input file
if (-e $seq) {
  print STDERR "Skip test: $seq was found, oddly enough this is unexpected\n";
  exit 0;
}


my $eval = eval {
 my $data = FASTX::Reader->new({ filename => "$seq" });
 print Dumper $data;
 1;
};

ok(!defined $eval, "Did not read a file");
done_testing();
