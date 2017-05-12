use strict;
use warnings;

use Module::Build;
use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new;

# It seems you have to use the <asm/termios.h> versions because those relate
# more to the kernel, whereas the straight <termios.h> lags massively behind
# and doesn't know of termios2

$cc->assert_compile_run(
   diag => "no struct termios2",
   source => <<'EOF' );
#include <asm/termios.h>

int main(int argc, char *argv[]) {
  struct termios2 t;
  return 0;
}
EOF

$cc->assert_compile_run(
   diag => "no TCGETS2",
   source => <<'EOF' );
#include <asm/termios.h>
#include <asm/ioctls.h>

int main(int argc, char *argv[]) {
  int a = TCGETS2;
  return 0;
}
EOF

$cc->new_module_build(
   module_name => 'Linux::Termios2',
   requires => {
   },
   configure_requires => {
      'Module::Build' => 0,
      'ExtUtils::CChecker' => 0,
   },
   build_requires => {
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
)->create_build_script;
