use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Abi';
# THIS TEST USES A HETERO CHROMATOGRAM (contains ambiguous bases)
my $chromatogram = "$Bin/../data/hetero.ab1";

if (-e "$chromatogram") {
    my $data = FASTX::Abi->new({ filename => "$chromatogram" });
    my $fastq_string = $data->get_fastq('sequence_name');
    my @lines = split /\n/, $fastq_string;

    ok($#lines == 7, "Got 8 lines (coherent with 2 fastq sequences)");

    ok( (substr($lines[0], 0, 1) eq '@' and substr($lines[4], 0, 1) eq '@'), "Sequence headers found");
    ok( (substr($lines[2], 0, 1) eq '+' and substr($lines[6], 0, 1) eq '+'), "Sequence separator found");
    ok( length($lines[1]) eq length($lines[3]), "Sequence and quality length is matched (with newline)");
    ok( length($lines[5]) eq length($lines[7]), "Sequence and quality length is matched (with newline)");
  }




done_testing();
