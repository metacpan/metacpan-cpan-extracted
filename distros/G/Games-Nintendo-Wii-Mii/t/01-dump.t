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

        $mii->parse_from_binary($mii_binary);
        
        is($mii->to_hexdump, unpack("H*", $mii_binary));
    }
}
