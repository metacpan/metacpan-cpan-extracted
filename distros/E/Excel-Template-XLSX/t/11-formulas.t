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

# Create expected workbook content
my ( @efh, @efilename );
for ( 0 .. 1 ) {
   ( $efh[$_], $efilename[$_] ) = tempfile( SUFFIX => '.xlsx' );

   my $wbk     = Excel::Writer::XLSX->new( $efilename[$_] );
   my $wksheet = $wbk->add_worksheet();

   $wksheet->write( 'A1', 'A1' . " $_" );
   $wksheet->write( 'A2', 'A2' . " $_" );
   my $dec = '0' x ( $_ + 1 );
   my $pct = $wbk->add_format( num_format => "0.${dec}%" );
   $wksheet->write( 'A3', 0.5, $pct );
   $wbk->close();
}

# Get workbook content as a template
my ( $gfh, $gfilename ) = tempfile( SUFFIX => '.xlsx' );
my ( $self, $twbk )
    = Excel::Template::XLSX->new( $gfilename, $efilename[0], $efilename[1] );
$self->parse_template();

# Get string table lookup by ID, not value
my $hstring = { reverse %{ $twbk->{_str_table} } };

is( get_cell( $twbk, $hstring, 0, 0 ), 'A1 0', "Sheet 1 A1" );
is( get_cell( $twbk, $hstring, 0, 1 ), 'A2 0', "Sheet 1 A2" );

is( get_cell( $twbk, $hstring, 1, 0 ), 'A1 1', "Sheet 2 A1" );
is( get_cell( $twbk, $hstring, 1, 1 ), 'A2 1', "Sheet 2 A2" );

my $sheet0 = $twbk->sheets(0);
is( $sheet0->{_table}{2}{0}[2]{_num_format},
   '0.0%', "Template 1 Number format" );
my $sheet1 = $twbk->sheets(1);
is( $sheet1->{_table}{2}{0}[2]{_num_format},
   '0.00%', "Template 2 Number format" );

is( $sheet0->get_name(), 'Sheet1',    "Template 1 Sheet 1 name" );
is( $sheet1->get_name(), 'Sheet1(1)', "Template 2 Sheet 1 renamed" );

$twbk->close();

warn "Files \n$efilename[0]\n$efilename[1]\n$gfilename\n not deleted\n"
    if $File::Temp::KEEP_ALL;
done_testing();

###############################################################################
sub get_cell {
   my ( $wb, $h, $sheet_idx, $row ) = @_;
   my $sheet     = $wb->sheets($sheet_idx);
   my $string_id = $sheet->{_table}{$row}{0}[1];
   return $h->{$string_id};
}

