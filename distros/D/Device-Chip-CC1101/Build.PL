use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::CC1101',
   requires => {
      'Data::Bitfield' => '0.04',
      'Device::Chip' => 0,
      'Future::AsyncAwait' => 0,
      'Future::IO' => 0,

      'perl' => '5.024', # postfix-deref
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
