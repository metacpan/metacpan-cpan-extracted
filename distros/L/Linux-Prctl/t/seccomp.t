use strict;
no strict 'subs';
use warnings;

use Test::More tests => 3;
use Linux::Prctl qw(:constants :functions);
use POSIX qw(WIFSIGNALED WTERMSIG SIGKILL);

SKIP: {
    skip "set_seccomp not available", 3 unless Linux::Prctl->can('set_seccomp');
    skip "get_seccomp failed, did you configure your kernel with CONFIG_SECCOMP=y?", 3 if get_seccomp() == -1;
    is(get_seccomp, 0, "Checking default seccomp value (0)");
    my $pid = fork;
    unless($pid) {
        set_seccomp(1);
        get_seccomp(); # This will result in a SIGKILL
        exit; # So this should never happen
    }
    waitpid $pid, 0;
    my $status = $?;
    is(WIFSIGNALED($status), 1, "Child received signal");
    is(WTERMSIG($status), SIGKILL, "Child received correct signal");
}
