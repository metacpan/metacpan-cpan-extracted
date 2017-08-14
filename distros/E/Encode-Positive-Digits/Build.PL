use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Encode::Positive::Digits',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Encode a positive integer using the specified digits and vice-versa',
  perl          => '5.16.0',
  license       => 'perl',
  requires      => {Carp=>0, Math::BigInt=>0, Test::More=>0},
  configure_requires => { 'Module::Build' => 0.42 },
  create_readme =>  0,
  perl          => '5.16.0',
 );

$b->create_build_script();
