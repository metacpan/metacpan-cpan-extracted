use 5.012;
use autodie;
use Term::ANSIColor;
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../lib/";
use FASTQ::MooseReader;



my ($opt_1, $opt_2) = @ARGV;
my $file1 = $opt_1 // "$Bin/test.fastq";
my $file2 = $opt_2 // "$Bin/test2.fastq";
my $o1 = FASTQ::Reader->new(filename => "$file1");
my $o2 = FASTQ::Reader->new(filename => "$file2");


print "READ FILE 1: $file1\n";
print "READ FILE 2: $file1\n";

my $counter = 0;
while (my $seq = $o1->getFastqRead()) {
  $counter++;
  my $pair = $o2->getFastqRead();
  say color('red'), $counter, color('reset'), "\t",$seq->{name}, ' - ', $pair->{name};
}
