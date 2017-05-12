BEGIN{ $^W = 0 }
use strict;

use Test::More tests => 4;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    file => \*DATA,
);
isa_ok( $object, $CLASS );

ok( $object->write_file( 'filename' ), 'Successfuly wrote file' );

my @calls = mock::get_calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_worksheet( '' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', 'before', '1' )
Spreadsheet::WriteExcel::Worksheet::insert_bitmap( '0', '1', '/full/path', '0', '0', '0', '0' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '2', 'after', '1' )
Spreadsheet::WriteExcel::Worksheet::insert_bitmap( '0', '3', '/full/path', '2', '2', '0', '0' )
Spreadsheet::WriteExcel::Worksheet::insert_bitmap( '0', '4', '/full/path', '0', '0', '2', '2' )
Spreadsheet::WriteExcel::Worksheet::insert_bitmap( '0', '5', '/full/path', '0', '1', '1.1', '0' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__

__DATA__
<workbook>
  <worksheet>
    <cell text="before" />
    <image path="/full/path" />
    <cell text="after" />
    <image path="/full/path" offset="2,2"/>
    <image path="/full/path" scale="2,2"/>
    <image path="/full/path" scale="1.1,0" offset="0,1"/>
  </worksheet>
</workbook>
