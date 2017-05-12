use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license     => 'perl',
  module_name => 'Acme::Colour',
  requires    => {
    'Error' => '0.15',
    'Graphics::ColorNames' => '0',
    'List::Util' => '0',
    'Module::Build' => '0.20',
    'Test::Exception' => '0.15',
    'Test::More' => '0.01',
  },
);
$build->create_build_script;
