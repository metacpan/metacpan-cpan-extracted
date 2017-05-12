use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license            => 'perl',
  module_name        => 'MealMaster',
  requires           => {
    'Class::Accessor::Chained::Fast' => '0',
    'Test::Exception'                => '0',
    'Test::More'                     => '0',
  },
);
$build->create_build_script;
