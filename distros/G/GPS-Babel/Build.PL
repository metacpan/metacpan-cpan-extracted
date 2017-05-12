use strict;
use warnings;

use Module::Build;

use lib 'inc';

use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'GPS::Babel',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/GPS/Babel.pm',
  requires          => {
    'File::Which' => 0,
    'Geo::Gpx'    => '0.15',
    'Test::More'  => 0,
  },
  PL_files           => {},
  add_to_cleanup     => ['GPS-Babel-*'],
  sign               => 1,
  license            => 'perl',
  create_readme      => 1,
  create_makefile_pl => 'traditional',
);

$builder->create_build_script;

