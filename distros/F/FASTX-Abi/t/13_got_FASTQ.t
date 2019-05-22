use 5.014;
use Data::Dumper;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Abi';
# THIS TEST USES A HETERO CHROMATOGRAM (contains ambiguous bases)

my $chromatogram_dir = "$Bin/../data/";


for my $chromatogram (glob "$chromatogram_dir/*.a*") {
  if (-e "$chromatogram") {
      my $data = FASTX::Abi->new({ filename => "$chromatogram" });
      my $seq_name = $data->{sequence_name};
      my $fastq_string = $data->get_fastq('sequence_name');
      my @lines = split /\n/, $fastq_string;

      my $expected_seqs = 1;
      $expected_seqs = 2 if ($data->{hetero});
      my $expected_index = (4 * $expected_seqs) - 1;
      ok($#lines == $expected_index, "[$seq_name] Got 8 lines (coherent with 2 fastq sequences)");

      #check first sequence:
      if ($expected_seqs == 1) {
        ok( (substr($lines[0], 0, 1) eq '@'), "[$seq_name] Sequence headers found");
        ok( (substr($lines[2], 0, 1) eq '+'), "[$seq_name] Sequence separator found");
        ok( length($lines[1]) eq length($lines[3]), "[$seq_name] Sequence and quality length is matched (with newline)");
      } else {
        ok( (substr($lines[0], 0, 1) eq '@' and substr($lines[4], 0, 1) eq '@'), "[$seq_name] Sequence headers found");
        ok( (substr($lines[2], 0, 1) eq '+' and substr($lines[6], 0, 1) eq '+'), "[$seq_name] Sequence separator found");
        ok( length($lines[1]) eq length($lines[3]), "[$seq_name] Sequence and quality length is matched (with newline)");
        ok( length($lines[5]) eq length($lines[7]), "[$seq_name] Sequence and quality length is matched (with newline)");
      }
    }
}



done_testing();
