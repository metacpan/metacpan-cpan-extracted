use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Metrics::Any::Adapter::Statsd',
   requires => {
      'IO::Socket::INET' => 0,
   },
   test_requires => {
      'Metrics::Any' => '0.05',
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
