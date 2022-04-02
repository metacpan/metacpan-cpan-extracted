use v5.14;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Devel::MAT::Tool::Object::Pad',
   requires => {
      'Syntax::Keyword::Match' => 0,
      'Devel::MAT' => '0.47',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing

      'Devel::MAT::Dumper' => '0.45',
      'Object::Pad' => '0.64',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
