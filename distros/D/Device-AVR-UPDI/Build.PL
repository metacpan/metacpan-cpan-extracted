use v5.20;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::AVR::UPDI',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'File::ShareDir' => 0,
      'Future::AsyncAwait' => 0,
      'Future::IO' => '0.03',
      'IO::Termios' => 0,
      'Struct::Dumb' => 0,
      'YAML' => 0,

      'perl' => '5.020',
   },
   test_requires => {
      'Test::ExpectAndCheck' => 0,
      'Test::Future::IO' => '0.02', # ->expect_sys*_anyfh
      'Test::More' => '0.88', # done_testing
   },
   share_dir => {
      module => { "Device::AVR::UPDI" => "share" },
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
