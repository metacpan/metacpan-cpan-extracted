use strict;

use Test::More tests => 10;

use lib 't';
use mock;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

{
    mock::reset;
    my $object = $CLASS->new(
        renderer => 'big',
        filename => 't/016.xml',
    );
    isa_ok( $object, $CLASS );

    ok( $object->write_file( 'filename' ), 'Something returned' );

    my @calls = mock::get_calls;
    is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::Big::new( 'filename' )
Spreadsheet::WriteExcel::Big::add_format( '' )
Spreadsheet::WriteExcel::Big::close( '' )
__END_EXPECTED__
}

{
    mock::reset;
    my $object = $CLASS->new(
        renderer => Excel::Template->RENDER_XML,
        filename => 't/016.xml',
    );
    isa_ok( $object, $CLASS );

    ok( $object->write_file( 'filename' ), 'Something returned' );

    my @calls = mock::get_calls;
    is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcelXML::new( 'filename' )
Spreadsheet::WriteExcelXML::add_format( '' )
Spreadsheet::WriteExcelXML::close( '' )
__END_EXPECTED__
}

{
    mock::reset;
    my $object = $CLASS->new(
        renderer => Excel::Template->RENDER_NML,
        filename => 't/016.xml',
    );
    isa_ok( $object, $CLASS );

    ok( $object->write_file( 'filename' ), 'Something returned' );

    my @calls = mock::get_calls;
    is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__
}
