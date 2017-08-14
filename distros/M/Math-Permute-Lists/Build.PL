use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Permute::Lists',
  dist_author   => 'PhilipRBrenan@appaaps.com',
  dist_abstract => 'Generate all the permutations of zero or more nested lists.',
  license       => 'perl',
  create_readme =>  0,
  perl          => '5.16.0',
  requires      => {Carp=>0, Test::More=>0},
  configure_requires => {'Module::Build'=>0.42},

 );

$b->create_build_script();
