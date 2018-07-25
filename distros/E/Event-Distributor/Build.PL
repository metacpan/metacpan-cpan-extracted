use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Event::Distributor',
   requires => {
      'Future' => '0.15',
      'Syntax::Keyword::Try' => 0,
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
