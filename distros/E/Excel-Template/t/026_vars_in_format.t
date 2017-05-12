BEGIN{ $^W = 0 }
use strict;

use Test::More tests => 5;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => 't/026_vars_in_format.xml',
);
isa_ok( $object, $CLASS );

ok(
    $object->param( 
        loopy => [
            { value => 1, color => 'red'     },
            { value => 2, color => 'green'   },
            { value => 3, color => 'yellow'  },
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
Spreadsheet::WriteExcel::add_format( 'bg_color', 'red' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', '1', '2' )
Spreadsheet::WriteExcel::add_format( 'bg_color', 'green' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '1', '2', '3' )
Spreadsheet::WriteExcel::add_format( 'bg_color', 'yellow' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '2', '3', '4' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__
