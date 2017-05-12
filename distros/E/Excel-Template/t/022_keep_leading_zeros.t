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
Spreadsheet::WriteExcel::Worksheet::keep_leading_zeros( '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '1', 'inside', '1' )
Spreadsheet::WriteExcel::Worksheet::keep_leading_zeros( '0' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '2', 'after', '1' )
Spreadsheet::WriteExcel::add_worksheet( '' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::keep_leading_zeros( '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', 'within', '1' )
Spreadsheet::WriteExcel::add_worksheet( '' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', 'after', '1' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__

__DATA__
<workbook>
  <worksheet>
    <cell text="before" />
    <keep_leading_zeros>
      <cell text="inside" />
    </keep_leading_zeros>
    <cell text="after" />
  </worksheet>
  <keep_leading_zeros>
    <worksheet>
      <cell text="within" />
    </worksheet>
  </keep_leading_zeros>
  <worksheet>
    <cell text="after" />
  </worksheet>
</workbook>

