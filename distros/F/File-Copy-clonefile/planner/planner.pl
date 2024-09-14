use v5.20;
use warnings;

load_module("ExtUtils::Builder::Conf");

my $source = <<'EOF';
#include <sys/attr.h>
#include <sys/clonefile.h>
int main() {
  (void)clonefile("", "", 0);
  return 0;
}
EOF

assert_compile_run(
    source => $source,
    quiet  => 1,
    diag   => 'This module only supports platforms that have clonefile system call, such as macos.',
);

load_module('Dist::Build::XS');
load_module('Dist::Build::XS::WriteConstants');

add_xs(
    write_constants => {
        NAMES => [qw(CLONE_NOFOLLOW CLONE_NOOWNERCOPY CLONE_ACL)],
        PROXYSUBS => { autoload => 1 },
    },
    -d ".git" ? ( extra_compiler_flags => ['-Wall', '-Wextra', '-Werror'] ) : (),
);
