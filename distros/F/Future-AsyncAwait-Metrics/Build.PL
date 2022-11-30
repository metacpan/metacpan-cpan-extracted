use v5;
use strict;
use warnings;

use Module::Build;
use Future::AsyncAwait::ExtensionBuilder;

my $build = Module::Build->new(
   module_name => "Future::AsyncAwait::Metrics",
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Metrics::Any' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'Future::AsyncAwait::ExtensionBuilder' => '0.60',
   },
   requires => {
      'perl' => '5.014',
      'Future::AsyncAwait' => '0.60',
      'Metrics::Any' => '0.09',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },
);

Future::AsyncAwait::ExtensionBuilder->extend_module_build( $build );

$build->create_build_script;
