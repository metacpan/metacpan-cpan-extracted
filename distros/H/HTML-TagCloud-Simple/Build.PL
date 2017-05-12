use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license            => 'perl',
  module_name        => 'HTML::TagCloud::Simple',
    requires           => {
    'Test::More' => '0',
    },
);
$build->create_build_script;
