use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Permute::Partitions',
  dist_author   => 'PhilipRBrenan@appaapps.com',
  dist_abstract => 'Generate all the permutations of a partitioned list.',
  requires => { 'Math::Cartesian::Product' => 0, 'Math::Permute::List' => 0},
  license       => 'perl',
  create_readme =>  1,
 );

$b->create_build_script();
