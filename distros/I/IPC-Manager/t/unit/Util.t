use Test2::V0;
use Time::HiRes qw/time/;

use IPC::Manager::Util qw/USE_INOTIFY USE_IO_SELECT require_mod pid_is_running clone_io tinysleep/;

subtest 'USE_IO_SELECT is constant' => sub {
    my $val = USE_IO_SELECT();
    ok(defined $val, "USE_IO_SELECT returns a value");
    like($val, qr/^[01]$/, "value is 0 or 1");
};

subtest 'USE_INOTIFY is constant' => sub {
    my $val = USE_INOTIFY();
    ok(defined $val, "USE_INOTIFY returns a value");
    like($val, qr/^[01]$/, "value is 0 or 1");
};

subtest 'require_mod loads a module' => sub {
    my $mod = require_mod('File::Spec');
    is($mod, 'File::Spec', "returns the module name");
    ok(File::Spec->can('catfile'), "module is loaded");
};

subtest 'require_mod dies on bad module' => sub {
    ok(dies { require_mod('This::Module::Does::Not::Exist::ZZZZZ') }, "dies on nonexistent module");
};

subtest 'pid_is_running - current process' => sub {
    is(pid_is_running($$), 1, "current process is running");
};

subtest 'pid_is_running - dead process' => sub {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) { exit 0 }
    waitpid($pid, 0);
    is(pid_is_running($pid), 0, "exited process is not running");
};

subtest 'pid_is_running - requires pid' => sub {
    like(dies { pid_is_running(undef) }, qr/pid is required/i, "dies without pid");
};

subtest 'clone_io' => sub {
    open(my $orig, '<', '/dev/null') or die "open: $!";
    my $clone = clone_io('<&', $orig);
    ok($clone, "got a cloned handle");
    close($clone);
    close($orig);
};

subtest 'clone_io - no mode' => sub {
    like(dies { clone_io(undef, \*STDIN) }, qr/No mode/, "dies without mode");
};

subtest 'clone_io - no handle' => sub {
    like(dies { clone_io('<', undef) }, qr/No handle/, "dies without handle");
};

subtest 'tinysleep sleeps for the requested duration' => sub {
    my $start = time;
    tinysleep(0.1);
    my $elapsed = time - $start;
    cmp_ok($elapsed, '>=', 0.05, "slept at least a reasonable amount");
    cmp_ok($elapsed, '<',  1.0,  "did not sleep much longer than requested");
};

subtest 'tinysleep is interrupted by a signal' => sub {
    my $fired = 0;
    local $SIG{USR1} = sub { $fired++ };

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        # Give the parent a moment to enter tinysleep().
        select(undef, undef, undef, 0.1);
        kill 'USR1', getppid();
        exit 0;
    }

    my $start   = time;
    tinysleep(10);
    my $elapsed = time - $start;
    waitpid($pid, 0);

    is($fired, 1, "signal handler fired");
    cmp_ok($elapsed, '<', 5, "tinysleep returned early on signal");
};

subtest 'tinysleep is a no-op for undef / non-positive values' => sub {
    my $start = time;
    tinysleep(undef);
    tinysleep(0);
    tinysleep(-1);
    my $elapsed = time - $start;
    cmp_ok($elapsed, '<', 0.1, "returned immediately");
};

done_testing;
