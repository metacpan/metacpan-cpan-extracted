#!/usr/local/bin/perl
# eg)
# perl -Mblib t/peekpoke.pl perl -E 'open $fh,"<","/etc/passwd"; print<$fh>'
use v5.18;
use strict;
use warnings;
use FreeBSD::i386::Ptrace;
use FreeBSD::i386::Ptrace::Syscall;

sub getsyscallname {
    my $pid = shift;
    my $cid = pt_getcall($pid);
    my $name = $SYS{$cid};
    #$name = $SYS{ pt_getregs($pid)->rdi } while $name =~ /syscall/;
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
        if ($name eq 'open') {
            my $r = pt_getregs($pid);
            my $st1 = pt_read($pid, $r->esp + 4);
            my $str = pt_peekstr($pid, $st1);
            # warn $str;
            if ($str eq '/etc/passwd'){
                pt_pokestr($pid, $st1, '/etc/motd');
            }
        }
    }
}
