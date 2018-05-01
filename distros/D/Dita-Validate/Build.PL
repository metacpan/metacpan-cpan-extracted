use 5.8.0;
use Module::Build;

my $b = Module::Build->new(
  configure_requires   => {'Module::Build'=>0.4224},
  create_readme        =>  0,
  dist_abstract        => 'In situ validation of XML parse trees representing OASIS DITA documents.',
  dist_author          => 'philiprbrenan@gmail.com',
  license              => 'perl',
  module_name          => 'Dita::Validate',
  perl                 => '5.8.0',
  requires             => {
    'Acme::Tools'      => 0,
     Carp              => 0,
    'Data::DFA'        => '20180429',
    'Data::Dump'       => 0,
    'Data::Edit::Xml'  => '20180428',
    'Data::Table::Text'=> '20180428',
     Storable          => 0,
    'Test::More'       => 0,
    'Test2::API'       => 0,
    'XML::Parser'      => 0,
   },
 );

$b->create_build_script();
