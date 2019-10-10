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
my $wbk = Excel::Writer::XLSX->new($efilename);
my $center = $wbk->add_format();
$center->set_align( 'center' );
$center->set_align( 'vcenter' );
my $right = $wbk->add_format();
$right->set_align( 'right' );

my $red = $wbk->add_format();
$red->set_color('red');
my $wksheet = $wbk->add_worksheet();
$wksheet->write( 'A1', 'A1A1' );
$wksheet->write_rich_string( 'A2', 'Some ', $red, 'red ', 'text' );
$wksheet->merge_range_type('rich_string', 'A3:B4', 'Some ', $red, 'red ', 'text', $center);
$wksheet->merge_range_type('formula', 'A5:B7', q[=A1 & "B1B1"], $right);
$wbk->close();

# Get workbook content as a template
my ( $gfh, $gfilename ) = tempfile( SUFFIX => '.xlsx' );
my ( $self, $twbk ) = Excel::Template::XLSX->new( $gfilename, $efilename );
$self->parse_template();

is_deeply($twbk->{_sheetnames}->{"Sheet1"}->{_merge}, $wbk->{_sheetnames}->{"Sheet1"}->{_merge}, "Sheet Data Structure");

TODO: {
  local $TODO = "Future testing of _table hash";
  my $h = [];
  $h->[0] =   $wbk->{_sheetnames}->{"Sheet1"}->{_table};
  $h->[1] =  $twbk->{_sheetnames}->{"Sheet1"}->{_table};
  is_deeply($h->[0], $h->[1], "Table Data Structure");
#  for (0..1) {
#    $h[$_]->{4}{0}[2] = undef;
#  }
}

$twbk->close();

warn "Files \n$efilename\n$gfilename\n not deleted\n"
    if $File::Temp::KEEP_ALL;
done_testing;

__END__

