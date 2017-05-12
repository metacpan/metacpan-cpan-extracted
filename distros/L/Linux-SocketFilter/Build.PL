use strict;
use warnings;

use Module::Build;

eval { require ExtUtils::CChecker; 1 } or
   die "OS unsupported - missing ExtUtils::CChecker";

my $cc = ExtUtils::CChecker->new;

$cc->assert_compile_run(
   diag => "no filter.h",
   source => <<'EOF' );
#include <linux/types.h>
#include <linux/filter.h>
int cmd = BPF_LD;
int main(int argc, char *argv[]) {
  return 0;
}
EOF

$cc->assert_compile_run(
   diag => "version mismatch",
   source => <<'EOF' );
#include <linux/types.h>
#include <linux/filter.h>
#include <stdio.h>
int main(int argc, char *argv[]) {
  if(BPF_MAJOR_VERSION != 1) {
    printf("BPF_MAJOR_VERSION mismatch; wanted 1, found %d\n", BPF_MAJOR_VERSION);
    return 1;
  }
  if(BPF_MINOR_VERSION != 1) {
    printf("BPF_MINOR_VERSION mismatch; wanted 1, found %d\n", BPF_MINOR_VERSION);
    return 1;
  }
  return 0;
}
EOF

my $build = $cc->new_module_build(
   module_name => 'Linux::SocketFilter',
   configure_requires => {
      'ExtUtils::CChecker' => '0.02',
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
   },
   build_requires => {
      'ExtUtils::CChecker' => '0.02',
      'ExtUtils::H2PM' => '0.03',
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
