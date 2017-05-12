use strict;

use Test::More tests => 4;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => 't/030.xml',
);
isa_ok( $object, $CLASS );

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;

is_deeply([@calls],[
    q[Spreadsheet::WriteExcel::new( 'filename' )],
    q[Spreadsheet::WriteExcel::add_format( '' )],
    q[Spreadsheet::WriteExcel::add_worksheet( 'cell' )],
    q[Spreadsheet::WriteExcel::Worksheet::new( '' )],
    q[Spreadsheet::WriteExcel::Worksheet::write( '0', '0', 'Test1', '1' )],
    q[Spreadsheet::WriteExcel::Worksheet::write_comment( '0', '0', 'Test1' )],
    q[Spreadsheet::WriteExcel::Worksheet::write( '0', '1', 'Test2', '1' )],
    q[Spreadsheet::WriteExcel::Worksheet::write_comment( '0', '1', 'Test2' )],
    q[Spreadsheet::WriteExcel::Worksheet::write( '0', '2', 'Test3', '1' )],
    q[Spreadsheet::WriteExcel::close( '' )],
],'Calls match up');
