use v5.20;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Device::AVR::UPDI',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'perl' => '5.026',
      'Future::AsyncAwait' => 0,
      'Object::Pad' => '0.807',
      'Object::Pad::ClassAttr::Struct' => '0.04',
      'Sublike::Extended' => '0.29',

      'Commandable' => '0.08',
      'Commandable::Finder::SubAttributes' => '0.14',
      'File::ShareDir' => 0,
      'Future::IO' => '0.03',
      'IO::Termios' => 0,
      'YAML' => 0,
   },
   test_requires => {
      'Test::ExpectAndCheck' => '0.04',
      'Test::Future::IO' => '0.04', # ->expect_sys*_anyfh
      'Test2::V0' => 0,
   },
   share_dir => {
      module => { "Device::AVR::UPDI" => "share" },
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
