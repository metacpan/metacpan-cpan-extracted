use strict;
use warnings;
use FindBin qw($Bin);
use Test::More tests => 2;

use_ok 'FASTX::Reader';
my $seq = "$Bin/../data/test.fastq";
#SKIP if seq not found
SKIP: {
    skip "$seq not found\n", 1 if (! -e "$seq");
    my $data = FASTX::Reader->new({ filename => "$seq" });
    isa_ok($data, 'FASTX::Reader');
}
