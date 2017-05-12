#!/usr/local/bin/perl
use v5.18;
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
defined( my $pid = fork() ) or die "fork failed:$!";
if ( $pid == 0 ) {
    pt_trace_me;
    exec @ARGV;
}
else {
    wait;    # for exec;
    while ( pt_to_sce($pid) == 0 ) {
        last if wait == -1;
        my $name = getsyscallname($pid);
        last if $name eq 'exit';
        if ($name =~ /fork/) {
            #pt_kill($pid);
            ptrace( PT_CONTINUE, $pid, 0, 9 );
            die "killed $pid; SYS_$name forbidden.\n";
        }
    }
}
