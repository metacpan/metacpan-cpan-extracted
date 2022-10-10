use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Devel::MAT::Tool::Future',
   requires => {
      'perl' => '5.014',
      'Syntax::Keyword::Match' => 0,

      'Devel::MAT::Tool' => '0.49',
   },
   test_requires => {
      'Future' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004',
   },
   share_dir => {
      module => { "Devel::MAT::Tool::Future" => "share" },
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
