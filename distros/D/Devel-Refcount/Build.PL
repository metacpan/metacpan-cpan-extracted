use strict;
use warnings;

use Module::Build;
use ExtUtils::CBuilder;

my $build_xs = 1;

if( $build_xs and not ExtUtils::CBuilder->new->have_compiler ) {
   print "No C compiler is available so cannot build XS implementation\n";
   $build_xs = 0;
}

my $build = Module::Build->new(
   module_name => 'Devel::Refcount',
   requires => {
      'Exporter' => '5.57',
      'XSLoader' => 0,
   },
   configure_requires => {
      'Module::Build' => 0,
   },
   build_requires => {
      'Module::Build' => 0,
      'Test::Fatal' => 0,
      'Test::More' => 0,
   },
   ( $build_xs ? () : ( xs_files => {} ) ),
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
