use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new(
   module_name => 'Games::SGF',
   license  => 'perl',
   create_makefile_pl => 'traditional',
   requires => {
      'enum'         => '1.016',
#      'Clone::PP'    => '1.02'
   },
   build_requires => {
      'Test::More'   => 0.70,
      'Data::Dumper' => 2.121,
      'Scalar::Util' => 1.14,
      'Pod::Coverage' => 0.19,
      'Test::Pod' => 1.26,
      'Test::Pod::Coverage' => 1.08,

   },
);
$build->create_build_script;
