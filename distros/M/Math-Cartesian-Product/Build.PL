use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Cartesian::Product',
  dist_author   => 'PhilipRBrenan@appaapps.com',
  dist_abstract => 'Generate the cartesian product of zero or more lists.',
  license       => 'perl',
  create_readme =>  1,
 );

$b->create_build_script();
