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
      my $eval = eval {
        my $fastq_string = $data->get_fastq('sequence_name', 'INVALID');
      };
      ok(defined $@, "Invalid quality supplied: get_fastq() failed");
    }
}



done_testing();
