use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Subsets::List',
  dist_author   => 'PhilipRBrenan@appaapps.com.com',
  dist_abstract => 'Generate all the subsets of a list.',
  license       => 'perl',
  create_readme =>  1,
 );

$b->create_build_script();
