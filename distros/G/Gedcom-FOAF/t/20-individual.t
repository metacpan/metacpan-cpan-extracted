use Test::More tests => 4;

use_ok( 'Gedcom::FOAF' );
use Gedcom;

my $gedcom = Gedcom->new(
    gedcom_file => 't/data/royal.ged',
    read_only   => 1,
);

isa_ok( $gedcom, 'Gedcom' );

my $I72 = $gedcom->get_individual( 'I72' );

isa_ok( $I72, 'Gedcom::Individual' );
my $foaf = $I72->as_foaf;

is( $foaf, read_file( 't/data/I72.xml' ), 'FOAF for individuals' );

sub read_file {
    my $filename = shift;
    open( my $file, $filename );
    my $data = do { local $/; <$file>; };
    close( $file );
    return $data;
}
