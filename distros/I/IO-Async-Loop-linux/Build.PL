use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'IO::Async::Loop::linux',
   requires => {
                 'IO::Async' => 0,
               },
   recommends => {
                 'IO::Async::Loop::Epoll' => 0,
               },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
  );

$build->create_build_script;
