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

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_worksheet( 'landscape' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::set_landscape( '' )
Spreadsheet::WriteExcel::add_worksheet( 'landscape2' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::set_landscape( '' )
Spreadsheet::WriteExcel::add_worksheet( 'portrait' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::set_portrait( '' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__

__DATA__
<workbook>
  <worksheet name="landscape" landscape="1" />
  <scope landscape="1">
    <worksheet name="landscape2" />
    <worksheet name="portrait" portrait="1" />
  </scope>
</workbook>
