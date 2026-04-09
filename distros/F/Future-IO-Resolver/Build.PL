use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Future::IO::Resolver',
   requires => {
      'perl' => '5.020',
      'meta' => '0.008',

      'Future::IO' => '0.19',
      'Future::Utils' => 0,
      'Net::LibAsyncNS' => 0,
   },
   test_requires => {
      # Not mentioned in any of the test scripts, but we need /a/ working
      # Future::IO::Impl to test with; this one seems most easy to obtain
      'Future::IO::Impl::Ppoll' => 0,

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
