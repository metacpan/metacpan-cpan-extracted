use v5.8.0;
use Module::Build;

my $b = Module::Build->new
 (configure_requires => {'Module::Build'=>0.4224},
  create_readme =>  0,
  dist_abstract => 'Generate all the disarrangements of a list.',
  dist_author   => 'philiprbrenan@gmail.com',
  license       => 'perl',
  module_name   => 'Math::Disarrange::List',
  perl          => '5.8.0',
  requires      => {Carp=>0, 'Test::More'=>0, 'Test2::API'=>0},
 );

$b->create_build_script();
