use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Permute::Lists',
  dist_author   => 'PhilipRBrenan@appaaps.com',
  dist_abstract => 'Generate all the permutations of zero or more nested lists.',
  license       => 'perl',
  create_readme =>  1,
 );

$b->create_build_script();
