use Test;

BEGIN { plan tests => 2 };

use POSIX ();

use File::Spec::Functions;
my $tmp_dir = File::Spec::Functions::tmpdir;
die "cannot find out a temp dir" if $tmp_dir eq '';

use Debug::FaultAutoBT;
ok 1;

my $core_path_base = catfile $tmp_dir, "core.backtrace.";

# spawn a child process and kill it with SIGABRT, so we can verify in
# the parent process whether the core backtrace has been created and
# report success/failure
    my $trace = Debug::FaultAutoBT->new(
        dir            => "$tmp_dir",
        verbose        => 1,
        core_path_base => $core_path_base,
        #command_path   => catfile($tmp_dir, "my-gdb-command"),
        #debugger       => "gdb",
       );
    $trace->ready();
unless (my $pid = fork) { # child
    # commit suicide
    #die "the process should have core-dumped before reaching this point";
    sleep 10;
}
else {
    sleep 1;
    kill POSIX::SIGABRT(), $pid;
    wait();
    my $core_path = "$core_path_base$pid";
    print "parent\n";
    ok -e $core_path;

    # cleanup
    unlink $core_path;
    unlink catfile $tmp_dir, "gdb-command";
}

