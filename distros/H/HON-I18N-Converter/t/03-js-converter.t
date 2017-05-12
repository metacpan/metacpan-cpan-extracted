use strict;
use warnings;

use IO::All;
use File::Temp qw/tempfile tempdir/;
use HON::I18N::Converter;

use Test::File;
use Test::More tests => 6;

my $data = [
  {
    'file'     => 't/resources/1-language/input/file.xls',
    'language' => ['en'],
    'output'   => 't/resources/1-language/output/'
  },
  {
    'file'     => 't/resources/3-language/input/file.xls',
    'language' => [ 'en', 'fr', 'it' ],
    'output'   => 't/resources/3-language/output/'
  }
];

foreach my $row ( @{$data} ) {
  my $dir = File::Temp->newdir();
  my $converter = HON::I18N::Converter->new( excel => $row->{'file'} );
  $converter->build_properties_file('JS', $dir, '');
  
  file_exists_ok( $dir.'/jQuery-i18n.js' );
  file_not_empty_ok( $dir.'/jQuery-i18n.js'  );
  
  my @generatedLines = io($dir.'/jQuery-i18n.js')->slurp;
  my @expectedLines  = io($row->{'output'}.'/i18n.js')->slurp;
  
  my @genLines = map {
  	my $s = $_;
  	$s =~ s/,$// if $s =~ m/,$/;
  	$s;
  } @generatedLines;
  my @expLines = map {
  	my $s = $_;
  	$s =~ s/,$// if $s =~ m/,$/;
  	$s;
  } @expectedLines;
  
  @generatedLines = sort @genLines;
  @expectedLines  = sort @expLines;
  
  is_deeply(\@generatedLines, \@expectedLines, 'not same array');
}