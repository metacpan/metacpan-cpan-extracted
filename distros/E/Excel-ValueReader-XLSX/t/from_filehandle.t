use utf8;
use strict;
use warnings;
use Test::More 1.302195;
use Module::Load::Conditional 0.66 qw/check_install/;

use Excel::ValueReader::XLSX;

(my $tst_dir = $0) =~ s/from_filehandle\.t$//;
$tst_dir       ||= "./";
my $xl_file      = $tst_dir . "valuereader.xlsx";


my @backends = ('Regex');
push @backends, 'LibXML' if check_install(module => 'XML::LibXML::Reader');

foreach my $backend (@backends) { 
  open my $fh, "<", $xl_file or die "open $xl_file : $!";

  my $reader = Excel::ValueReader::XLSX->new($fh, using => $backend);

  # check sheet names
  my @sheet_names          = $reader->sheet_names;
  my @expected_sheet_names = qw/Test Empty Entities Tab_entities Dates Tables RemoteCells/;
  is_deeply(\@sheet_names, \@expected_sheet_names, "filehandle, sheet names using $backend");
}

done_testing;


