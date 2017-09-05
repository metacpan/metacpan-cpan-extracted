use v5.16.0;
use Module::Build;

my $b = Module::Build->new
 (configure_requires => {'Module::Build'=>0.4224},
  create_readme =>  0,
  dist_abstract => 'Generate all the permutations of zero or more nested lists.',
  dist_author   => 'philiprbrenan@gmail.com',
  license       => 'perl',
  module_name   => 'Math::Permute::Lists',
  perl          => '5.16.0',
  requires      => {Carp=>0, 'Test::More'=>0},
 );

$b->create_build_script();
