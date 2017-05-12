use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Permute::List',
  dist_author   => 'PhilipRBrenan@handybackup.com',
  dist_abstract => 'Generate all the permutations of a list.',
  license       => 'perl',
  create_readme =>  1,
 );

$b->create_build_script();
