#!perl

use strict;
use warnings;

use lib 't/lib';
use Excel::Writer::XLSX;
use Excel::Template::XLSX;
use Test::More;
use File::Temp qw(tempfile);

# Can be set to 1 to see the created template and output file during debugging
$File::Temp::KEEP_ALL = 0;

###############################################################################

# Issue with using EWX to create array formulas
# Expected spreadsheet developed by hand.
my $efilename = q[./t/06-cell.xlsx];
TODO: {
  local $TODO = "Restore programmitically generated expected Excel worksheet";
  ok(0, 'Add ability to programmatically generate Excel Worksheet');
}
=for nothing
# Create expected workbook content
my ( $efh, $efilename ) = tempfile( SUFFIX => '.xlsx' );
my $wbk     = Excel::Writer::XLSX->new($efilename);
my $wksheet = $wbk->add_worksheet();
$wksheet->set_row( 0, 20 );
$wksheet->set_column( 'D:D', 25 );

$wksheet->write( 'A1', 'A1' );
$wksheet->write( 'A2', 'A2' );
$wksheet->write_url( 'A3', 'http://www.cpan.org',, 'CPAN' );
my $pct = $wbk->add_format( num_format => '0.00%' );
$wksheet->write( 'A4', 0.5, $pct );

for ( 4 .. 8 ) {
   $wksheet->write( $_, 0, $_ );
   $wksheet->write( $_, 1, $_ * 2 );
}
$wksheet->write( 'C5:C9', '{=TREND(B5:B9,A5:A9)}' );

# These are not tested.  EWX just writes them as strings
$wksheet->write( 'D1', 'TRUE' );
$wksheet->write( 'D2', 'FALSE' );

$wbk->close();
=cut

# Get workbook content as a template
my ( $gfh, $gfilename ) = tempfile( SUFFIX => '.xlsx' );
my ( $self, $twbk ) = Excel::Template::XLSX->new( $gfilename, $efilename );
$self->parse_template();

my $sheet = $twbk->get_worksheet_by_name('Sheet1');

is( int( $sheet->{_row_sizes}{0}[0] ), 20, 'Row Height' );
is( int( $sheet->{_col_info}{3}[0] ), 25, 'Column Width' );

# Test that expected workbook was parsed correctly as a template
for (qw[A1 A2]) {
   my ( $r, $c ) = $self->_cell_to_row_col($_);
   my $si = $sheet->{_table}{$r}{$c}[1];
   is($sheet->{_table}{$r}{$c}[1],
      $twbk->{_str_table}{$_},
      "String lookup $_"
   );
}

# warn dumper( $sheet->{_table} );
is( $sheet->{_table}{4}{2}[1], 'TREND(B5:B9,A5:A9)', "Array Formula" );

$twbk->close();

warn "Files \n$efilename\n$gfilename\n not deleted\n"
    if $File::Temp::KEEP_ALL;
done_testing();

