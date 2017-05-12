use strict;

use Test::More tests => 5;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => 't/011.xml',
);
isa_ok( $object, $CLASS );

ok(
    $object->param( 
        loopy => [
            { int => 0, char => 'n' },
            { int => 0, char => 'y' },
            { int => 1, char => 'z' },
            { int => -1, char => 'y' },
        ],
    ),
    'Parameters set',
);

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_worksheet( 'conditional' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', 'bool false', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '1', 'num == passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '2', 'num >= passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '3', 'num <= passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '4', 'char ne passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '5', 'char lt passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '6', 'char le passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '1', '0', 'bool false', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '1', '1', 'num == passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '1', '2', 'num >= passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '1', '3', 'num <= passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '1', '4', 'char eq passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '1', '5', 'char ge passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '1', '6', 'char le passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '2', '0', 'bool true', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '2', '1', 'num != passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '2', '2', 'num > passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '2', '3', 'num >= passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '2', '4', 'char ne passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '2', '5', 'char gt passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '2', '6', 'char ge passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '0', 'bool true', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '1', 'num != passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '2', 'num < passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '3', 'num <= passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '4', 'char eq passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '5', 'char ge passes', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '6', 'char le passes', '1' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__
