#!perl

use strict;
use warnings;

use lib 't/lib';
use Excel::Writer::XLSX;
use Excel::Template::XLSX;
use Test::More;
use File::Temp qw(tempfile);

   use Mojo::Util qw(dumper);

# Can be set to 1 to see the created template and output file during debugging
$File::Temp::KEEP_ALL = 0;

###############################################################################

# Create expected workbook content
my ( $efh, $efilename ) = tempfile( SUFFIX => '.xlsx' );

my $wbk     = Excel::Writer::XLSX->new( $efilename );
my $wksheet = $wbk->add_worksheet();

$wksheet->write( 'A1', 'A1' );
$wksheet->write( 'A2', 'A2' );
my $pct = $wbk->add_format( num_format => "0.1%" );
$wksheet->write( 'A3', 0.5, $pct );
$wbk->close();

# Get workbook content as a template
my ( $gfh, $gfilename ) = tempfile( SUFFIX => '.xlsx' );
my ( $self, $twbk ) = Excel::Template::XLSX->new( $gfilename, $efilename );
$self->parse_template();

# Get string table lookup by ID, not value
my $hstring = $twbk->{_str_table};
# warn "hstring is ", dumper( $hstring );


TODO: {
  local $TODO = <<"EOF";
Find a way to read output file, and see if array formula survives.  
Consider is_deeply on sheet XML.
For now, set KEEP_ALL to 1, and examine output file by hand.
EOF
  is( $hstring->{A1}, '0', "Sheet 1 A1 in row 0" );
  is( $hstring->{A2}, '1', "Sheet 1 A2 in row 1" );
}
# is( get_cell( $twbk, $hstring->{0}, 0, 0 ), 'A1', "Sheet 1 A1" );
# is( get_cell( $twbk, $hstring->{1}, 0, 1 ), 'A2', "Sheet 1 A2" );

my $sheet = $twbk->sheets(0);
is( $sheet->{_table}{2}{0}[2]{_num_format}, '0.1%', "Template 1 Number format" );

is( $sheet->get_name(), 'Sheet1',    "Template 1 Sheet 1 name" );
$twbk->close();

warn "Files \n$efilename\n$efilename\n$gfilename\n not deleted\n" if $File::Temp::KEEP_ALL;
done_testing();

###############################################################################
sub get_cell {
   my ( $wb, $h, $sheet_idx, $row ) = @_;
   my $sheet     = $wb->sheets($sheet_idx);
   my $string_id = $sheet->{_table}{$row}{0}[1];
   # warn "row is $row ", dumper( $sheet->{_table} );
   return $h->{$string_id};
}

