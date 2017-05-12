use Test;

BEGIN { plan tests => 2 };

use File::Spec::Functions;
my $tmp_dir = File::Spec::Functions::tmpdir;
die "cannot find out a temp dir" if $tmp_dir eq '';

use Debug::DumpCore;
use Debug::FaultAutoBT;
ok 1;

my $core_path_base = catfile $tmp_dir, "core.backtrace.";

# spawn a child process and make it segfault, so we can verify in the
# parent process whether the core backtrace has been created and
# report success/failure
unless (my $pid = fork) { # child
    my $trace = Debug::FaultAutoBT->new(
        dir            => "$tmp_dir",
        verbose        => 1,
        core_path_base => $core_path_base,
        #command_path   => catfile($tmp_dir, "my-gdb-command"),
        #debugger       => "gdb",
       );
    $trace->ready();
    Debug::DumpCore::segv();
    die "the process should have segfaulted before reaching this point";
}
else {
    wait();
    my $core_path = "$core_path_base$pid";
    print "parent\n";
    ok -e $core_path;

    # cleanup
    unlink $core_path;
    unlink catfile $tmp_dir, "gdb-command";
}

