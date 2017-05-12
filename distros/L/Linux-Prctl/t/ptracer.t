use strict;
use warnings;

use Test::More tests => 2;
use Linux::Prctl qw(:constants :functions);

SKIP: {
    skip "set_ptracer not available", 2 unless Linux::Prctl->can('set_ptracer');
    skip "yama not available", 2 unless -e "/proc/sys/kernel/yama";
    is(set_ptracer(1), 0, "Setting ptracer to 1 (init)");
    my $pid = fork or exit;
    waitpid $pid, 0;
    is(set_ptracer($pid), -1, "Setting ptracer to an invalid pid");
}
