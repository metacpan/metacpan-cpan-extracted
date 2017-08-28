use Module::Build;
use v5.16.0;

my $b = Module::Build->new
 (module_name   => 'Math::Transform::List',
  dist_author   => 'PhilipRBrenan@gmail.com',
  dist_abstract => 'Generate specified transformations of a list.',
  license       => 'perl',
  perl          => '5.16.0',
  requires      => {Carp=>0, 'Test::More'=>0},
  configure_requires => {'Module::Build'=>0.4224},
  create_readme =>  0,
 );

$b->create_build_script();
