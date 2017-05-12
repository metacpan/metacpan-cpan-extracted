#! /usr/bin/perl -w

# Usage: perl -MEmacs::Forward -e0 INFD OUTFD

# Allow Emacs to read from file descriptor INFD and write to OUTFD
# through a subprocess.  Emacs Lisp can communicate with subprocesses
# only through their STDIN and STDOUT/STDERR.  This program makes any
# file descriptors that Emacs inherited look like a subprocess's STDIN
# and STDOUT.

($infd, $outfd) = @ARGV;

open (IN, "<&=$infd") || die $!;
open (OUT, ">&=$outfd") || die $!;
$rin = '';
vec ($rin, fileno (STDIN), 1) = 1;
vec ($rin, $infd, 1) = 1;

while (1) {
    select ($rout = $rin, undef, undef, undef) || die "select: $!";
    if (vec ($rout, fileno (STDIN), 1)) {
	forward (\*STDIN, \*OUT);
    }
    if (vec ($rout, $infd, 1)) {
	forward (\*IN, \*STDOUT);
    }
}

sub forward {
    my ($from, $to) = @_;
    sysread ($from, $_, 4096) || exit;
    syswrite ($to, $_, length) || die "syswrite: $!";
}
