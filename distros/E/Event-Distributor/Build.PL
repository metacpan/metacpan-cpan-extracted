use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Event::Distributor',
   requires => {
      'perl' => '5.014',

      'Feature::Compat::Try' => 0,
      'Future' => '0.15',
   },
   test_requires => {
      'Test::Fatal' => 0,
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
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

$build->create_build_script;
