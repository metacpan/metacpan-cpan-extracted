use strict;
use warnings;
use Module::Build;
use 5.005;

use lib 'inc';

use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'Geo::Gpx',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/Geo/Gpx.pm',
  requires          => {
    'DateTime'                  => 0,
    'DateTime::Format::ISO8601' => 0,
    'HTML::Entities'            => 0,
    'Scalar::Util'              => 0,
    'Test::More'                => 0,
    'Time::Local'               => 0,
    'XML::Descent'              => '1.01',
    'version'                   => 0,
  },
  add_to_cleanup => ['Geo-Gpx-*'],
);

$builder->create_build_script();
