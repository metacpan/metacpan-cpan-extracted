use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::Chip::CC1101',
   requires => {
      'Data::Bitfield' => '0.04',
      'Device::Chip' => 0,
      'Future::AsyncAwait' => '0.47', # toplevel await
      'Future::IO' => 0,
      'Object::Pad' => '0.27',
      'XS::Parse::Sublike' => '0.05', # parse_subsignature whitespace bugfix

      'perl' => '5.026', # postfix-deref, signatures
   },
   test_requires => {
      'Test::Device::Chip::Adapter' => 0,
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
