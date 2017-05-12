#!/usr/local/bin/perl
use strict;
use warnings;
use FreeBSD::i386::Ptrace;
use FreeBSD::i386::Ptrace::Syscall;

die "$0 prog args ..." unless @ARGV;
defined( my $pid = fork() ) or die "fork failed:$!";
if ( $pid == 0 ) {
    pt_trace_me;
    exec @ARGV;
}
else {
    wait;    # for exec;
    my $count = 0;    # odd on enter, even on leave
    while ( pt_to_sce($pid) == 0 ) {
        last if wait == -1;
        my $call = pt_getcall($pid);
        my $name = $SYS{$call} || 'unknown';
        last if $name eq 'exit';
        # warn "$name";
        if ( $name =~ /fork/ ) {
            #pt_kill($pid);
            ptrace( PT_CONTINUE, $pid, 0, 9 );
            die "killed $pid; SYS_$name forbidden.\n";
        }
    }
}
