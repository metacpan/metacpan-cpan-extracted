use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Keyword::Builder;

my $build = Module::Build->new(
   module_name => "List::Keywords",
   test_requires => {
      'Test2::V0' => '0.000148',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Keyword::Builder' => '0.35',
   },
   requires => {
      'perl' => '5.014',
      'XS::Parse::Keyword' => '0.05',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },

   extra_compiler_flags => [qw( -Ihax )],
);

XS::Parse::Keyword::Builder->extend_module_build( $build );

$build->create_build_script;
