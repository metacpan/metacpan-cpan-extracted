use strict;
use warnings;

use IO::All;
use File::Temp qw/tempfile tempdir/;
use HON::I18N::Converter;

use Test::File;
use Test::More tests => 12;

my $data = [
  {
    'file'     => 't/resources/1-language/input/file.xls',
    'language' => ['en'],
    'output'   => 't/resources/1-language/output'
  },
  {
    'file'     => 't/resources/3-language/input/file.xls',
    'language' => [ 'en', 'fr', 'it' ],
    'output'   => 't/resources/3-language/output'
  }
];

foreach my $row ( @{$data} ) {
  my $dir = File::Temp->newdir();
  my $converter = HON::I18N::Converter->new( excel => $row->{'file'} );
  $converter->build_properties_file('INI', $dir, '');
  
  foreach my $language (@{$row->{language}}){
    file_exists_ok( $dir.'/'.$language.'.ini' );
    file_not_empty_ok( $dir.'/'.$language.'.ini' );
    
    my @generatedLines = io( $dir.'/'.$language.'.ini')->slurp;
    my @expectedLines  = io($row->{'output'}.'/'.$language.'.ini')->slurp;
    
    @generatedLines = sort @generatedLines;
    @expectedLines  = sort @expectedLines;
    
    is_deeply(\@generatedLines, \@expectedLines, 'not same array');
    
  }
}