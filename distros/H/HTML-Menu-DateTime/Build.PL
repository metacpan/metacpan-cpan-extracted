use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new (
  module_name => 'HTML::Menu::DateTime',
  license     => 'perl',
  requires    => {
    'Test::More' => 0,
  },
  recommends  => {
    'DateTime::Locale'   => '0.20',
    'HTML::Menu::Select' => '1.0',
  },
  create_makefile_pl => 'traditional',
  create_readme      => 1,
);

$build->create_build_script;

