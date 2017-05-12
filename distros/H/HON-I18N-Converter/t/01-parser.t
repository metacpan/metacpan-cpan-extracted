use strict;
use warnings;

use HON::I18N::Converter;

use Test::More tests => 9;

my $converter =
  HON::I18N::Converter->new( excel => 't/resources/1-language/input/file.xls' );

can_ok( $converter, 'p_getLanguage' );
can_ok( $converter, 'p_buildHash' );
can_ok( $converter, 'p_write_JS_i18n' );
can_ok( $converter, 'p_write_INI_i18n' );
can_ok( $converter, 'build_properties_file' );

my $data = [
  {
    'file'     => 't/resources/1-language/input/file.xls',
    'language' => ['en'],
    'labels'   => {
      'en' => {
        'ALL'    => 'All',
        'CANCER' => 'Cancer'
      },
    },
  },
  {
    'file'     => 't/resources/3-language/input/file.xls',
    'language' => [ 'en', 'fr', 'it' ],
    'labels'   => {
      'en' => {
        'ALL'    => 'All',
        'CANCER' => 'Cancer'
      },
      'fr' => {
        'ALL'    => 'Tout',
        'CANCER' => 'Cancer'
      },
      'it' => {
        'ALL'    => 'Tutto',
        'CANCER' => 'Cancro'
      },
    },
  }
];

foreach my $row ( @{$data} ) {

  $converter = HON::I18N::Converter->new( excel => $row->{'file'} );
  my @listLanguage = $converter->p_getLanguage();
  $converter->p_buildHash( \@listLanguage );
  shift @listLanguage;
  my $hash = $converter->labels();
  
  is_deeply( \@listLanguage, $row->{'language'}, 'wrong languages' );
  is_deeply( $hash, $row->{'labels'}, 'wrong labels' );
}