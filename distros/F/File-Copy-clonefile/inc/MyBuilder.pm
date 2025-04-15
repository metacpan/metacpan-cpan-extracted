package MyBuilder;
use v5.20;
use warnings;
use experimental 'signatures';

package MyCBuilder {
    use parent 'ExtUtils::CBuilder';
    use IPC::Run3 ();

    sub do_system ($self, @cmd) {
        if (!$self->{quiet}) {
            my $full = join ' ', map $self->quote_literal($_), @cmd;
            print $full . "\n";
        }
        IPC::Run3::run3( \@cmd, undef, \my $out, \my $err, { return_if_system_error => 1 } );
        my $exit = $?;
        if (!$self->{quiet}) {
            print {\*STDOUT} $out if $out;
            print {\*STDERR} $err if $err;
        }
        return $exit == 0;
    }
}

use parent 'Module::Build';
use ExtUtils::Constant ();
use File::Spec;
use File::Temp ();

my $_clonefile = <<'EOF';
#include <sys/attr.h>
#include <sys/clonefile.h>
int main() {
  (void)clonefile("", "", 0);
  return 0;
}
EOF

sub new ($class, %argv) {
    my $self = $class->SUPER::new(
        %argv,
        needs_compiler => 1,
        -d ".git" ? ( extra_compiler_flags => ['-Wall', '-Wextra', '-Werror'] ) : (),
    );
    $self->_try_compile_run($_clonefile)
        or die "This module only supports platforms that have clonefile system call, such as macos.\n";
    $self->_write_constants;
    $self;
}

sub _try_compile_run ($self, $source) {
    my $cbuilder = MyCBuilder->new(config => $self->config, quiet => !$self->verbose);
    my $tempdir = File::Temp->newdir;

    my $c_file = File::Spec->catfile($tempdir, "try_compile_run.c");
    { open my $fh, ">", $c_file or die; print {$fh} $source; }
    my $obj_file = eval { $cbuilder->compile(source => $c_file) };
    if ($@) {
        $self->log_verbose($@);
        return;
    }
    my $exe_file = eval { $cbuilder->link_executable(objects => [$obj_file]) };
    if ($@) {
        $self->log_verbose($@);
        return;
    }
    return $cbuilder->do_system($exe_file);
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
