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
Spreadsheet::WriteExcel::Worksheet::set_row( '0', '8' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', '', '1' )
Spreadsheet::WriteExcel::Worksheet::set_row( '1', '10' )
Spreadsheet::WriteExcel::Worksheet::write( '1', '0', '', '1' )
Spreadsheet::WriteExcel::Worksheet::set_row( '2', '6' )
Spreadsheet::WriteExcel::Worksheet::write( '2', '0', '', '1' )
Spreadsheet::WriteExcel::Worksheet::set_row( '3', '16' )
Spreadsheet::WriteExcel::Worksheet::write( '3', '0', '', '1' )
Spreadsheet::WriteExcel::Worksheet::set_row( '4', '4' )
Spreadsheet::WriteExcel::Worksheet::write( '4', '0', '', '1' )
Spreadsheet::WriteExcel::Worksheet::set_row( '5', '8' )
Spreadsheet::WriteExcel::Worksheet::write( '5', '0', '', '1' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__

__DATA__
<workbook>
  <worksheet height="8">
    <row>
      <cell />
    </row>
    <row height="+2">
      <cell />
    </row>
    <row height="-2">
      <cell />
    </row>
    <row height="*2">
      <cell />
    </row>
    <row height="/2">
      <cell />
    </row>
    <row height="/0">
      <cell />
    </row>
  </worksheet>
</workbook>

