use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Abi';
my $chromatogram_dir = "$Bin/../data/";


for my $chromatogram (glob "$chromatogram_dir/*.a*") {
  if (-e "$chromatogram") {
      my $data = FASTX::Abi->new({ filename => "$chromatogram" });
      isa_ok($data, 'FASTX::Abi');
  }
}
done_testing();
