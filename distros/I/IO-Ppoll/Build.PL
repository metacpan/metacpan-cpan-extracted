use v5;
use strict;
use warnings;

use Module::Build;
use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new;

# ppoll needs _GNU_SOURCE
$cc->define( "_GNU_SOURCE" );

$cc->assert_compile_run(
   diag => "no ppoll()",
   source => <<'EOF' );
#include <poll.h>
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char *argv[]) {
  struct timespec timeout = { 0, 0 };
  if(ppoll(NULL, 0, &timeout, NULL) != 0)
    exit(1);
  exit(0);
}
EOF

my $build = Module::Build->new(
   module_name => 'IO::Ppoll',
   configure_requires => {
      'ExtUtils::CChecker' => 0,
      'Module::Build' => 0,
   },
   requires => {
      'perl' => '5.014',
      'Exporter' => '5.57',
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$cc->extend_module_build( $build );

$build->create_build_script;
