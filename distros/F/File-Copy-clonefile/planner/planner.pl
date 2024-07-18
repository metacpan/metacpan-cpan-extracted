use v5.20;
use warnings;

use Devel::CheckCompiler ();

my $ok = Devel::CheckCompiler::check_compile(<<'EOF', executable => 1);
#include <sys/attr.h>
#include <sys/clonefile.h>
int main() {
  return clonefile("", "", 0);
}
EOF
if (!$ok) {
    die "This module only supports platforms that have clonefile system call, such as macos.\n";
}


load_module('Dist::Build::XS');

add_xs(
    module_name => "File::Copy::clonefile",
    ( -d ".git" ? (extra_compiler_flags => ['-Wall', '-Wextra', '-Werror']) : () ),
);

create_node(
    target => "lib/File/Copy/const-c.inc",
    actions => [function(module => "MyFunc", function => "write_constants")],
);
create_node(
    target => "code",
    dependencies => ["lib/File/Copy/const-c.inc"],
    phony => 1,
);
