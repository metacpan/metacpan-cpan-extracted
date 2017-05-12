use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Disarrange::List',
  dist_author   => 'PhilipRBrenan@appaapps.com',
  dist_abstract => 'Generate all the disarrangements of a list.',
  license       => 'perl',
  create_readme =>  1,
 );

$b->create_build_script();
