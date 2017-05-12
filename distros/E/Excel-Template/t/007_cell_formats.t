use strict;

use Test::More tests => 4;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => 't/007.xml',
);
isa_ok( $object, $CLASS );

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_worksheet( 'cell' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', '', '1' )
Spreadsheet::WriteExcel::add_format( 'bold', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '1', '', '2' )
Spreadsheet::WriteExcel::add_format( 'bold', '1', 'italic', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '2', '', '3' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__
