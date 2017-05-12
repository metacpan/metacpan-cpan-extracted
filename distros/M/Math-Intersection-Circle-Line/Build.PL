use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Intersection::Circle::Line',
  dist_author   => 'PhilipRBrenan@gmail.com',
  dist_abstract => 'Find the points at which a given circle and a line intersect.',
  license       => 'perl',
  create_readme =>  1,
  requires      => { utf8 => 0 }
 );

$b->create_build_script();
