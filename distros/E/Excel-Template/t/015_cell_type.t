use strict;

use Test::More tests => 4;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => 't/015.xml',
);
isa_ok( $object, $CLASS );

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_worksheet( 'cell_type' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::write_string( '0', '0', 'String', '1' )
Spreadsheet::WriteExcel::Worksheet::write_number( '0', '1', 'Number', '1' )
Spreadsheet::WriteExcel::Worksheet::write_blank( '0', '2', 'Blank', '1' )
Spreadsheet::WriteExcel::Worksheet::write_url( '0', '3', 'URL', '1' )
Spreadsheet::WriteExcel::Worksheet::write_formula( '0', '4', 'Formula', '1' )
Spreadsheet::WriteExcel::Worksheet::write_date_time( '0', '5', 'DateTime', '1' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__
