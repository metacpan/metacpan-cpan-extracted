use v5;
use strict;
use warnings;

use Module::Build;
use Future::AsyncAwait::ExtensionBuilder;
use XS::Parse::Keyword::Builder;

my $build = Module::Build->new(
   module_name => "Future::AsyncAwait::Hooks",
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'Future::AsyncAwait::ExtensionBuilder' => '0.64',
      'XS::Parse::Keyword::Builder' => '0.13',
   },
   requires => {
      # Needs F-AA which is 5.18+.
      # Additionally, tests appear not to pass before 5.24 but I don't know why
      'perl' => '5.024',
      'Future::AsyncAwait' => '0.64',
   },
   test_requires => {
      'Future' => 0,
      'Future::AsyncAwait' => 0,
      'Test2::V0' => 0,
   },
   extra_compiler_flags => [qw( -I. -Ihax -ggdb )],
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

XS::Parse::Keyword::Builder->extend_module_build( $build );

$build->create_build_script;
