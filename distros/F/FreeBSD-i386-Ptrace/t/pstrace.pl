#!/usr/local/bin/perl
use strict;
use warnings;
use FreeBSD::i386::Ptrace;
use FreeBSD::i386::Ptrace::Syscall;

die "$0 prog args ..." unless @ARGV;
my $pid = fork();
die "fork failed:$!" if !defined($pid);
if ( $pid == 0 ) {    # son
    pt_trace_me;
    exec @ARGV;
}
else {                # mom
    wait;             # for exec;
    my $count = 0;
    while ( pt_to_sce($pid) == 0 ) {
        last if wait == -1;
        my $call = pt_getcall($pid);
        pt_to_scx($pid);
        wait;
        my $retval = pt_getcall($pid);
        my $name = $SYS{$call} || 'unknown';
        print "$name() = $retval\n";
        $count++;
    }
    warn "$count system calls issued\n";
}
