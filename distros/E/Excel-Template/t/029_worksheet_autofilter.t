use strict;

use Test::More tests => 4;

use lib 't';
use mock;
use Data::Dumper;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => \*DATA,
);
isa_ok( $object, $CLASS );

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;
# warn Dumper \@calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_worksheet( '' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::autofilter( 'A1:D11' )
Spreadsheet::WriteExcel::add_worksheet( '' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::Worksheet::autofilter( '0', '0', '10', '3' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__

__DATA__
<workbook>
  <worksheet autofilter='A1:D11' />
  <worksheet autofilter='0, 0, 10, 3' />
</workbook>
