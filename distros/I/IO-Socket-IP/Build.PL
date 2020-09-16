use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Socket::IP',
   requires => {
      'IO::Socket' => 0,
      'Socket' => '1.97',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
