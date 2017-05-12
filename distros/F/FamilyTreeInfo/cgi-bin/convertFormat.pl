#!/usr/bin/perl -w

use lib ('cgi', 'cgi/lib');
use Ftree::FamilyTreeDataFactory;
use v5.10.1;
no warnings 'experimental::smartmatch';
use utf8;

my $input_file_name = $ARGV[0];
my $output_file_name = $ARGV[1];

if(!defined $input_file_name || !defined $output_file_name) {
  print "usage: $0 input_file_name output_file_name\n",
    "some examples:\n",
    "  $0 tree.txt tree.xls\n",
    "  $0 tree.xls tree.ser\n",
    "  $0 tree.xlsx tree.ser\n",
}
else {
  my %type_hash = (
    csv => "csv",
    txt => "csv",
    xls => "excel",
    xlsx => "excelx",
    ged => "gedcom",
    ser => "ser",
  );
  my $input_extension = (split(/\./, $input_file_name))[-1];
  my %config = (
    type => $type_hash{$input_extension},
    config => {
      file_name => $input_file_name,
    }
  );


  my $family_tree = Ftree::FamilyTreeDataFactory::getFamilyTree( \%config );
  my $extension = (split(/\./, $output_file_name))[-1];
  for ($extension) {
    when (/\bxls\b/) {
      require Ftree::Exporters::ExcelExporter;
      Ftree::Exporters::ExcelExporter::export($output_file_name, $family_tree);
      }
    when (/\bxlsx\b/){
      require Ftree::Exporters::ExcelxExporter;
      Ftree::Exporters::ExcelxExporter::export($output_file_name, $family_tree);
      }
    when (/\bser\b/) {
      require Ftree::Exporters::Serializer;
      Ftree::Exporters::Serializer::export($output_file_name, $family_tree);
      }
}

}

