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
my ( $efh, $efilename ) = tempfile( SUFFIX => '.xlsx' );

my $wbk     = Excel::Writer::XLSX->new( $efilename );
my $format = $wbk->add_format(
    border => 6,
    valign => 'vcenter',
    align  => 'center',
);

my $sheet1 = $wbk->add_worksheet();
$sheet1->merge_range( 'C2:F2', 'Sheet1 C2F2', $format );

my $sheet2 = $wbk->add_worksheet();
$sheet2->merge_range( 'C2:L6', 'Sheet2 C2L6', $format );
$wbk->close();

# Get workbook content as a template
my ( $gfh, $gfilename ) = tempfile( SUFFIX => '.xlsx' );
my ( $self, $twbk ) = Excel::Template::XLSX->new( $gfilename, $efilename );
$self->parse_template();

for (1..2) {
  is_deeply($twbk->{_sheetnames}->{"Sheet$_"}->{_merge}, $wbk->{_sheetnames}->{"Sheet$_"}->{_merge}, "Sheet$_ Data Structure");
}
$twbk->close();

warn "Files \n$efilename\n$efilename\n$gfilename\n not deleted\n" if $File::Temp::KEEP_ALL;
done_testing();


