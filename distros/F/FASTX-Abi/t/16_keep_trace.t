use 5.012;
use warnings;
use FindBin qw($Bin);
use Test::More;
use Data::Dumper;
use_ok 'FASTX::Abi';
# Test TRACE object
my $chromatogram = "$Bin/../data/mt.ab1";

if (-e "$chromatogram") {

    # KEEP ABI = 1
    my $data = FASTX::Abi->new({
        filename => "$chromatogram",
        keep_abi => 1,
    });

    ok( defined $data->{chromas}, "ABIF object retained");
    ok( $data->{chromas}->{_ABIF_VERSION} > 1, "ABIF object retained, with version");

    # KEEP ABI = 0
    my $nodata = FASTX::Abi->new({
        filename => "$chromatogram",
        keep_abi => 0,
    });
    ok( !defined($nodata->{chromas}), "ABIF object NOT retained [passing keep_abi=0]");

    # KEEP ABI = default
    my $nodata_def = FASTX::Abi->new({
        filename => "$chromatogram",
    });

    ok( !defined($nodata_def->{chromas}), "ABIF object NOT retained [by default]");
}

done_testing();
