use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::BusPirate::Chip::AVR_HVSP',
   requires => {
      'Device::BusPirate::Chip' => 0,
      'Struct::Dumb' => 0,
   },
   build_requires => {
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
