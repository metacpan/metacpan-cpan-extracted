use Test::More tests => 4;

use_ok( 'Gedcom::FOAF' );
use Gedcom;

my $gedcom = Gedcom->new(
    gedcom_file => 't/data/royal.ged',
    read_only   => 1,
);

isa_ok( $gedcom, 'Gedcom' );

my $F45 = $gedcom->get_family( 'F45' );

isa_ok( $F45, 'Gedcom::Family' );
my $foaf = $F45->as_foaf;

is( $foaf, read_file( 't/data/F45.xml' ), 'FOAF for families' );

sub read_file {
    my $filename = shift;
    open( my $file, $filename );
    my $data = do { local $/; <$file>; };
    close( $file );
    return $data;
}
