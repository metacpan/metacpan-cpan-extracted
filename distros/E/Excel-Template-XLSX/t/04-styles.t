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

# Create expected workbook content
my ( $efh, $efilename ) = tempfile( SUFFIX => '.xlsx' );
my $wbk     = Excel::Writer::XLSX->new($efilename);
my $format1 = $wbk->add_format();
$format1->set_color('red');
$format1->set_align('center');
$format1->set_valign('top');
$format1->set_indent(2);
$format1->set_text_wrap(1);
$format1->set_rotation(45);
$format1->set_font('Helvetica');
$format1->set_size(14);
$format1->set_bold();
$format1->set_italic();
$format1->set_underline();

my $format2 = $wbk->add_format();
$format2->set_shrink(1);

my $cell_format = $wbk->add_format();
$cell_format->set_border(9);    # Dash Dot Weight 2
$cell_format->set_border_color('#00FF00');

my $diag_format = $wbk->add_format(
   diag_type   => 3,
   diag_border => 7,
   diag_color  => 'red',
);
my $pat_format = $wbk->add_format();
$pat_format->set_pattern(5);
$pat_format->set_bg_color('#AA0000');
$pat_format->set_fg_color('#00AA00');

my $num_format1 = $wbk->add_format( num_format => 'dd/mm/yy hh:mm' );

my $sheet = $wbk->add_worksheet();
$sheet->set_row( 0, 90 );    # Increase row/column size to see effects
$sheet->set_column( 'A:C', 30 );
$sheet->write( 0, 0, 'Formatted', $format1 );
$sheet->write( 0, 1,
   'Bold,italic,undeline,red,center,indent, wrap,top,rotate,Helvetica,14,',
   $format2 );
$sheet->write( 0, 2, 'Border',   $cell_format );
$sheet->write( 1, 0, 'Diagonal', $diag_format );
$sheet->write( 2, 0, 'Pattern',  $pat_format );
$sheet->write( 3, 0, 4050.1,     $num_format1 );

# Zip codes:
# string tested in shared strings
my $zip_format = $wbk->add_format( num_format => '00000' );
$sheet->write( 4, 0, '01111', $zip_format );
$sheet->keep_leading_zeros();    # Just converts number to a string
$sheet->write( 5, 0, '01111' );

my $prot_format = $wbk->add_format( 'hidden' => 1, 'locked' => 1 );
$sheet->write_formula( 6, 0, '="Locked" & " Hidden"', $prot_format );

$wbk->close();

# Get workbook content as a template
my ( $gfh, $gfilename ) = tempfile( SUFFIX => '.xlsx' );
my ( $self, $twbk ) = Excel::Template::XLSX->new( $gfilename, $efilename );
$self->parse_template();

# Get the format object referenced by cell 0,0
my $got_sheet = $twbk->get_worksheet_by_name('Sheet1');

my $got_format1 = $got_sheet->{_table}{0}{0}[2];
is( $got_format1->{_color},        '#FF0000',   "Format color" );
is( $got_format1->{_bold},         '1',         "Format Bold" );
is( $got_format1->{_text_h_align}, '1',         "Format Align Center" );
is( $got_format1->{_text_v_align}, '1',         "Format Vertical Align Top" );
is( $got_format1->{_indent},       '2',         "Format Indent" );
is( $got_format1->{_text_wrap},    '1',         "Format Text Wrap" );
is( $got_format1->{_rotation},     '45',        "Format Rotation" );
is( $got_format1->{_font},         'Helvetica', "Format font name" );
is( $got_format1->{_size},         '14',        "Format font size" );
is( $got_format1->{_italic},       '1',         "Format italic" );
is( $got_format1->{_underline},    '1',         "Format underlined" );

my $got_format2 = $got_sheet->{_table}{0}{1}[2];
is( $got_format2->{_shrink}, '1', "Format Shrink" );

my $got_format3 = $got_sheet->{_table}{0}{2}[2];

for (qw[top bottom left right]) {
   is( $got_format3->{"_$_"},         '9',       "Border Style $_" );
   is( $got_format3->{"_${_}_color"}, '#00FF00', "Border Color $_" );
}

my $got_format4 = $got_sheet->{_table}{1}{0}[2];
is( $got_format4->{'_diag_type'},   '3',       'Diagonal Border Type' );
is( $got_format4->{'_diag_color'},  '#FF0000', 'Diagonal Border Color' );
is( $got_format4->{'_diag_border'}, '7',       'Diagonal Border Style' );

my $got_format5 = $got_sheet->{_table}{2}{0}[2];
is( $got_format5->{'_pattern'},  '5',       'Pattern Type' );
is( $got_format5->{'_bg_color'}, '#AA0000', 'Pattern Background Color' );
is( $got_format5->{'_fg_color'}, '#00AA00', 'Pattern ForegroundColor' );

my $got_format6 = $got_sheet->{_table}{3}{0}[2];

#warn Dump $got_format6;
is($got_format6->{'_num_format'},
   'dd/mm/yy hh:mm',
   'Number Format date/time'
);

my $got_format7 = $got_sheet->{_table}{4}{0}[2];
is( $got_format7->{'_num_format'}, '00000', 'Number Format zip code' );

my $got_format8 = $got_sheet->{_table}{6}{0}[2];
is( $got_format8->{'_locked'}, '1', 'Protection locked' );
is( $got_format8->{'_hidden'}, '1', 'Protection hidden' );

$twbk->close();

warn "Files \n$efilename\n$gfilename\n not deleted\n"
    if $File::Temp::KEEP_ALL;
done_testing();

__END__

