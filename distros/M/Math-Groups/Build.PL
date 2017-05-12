use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Groups',
  dist_author   => 'PhilipRBrenan@gmail.com',
  dist_abstract => 'Mathematical groups',
  license       => 'perl',
  create_readme =>  1,
  requires      => { utf8 => 0,
                     Carp => 0,
                     Math::Cartesian::Product => 0,
                     Math::Permute::List => 0,
                     Data::Dump => 0,
   }
 );

$b->create_build_script();
