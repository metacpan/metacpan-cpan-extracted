use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

use_ok 'FASTX::Abi';
my $chromatogram_dir = "$RealBin/../data/";


for my $chromatogram (glob "$chromatogram_dir/*.a*") {
  if (-e "$chromatogram") {
      my $data = FASTX::Abi->new({ filename => "$chromatogram" });
      isa_ok($data, 'FASTX::Abi');
  }
}
done_testing();
