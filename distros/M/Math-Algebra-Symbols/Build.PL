use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Algebra::Symbols',
  dist_author   => 'PhilipRBrenan@gmail.com',
  dist_abstract => 'Symbolic Algebra in Pure Perl',
  license       => 'perl',
  create_readme =>  1,
  requires      =>
   {'utf8'         => '0',
    'Carp',        => '0',
    'Scalar::Util' => '0',
    'IO::Handle'   => '0',
    'Math::BigInt' => '0',
   },
 );

$b->create_build_script();
