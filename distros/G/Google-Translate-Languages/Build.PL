use 5.8.0;
use Module::Build;

my $b = Module::Build->new(
  configure_requires   => {'Module::Build'=>0.4224},
  create_readme        =>  0,
  dist_abstract        => 'List of languages and ISO 639 language codes supported by Google Translate',
  dist_author          => 'philiprbrenan@gmail.com',
  license              => 'perl',
  module_name          => 'Google::Translate::Languages',
  perl                 => '5.8.0',
  requires             => {
     Carp              => 0,
     Data::Dump        => 0,
     Data::Table::Text => '20171117',
     ISO::639          => '20171206',
    'Test::More'       => 0,
    'Test2::API'       => 0,
    'utf8'             => 0,
   },
 );

$b->create_build_script();
