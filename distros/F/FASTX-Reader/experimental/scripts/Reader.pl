use 5.012;
use autodie;
use Term::ANSIColor;
use Data::Dumper;
use Carp qw(confess);
use FindBin qw($Bin);
use lib "$Bin/../lib/";
use FASTQ::Reader;

my ($opt_1, $opt_2) = @ARGV;
my $file1 = $opt_1 // "$Bin/test.fastq";
my $file2 = $opt_2 // "$Bin/test2.fastq";
my $o1 = FASTQ::Reader->new({filename => "$file1"});
my $o2 = FASTQ::Reader->new({filename => "$file2"});


print STDERR color('yellow'), "Test file formats of input files\n", color('reset');
foreach my $file (@ARGV) {
  say " - [",  FASTQ::Reader::getFileFormat($file) , "]\t<- $file";
}
print STDERR color('yellow'), "READ FILE 1: $file1\n", color('reset');
print STDERR color('yellow'), "READ FILE 2: $file1\n", color('reset');

my $counter = 0;
while (my $seq = $o1->getRead()) {
  $counter++;
  if (defined $seq->{qual}) {
    print '@', $seq->{name}, ' ', $seq->{comment}, "\n", $seq->{seq}, "\n+\n", $seq->{qual}, "\n";
  } else {
    print ">", $seq->{name}, ' ', $seq->{comment}, "\n", $seq->{seq}, "\n";
  }
}
say STDERR 'File1 seqs: ',color('green'), $o1->{counter}, color('reset');
say STDERR 'File2 seqs: ',color('green'), $o2->{counter}, color('reset');
# Test general settings for the module
#my $file = FASTQ::Reader->new(
#	filepath => $input,
#);
#my $input = file("$Bin/test.fastq");

#while (my $line = $file->process_file) {
#	say $line;
#}
