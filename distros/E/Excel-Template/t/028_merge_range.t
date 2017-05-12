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
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', '', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '1', '', '1' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::Worksheet::merge_range( 'A1:B1', 'This is the Foo Range', '2' )
Spreadsheet::WriteExcel::add_worksheet( '' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', '', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '1', '', '1' )
Spreadsheet::WriteExcel::Worksheet::merge_range( 'A1:B1', 'This is the Foo Range2', '2' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__

__DATA__
<workbook>
  <worksheet>
    <cell ref="foo" />
    <cell ref="foo" />
    <format is_merged="1">
      <merge_range ref="foo" text="This is the Foo Range" />
    </format>
  </worksheet>
  <worksheet>
    <cell ref="foo2" />
    <cell ref="foo2" />
    <merge_range ref="foo2">This is the Foo Range2</merge_range>
  </worksheet>
</workbook>
