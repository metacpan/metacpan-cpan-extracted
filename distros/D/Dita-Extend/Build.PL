use Module::Build;

my $b = Module::Build->new(
  configure_requires   => {'Module::Build'=>0.4224},
  create_readme        =>  0,
  dist_abstract        => 'Validate XML documents written as extensions of OASIS DITA.',
  dist_author          => 'philiprbrenan@gmail.com',
  license              => 'perl',
  module_name          => 'Dita::Extend',
  perl                 => '5.20',
  requires             => {
    'Acme::Tools'      => 0,
     Carp              => 0,
    'Data::DFA'        => '20181027',
    'Data::NFA'        => '20181027',
    'Data::Dump'       => 0,
    'Data::Table::Text'=> '20190121',
    'Data::Edit::Xml'  => '20190124',
     Storable          => 0,
    'Test::More'       => 0,
    'Test2::API'       => 0,
    'XML::Parser'      => 0,
   },
 );

$b->create_build_script();
