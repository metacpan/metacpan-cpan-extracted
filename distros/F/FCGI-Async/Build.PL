use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'FCGI::Async',
   requires => {
      'Net::Async::FastCGI' => 0,
   },
   build_requires => {
      'Test::HexString' => 0,
      'Test::More' => 0,
      'Test::Refcount' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);
  
$build->create_build_script;
