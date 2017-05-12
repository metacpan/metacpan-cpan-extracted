use strict;

use Test::More tests => 4;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => 't/014.xml',
);
isa_ok( $object, $CLASS );

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_worksheet( 'heightwidth' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::set_row( '0', '30' )
Spreadsheet::WriteExcel::Worksheet::set_column( '0', '0', '10' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', '1', '1' )
Spreadsheet::WriteExcel::Worksheet::set_column( '1', '1', '0.5' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '1', '1', '1' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__
