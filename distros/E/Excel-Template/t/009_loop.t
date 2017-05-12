BEGIN{ $^W = 0 }
use strict;

use Test::More tests => 5;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => 't/009.xml',
);
isa_ok( $object, $CLASS );

ok(
    $object->param( 
        loopy => [
            { value => 1 },
            { value => 2 },
            { value => 3 },
        ],
        outer => [
            { iter => 'a', inner => [ { value => 1 }, { value => 2 } ] },
            { iter => 'b', inner => [ { value => 3 }, { value => 4 } ] },
        ],
        worksheets => [
            { value => 1 },
            { value => 2 },
            { value => 3 },
        ],
        no_iters => [
        ],
    ),
    'Parameters set',
);

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_worksheet( 'loops' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', '1', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '1', 'text', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '1', '0', '2', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '1', '1', 'text', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '2', '0', '3', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '2', '1', 'text', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '0', 'a', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '1', '1', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '2', '2', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '4', '0', 'b', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '4', '1', '3', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '4', '2', '4', '1' )
Spreadsheet::WriteExcel::add_worksheet( '1' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::add_worksheet( '2' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::add_worksheet( '3' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__
