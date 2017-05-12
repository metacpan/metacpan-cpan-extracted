use Test::More qw(no_plan);
use Games::Nintendo::Wii::Mii;

{
    my @mii_files = glob("./sample/*.mii");

    for my $mii_file (@mii_files) {
        my Games::Nintendo::Wii::Mii $mii = Games::Nintendo::Wii::Mii->new;

        my $mii_binary;
        open(MII, $mii_file) || die(qq|Can't open file $mii_file|);
        read(MII, $mii_binary, -s $mii_file);
        close(MII);

        my $mii_test_file = $mii_file . ".test";
        $mii->parse_from_binary($mii_binary);
        $mii->save_to_file($mii_test_file);

        is(-s $mii_test_file, -s $mii_file);

        my $mii_test_binary;
        open(MIITEST, $mii_test_file) || die(qq|Can't open file $mii_test_file|);
        read(MIITEST, $mii_test_binary, -s $mii_test_file);
        close(MIITEST);

        is($mii_test_binary, $mii_binary);

        unlink($mii_test_file);
    }
}
