use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Future::AsyncAwait',
   requires => {
      'Future' => 0,
      'perl' => '5.016', # PL_keyword_plugin, pad_new(), CvDYNFILE, many tests fail on 5.14
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
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },

   extra_compiler_flags => [qw( -std=c89 -Ihax )],
);

$build->create_build_script;
