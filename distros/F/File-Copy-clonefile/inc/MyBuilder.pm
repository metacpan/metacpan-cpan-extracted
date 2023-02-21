package MyBuilder;
use v5.20;
use warnings;
use experimental 'signatures';

use ExtUtils::Constant ();
use Devel::CheckCompiler ();
use parent 'Module::Build';

my $check = <<'EOF';
#include <sys/attr.h>
#include <sys/clonefile.h>
int main() {
  return clonefile("", "", 0);
}
EOF

sub new ($class, %argv) {
    my $ok = Devel::CheckCompiler::check_compile($check, executable => 1);
    if (!$ok) {
        print "This module only supports platforms that have clonefile system call, such as macos.\n";
        exit 0;
    }
    if (-d ".git") {
        %argv = (%argv, extra_compiler_flags => ['-Wall', '-Wextra', '-Werror']);
    }
    my $self = $class->SUPER::new(%argv);
    $self->_write_constants;
    $self;
}

sub _write_constants ($self) {
    ExtUtils::Constant::WriteConstants(
        NAME => $self->module_name,
        NAMES => [qw(CLONE_NOFOLLOW CLONE_NOOWNERCOPY CLONE_ACL)],
        PROXYSUBS => { autoload => 1 },
        C_FILE => 'lib/File/Copy/const-c.inc',
        XS_FILE => 'lib/File/Copy/const-xs.inc',
    );
}

1;
