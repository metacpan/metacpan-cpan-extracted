use strict;

use Test::More tests => 4;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    filename => \*DATA,
);
isa_ok( $object, $CLASS );

ok( my $output = $object->output( 'filename' ), "Something returned" );

my $val = <<__END_EXPECTED__;
Spreadsheet::WriteExcel::new\\( 'GLOB\\([^)]+\\)' \\)
Spreadsheet::WriteExcel::add_format\\( '' \\)
Spreadsheet::WriteExcel::close\\( '' \\)
__END_EXPECTED__

like( $output, qr/$val/, 'Calls match up' );

__DATA__
<workbook />
