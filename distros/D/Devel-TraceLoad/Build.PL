require 5.008;

use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'Devel::TraceLoad',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/Devel/TraceLoad.pm',
  requires          => {
    'Data::Dumper' => 0,
    'File::Path'   => 0,
    'File::Spec'   => 0,
    'File::Temp'   => 0,
    'Scalar::Util' => 0,
    'Test::Deep'   => '0.096',
    'Test::More'   => 0,
    'YAML'         => 0,
  },
  add_to_cleanup => ['Devel-TraceLoad-*'],
);

$builder->create_build_script();
