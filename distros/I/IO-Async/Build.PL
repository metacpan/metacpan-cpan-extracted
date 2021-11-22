use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'IO::Async',
   requires => {
      'Future' => '0.33', # ->catch
      'Future::Utils' => '0.18', # try_repeat
      'Exporter' => '5.57',
      'File::stat' => 0,
      'IO::Poll' => 0,
      'List::Util' => 0,
      # Require Socket 2.029 on MSWin32 because of AF_UNIX (RT133018)
      ( 'Socket' => ( $^O eq "MSWin32" ? '2.029' : '2.007' ) ),
      'Storable' => 0,
      'Struct::Dumb' => 0,
      'Time::HiRes' => 0,

      # Fails on perl 5.8.3 for unknown reasons
      'perl' => '5.008004',
   },
   recommends => {
      'IO::Socket::IP' => 0,
   },
   test_requires => {
      'File::Temp' => 0,
      'Test::Fatal' => 0,
      'Test::Future::IO::Impl' => 0,
      'Test::Identity' => 0,
      'Test::Metrics::Any' => 0,
      'Test::More' => '0.88',
      'Test::Refcount' => 0,
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
