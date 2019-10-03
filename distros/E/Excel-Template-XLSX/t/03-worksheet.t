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

# Create expected worksheet content
my ( $efh, $efilename ) = tempfile( SUFFIX => '.xlsx' );
my $wbk     = Excel::Writer::XLSX->new($efilename);
my $wksheet = $wbk->add_worksheet();

$wksheet->repeat_rows( 1, 1 );

$wksheet->repeat_columns( 1, 2 );
$wksheet->print_area('A1:H20');
$wbk->define_name( 'Exchange_rate', '=0.96' );
$wbk->define_name( 'Sales',         '=Sheet1!$G$1:$H$10' );

$wbk->close();

# Get workbook content as a template
my ( $gfh, $gfilename ) = tempfile( SUFFIX => '.xlsx' );
my ( $self, $twbk ) = Excel::Template::XLSX->new( $gfilename, $efilename );
$self->parse_template();

my @df = $twbk->{_defined_names};
my ( $got_exchange, $got_sales );

for my $list1 (@df) {
   for my $list2 (@$list1) {
      $got_exchange = $list2->[2] if $list2->[0] =~ m/Exchange/;
      $got_sales    = $list2->[2] if $list2->[0] =~ m/Sales/;
   }
}

is( $got_exchange, '0.96', 'Defined Name Exchange_rate' );
is( $got_sales, 'Sheet1!$G$1:$H$10', 'Defined Name Sales' );

my $sheet = $twbk->get_worksheet_by_name('Sheet1');

my $got_print_area  = $sheet->{_print_area};
my $got_repeat_cols = $sheet->{_repeat_cols};
my $got_repeat_rows = $sheet->{_repeat_rows};

is( $got_print_area,  'Sheet1!$A$1:$H$20', 'Print Area' );
is( $got_repeat_rows, 'Sheet1!$2:$2',      'Rows to repeat at Top' );
is( $got_repeat_cols, 'Sheet1!$B:$C',      'Cols to repeat at Left' );

$twbk->close();

warn "Files \n$efilename\n$gfilename\n not deleted\n"
    if $File::Temp::KEEP_ALL;
done_testing();
