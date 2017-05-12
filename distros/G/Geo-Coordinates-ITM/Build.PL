use strict;
use warnings;
use Module::Build;

use lib 'inc';

use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'Geo::Coordinates::ITM',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/Geo/Coordinates/ITM.pm',
  requires          => {
    'Test::More'          => 0,
    'Test::Number::Delta' => '1.03',
  },
  add_to_cleanup => ['Geo-Coordinates-ITM-*'],
);

$builder->create_build_script();
