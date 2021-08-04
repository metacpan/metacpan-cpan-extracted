use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;

# TEST: Retrieves sequences from a test FASTA file
use_ok 'FASTX::Reader';
my $seq_file = "$RealBin/../data/encodings/test-lf.fa";
my $win_file = "$RealBin/../data/encodings/test-crlf.fa";
# Check required input file
if (! -e $seq_file or ! -e $win_file) {
  print STDERR "Skip test: $seq_file not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq_file" });
my $windata = FASTX::Reader->new({ filename => "$win_file" });

my $c = 0;
while (my $r = $data->getRead() ) {
  $c++;
  my $w = $windata->getRead();
  ok($w->{name} eq $r->{name}, "Sequence $c has the same name $w->{name}");
  ok(length($w->{seq}) eq length($r->{seq}), "Sequence $c has the same length $w->{name}");

}
done_testing();
