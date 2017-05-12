use strict;

use Test::More tests => 5;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => 't/006.xml',
);
isa_ok( $object, $CLASS );

ok(
    $object->param( 
        test1 => 'test1',
        test2 => 'test2',
    ),
    'Parameters set',
);

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_worksheet( 'cell' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', 'test1', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '1', 'test2', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '2', 'PRE test1 POST', '1' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__
