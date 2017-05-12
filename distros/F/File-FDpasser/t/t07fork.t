
$SIG{CHLD} = sub { wait };

BEGIN { $|=1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::FDpasser;
use IO::Handle;

$loaded = 1;

print "ok 1\n";
$|=0;
@fd=spipe();
die "spipe() failed\n" if !defined(@fd);
$,=", ";
print "#fd: @fd\n";

$pid = fork;
if (!defined($pid)) { die "fork failed: $!\n"; }
if ($pid) { # parent
    open(FH,">test.txt") || die "parent - open(): $!\n";
    print FH "testing - hello world, etc..\n\n";
    close(FH); # just a lame flush - 
    open(FH,"test.txt") || die "parent - open(): $!\n";
    $rc=send_file($fd[0],*FH{IO});
    print "#parent: rc=$rc\n";
    print "ok\n";
} else { # child
    $fh=recv_fh($fd[1]) || die "recv_fh: $!\n";
    while(<$fh>) { print '# '; print; }
    print "ok\n";
}

