use strict;
use warnings;

use Module::Build;
use ExtUtils::CChecker;

ExtUtils::CChecker->new->assert_compile_run( 
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
   dist_version_from => 'lib/IO/Ppoll.pm',
   configure_requires => {
      'ExtUtils::CChecker' => 0,
      'Module::Build' => 0,
   },
   requires => {
      'Exporter' => '5.57',
   },
   test_requires => {
      'Test::More' => "0.88", # done_testing
   },
   auto_configure_requires => 1,
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
