use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;
use FASTX::ReaderPaired;

# TEST: Check errors on wrong filenames

my $seqfile1 = "$RealBin/../data/illumina_1.fq.gz";
my $seqfile2 = "$RealBin/../data/illumina_2.fq.gz";
my $badfile1 = "$RealBin/../data/illumina_R1.fq.gz";
my $badfile2 = "$RealBin/../data/illumina_R2.fq.gz";
# Check required input file
if (! -e $seqfile1) {
  print STDERR "Skip test: $seqfile1 (R1) not found\n";
  done_testing();
  exit 0;
}
if (! -e $seqfile2) {
  print STDERR "Skip test: $seqfile2 (R2) not found\n";
  done_testing();
  exit 0;
}
if (-e $badfile1) {
  print STDERR "Skip test: $badfile1 (R1) not expected\n";
  done_testing();
  exit 0;
}
if (-e $badfile2) {
  print STDERR "Skip test: $badfile1 (R2) not expected\n";
  done_testing();
  exit 0;
}

my $data_OK = FASTX::ReaderPaired->new({ 
    filename => "$seqfile1",
    rev      => "$seqfile2",
});
my $PE_OK = $data_OK->getReads();
ok(defined $PE_OK->{qual1}, "[PE_OK] quality1 is defined");
ok(defined $PE_OK->{qual2}, "[PE_OK] quality2 is defined");

eval {
        my $data_KO = FASTX::ReaderPaired->new({ 
            filename => "$seqfile1",
            rev      => "$badfile2",
        });
};

ok(defined $@, "[PE_KO] Unable to create object with wrong R2 pair:\n" .  substr($@, 0, 150)."...");

eval {
        my $data_KO = FASTX::ReaderPaired->new({ 
            filename => "$badfile1",
            rev      => "$seqfile2",
        });
};
ok(defined $@, "[PE_KO] Unable to create object with wrong R1 pair:\n" .  substr($@, 0, 150)."...");

eval {
        my $data_KO = FASTX::ReaderPaired->new({ 
            filename => "$badfile1",
            rev      => "$badfile2",
        });
};
ok(defined $@, "[PE_KO] Unable to create object with wrong R1 and R2 pairs:\n" .  substr($@, 0, 150)."...");

done_testing();
