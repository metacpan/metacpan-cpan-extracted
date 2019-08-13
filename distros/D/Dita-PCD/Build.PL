use Module::Build;

my $b = Module::Build->new(
  configure_requires    => {'Module::Build'=>0.4224},
  create_readme         =>  0,
  dist_abstract         => 'Implementation of the Please Change Dita Language',
  license               => 'perl',
  module_name           => 'Dita::PCD',
  perl                  => '5.20',
  requires              => {
     Carp               => 0,
     Cwd                => 0,
    'Data::Dump'        => 0,
    'Data::Table::Text' => 20190811,
    'Data::Edit::Xml'   => 20190810,
    'Exporter'          => 0,
    'Test::More'        => 0,
    'Test2::API'        => 0,
   },
 );

$b->create_build_script();
