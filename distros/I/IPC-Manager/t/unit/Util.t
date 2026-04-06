use Test2::V0;

use IPC::Manager::Util qw/USE_INOTIFY USE_IO_SELECT require_mod pid_is_running clone_io/;

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

done_testing;
