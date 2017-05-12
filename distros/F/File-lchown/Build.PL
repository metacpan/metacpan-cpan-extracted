use strict;
use warnings;

use Module::Build;
use ExtUtils::CChecker 0.03;

my $cc = ExtUtils::CChecker->new;

$cc->assert_compile_run( 
   diag => "no lchown()",
   source => <<'EOF' );
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char *argv[]) {
  if(lchown(".", -1, -1) != 0)
    exit(1);
  exit(0);
}
EOF

$cc->try_compile_run(
   define => "HAVE_LUTIMES",
   source => <<'EOF' );
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char *argv[]) {
  if(lutimes(".", NULL) != 0)
    exit(1);
  exit(0);
}
EOF

my $build = $cc->new_module_build(
   module_name => 'File::lchown',
   configure_requires => {
      'ExtUtils::CChecker' => 0.03,
   },
   requires => {
   },
   build_requires => {
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
      'Test::More' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);
  
$build->create_build_script;
