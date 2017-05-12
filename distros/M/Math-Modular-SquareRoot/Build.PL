use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Modular::SquareRoot',
  dist_author   => 'PhilipRBrenan@handybackup.com',
  dist_abstract => 'Modular square roots',
  license       => 'perl',
  create_readme =>  1,
 );

$b->create_build_script();
