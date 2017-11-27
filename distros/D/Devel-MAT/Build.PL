use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Devel::MAT',
   requires => {
      'File::ShareDir' => 0,
      'File::Spec' => 0,
      'List::Util' => '1.44', # uniq
      'List::UtilsBy' => 0,   # sort_by
      'Module::Pluggable' => 0,
      'perl' => '5.010',      # various XS failures on 5.8
      'String::Tagged' => '0.15', # sprintf
      'String::Tagged::Terminal' => 0,
      'Struct::Dumb' => '0.07',
   },
   test_requires => {
      'Test::Identity' => 0,
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   share_dir => {
      module => { "Devel::MAT::UI" => "share" },
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

if( $build->args( "DEBUG" ) ) {
   $build->extra_compiler_flags( @{ $build->extra_compiler_flags }, "-ggdb" );
}

$build->create_build_script;
