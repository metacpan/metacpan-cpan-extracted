use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::BusPirate',
   requires => {
      'Device::Chip::Adapter' => '0.02',
      'Device::Chip::ProtocolBase::SPI' => 0,
      'Future' => 0,
      'Future::Mutex' => 0,
      'Future::IO' => '0.04',
      'Future::AsyncAwait' => '0.25', # RT129303
      'IO::Termios' => '0.07',
      'List::Util' => '1.33',
      'Module::Pluggable' => 0,
      'Time::HiRes' => 0,
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Future::Deferred' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
