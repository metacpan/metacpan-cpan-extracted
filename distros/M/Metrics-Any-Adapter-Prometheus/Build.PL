use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Metrics::Any::Adapter::Prometheus',
   requires => {
      'perl' => '5.020',
      'Net::Prometheus::Counter' => 0,
      'Net::Prometheus::Gauge' => 0,
      'Net::Prometheus::Histogram' => '0.10',
      'Net::Prometheus::Registry' => 0,
   },
   test_requires => {
      'Metrics::Any' => '0.09',
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
