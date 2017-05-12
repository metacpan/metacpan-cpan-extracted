#!/usr/local/bin/perl
use strict;
use warnings;
use FreeBSD::amd64::Ptrace;
use FreeBSD::amd64::Ptrace::Syscall;

sub getsyscallname {
    my $pid = shift;
    my $cid = pt_getcall($pid);
    my $name = $SYS{$cid};
    $name = $SYS{ pt_getregs($pid)->rdi } while $name =~ /syscall/;
    return $name;
}

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
    while ( pt_syscall($pid) == 0 ) {
        last if wait == -1;
        my $name = getsyscallname($pid) || 'unknown';
        pt_to_scx($pid);
        wait;
        my $retval = pt_getcall($pid);
        print "$name() = $retval\n";
        $count++;
    }
    warn "$count system calls issued\n";
}
