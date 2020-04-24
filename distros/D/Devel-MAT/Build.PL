use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Devel::MAT',
   requires => {
      'Commandable::Invocation' => '0.04', # ->peek_remaining
      'Devel::MAT::Dumper' => '0.35',
      'File::ShareDir' => 0,
      'File::Spec' => 0,
      'Heap' => 0,
      'List::Util' => '1.44', # uniq
      'List::UtilsBy' => 0,   # sort_by
      'Module::Pluggable' => 0,
      'perl' => '5.014',      # s///r
      'String::Tagged' => '0.15', # sprintf
      'String::Tagged::Terminal' => '0.03',
      'Struct::Dumb' => '0.07',
      'Syntax::Keyword::Try' => 0,
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
