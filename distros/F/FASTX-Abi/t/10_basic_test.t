use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Abi';
my $chromatogram = "$Bin/../data/mt.ab1";

if (-e "$chromatogram") {
    my $data = FASTX::Abi->new({ filename => "$chromatogram" });
    isa_ok($data, 'FASTX::Abi');
}

done_testing();
