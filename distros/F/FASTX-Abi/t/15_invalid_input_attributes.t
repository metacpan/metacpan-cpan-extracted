use 5.012;
use warnings;
use FindBin qw($Bin);
use Test::More;
use Data::Dumper;
use_ok 'FASTX::Abi';
# THIS TEST USES A HETERO CHROMATOGRAM (contains ambiguous bases)
my $chromatogram = "$Bin/../data/mt.ab1";

if (-e "$chromatogram") {

    my $eval = eval {
    my $data = FASTX::Abi->new({
          filename => "$chromatogram",
          bad_attribute => 1
        });
        1;
    };

    ok(! defined $eval, "Module crashed receiving bad_attribute");

    $eval = eval {
    my $data = FASTX::Abi->new({
          filename => "$chromatogram.wrong",

        });
        1;
    };
    if (! -e "$chromatogram.wrong") {
      ok(! defined $eval, "Module crashed receiving wrong input file");
    }

}




done_testing();
