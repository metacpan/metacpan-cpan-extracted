use strict;

use Test::More tests => 4;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => 't/005.xml',
);
isa_ok( $object, $CLASS );

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_format( 'bold', '1' )
Spreadsheet::WriteExcel::add_format( 'hidden', '1' )
Spreadsheet::WriteExcel::add_format( 'italic', '1' )
Spreadsheet::WriteExcel::add_format( 'locked', '1' )
Spreadsheet::WriteExcel::add_format( 'font_outline', '1' )
Spreadsheet::WriteExcel::add_format( 'font_shadow', '1' )
Spreadsheet::WriteExcel::add_format( 'font_strikeout', '1' )
Spreadsheet::WriteExcel::add_format( 'shrink', '1' )
Spreadsheet::WriteExcel::add_format( 'text_wrap', '1' )
Spreadsheet::WriteExcel::add_format( 'text_justlast', '1' )
Spreadsheet::WriteExcel::add_format( 'size', '3' )
Spreadsheet::WriteExcel::add_format( 'num_format', '3' )
Spreadsheet::WriteExcel::add_format( 'underline', '3' )
Spreadsheet::WriteExcel::add_format( 'rotation', '3' )
Spreadsheet::WriteExcel::add_format( 'indent', '3' )
Spreadsheet::WriteExcel::add_format( 'pattern', '3' )
Spreadsheet::WriteExcel::add_format( 'border', '3' )
Spreadsheet::WriteExcel::add_format( 'bottom', '3' )
Spreadsheet::WriteExcel::add_format( 'top', '3' )
Spreadsheet::WriteExcel::add_format( 'left', '3' )
Spreadsheet::WriteExcel::add_format( 'right', '3' )
Spreadsheet::WriteExcel::add_format( 'font', '3' )
Spreadsheet::WriteExcel::add_format( 'color', '3' )
Spreadsheet::WriteExcel::add_format( 'align', '3' )
Spreadsheet::WriteExcel::add_format( 'valign', '3' )
Spreadsheet::WriteExcel::add_format( 'bg_color', '3' )
Spreadsheet::WriteExcel::add_format( 'fg_color', '3' )
Spreadsheet::WriteExcel::add_format( 'border_color', '3' )
Spreadsheet::WriteExcel::add_format( 'bottom_color', '3' )
Spreadsheet::WriteExcel::add_format( 'top_color', '3' )
Spreadsheet::WriteExcel::add_format( 'left_color', '3' )
Spreadsheet::WriteExcel::add_format( 'right_color', '3' )
Spreadsheet::WriteExcel::add_format( 'bold', '1', 'italic', '1' )
Spreadsheet::WriteExcel::add_format( 'bold', '1', 'hidden', '1', 'italic', '1' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__
