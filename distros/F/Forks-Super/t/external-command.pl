#! perl
# $^X external-command.pl [options]
#
# We don't know what OS and environment we are testing on.
# But we can be confident that the system will have perl,
# so when we need to test something about external programs,
# we'll use a perl script.
#
# Depending on the command line arguments provided, this script
# is capable of mocking an external command by running for a certain
# amount of time, producing simple output to a file, determining
# environment like the PPID, and exiting with an arbitrary exit code.
#
#   -e=msg        writes the msg to standard output or output
#   -F            output program status when the program exits
#   -n            writes a newline to standard output or output
#   -o=file       redirect standard output to file
#   -p            outputs the parent PID
#   -P,-W         outputs process id
#   -s=n          go to sleep for <n> seconds
#   -w=msg        writes the msg to standard error
#   -x=z          exit with code <z>
#   -y=n          print line from STDIN <n> times to STDOUT, once to STDERR
#
#
# Examples:
#
#   $^X t/external-command.pl -o=t/out/test -e=Hello, -e=Whirled -p -x=0
#
# This script is used in tests:
#      t/11-to-command.t
#      t/13-to-exec.t
#      t/25-open.t
#      t/26-waitpid-MSWin32-pgrp.t
#      t/40h-timeout.t
#      t/42[abcef]-filehandle.t
#      t/43e-sockethandles.t
#      t/46[bd]-userbusy.t
#      t/49*.tt
#      t/56a-dir.t
#      t/60-os.t
#      t/63a-bg_qx.t
#      t/63b-bg_qx_tie.t
#      t/63c-bg_qx_list.t
#      t/67[ab]-emulate.t
#

use strict;
use warnings;
no warnings;

my $flag_on_error = 0;
my $STATUS=0;
#$SIG{'INT'} = sub { $STATUS=2; die $^O eq 'MSWin32' ? "die INT\n" : "\n";};
$SIG{'HUP'} = sub { $STATUS=1; die $^O eq 'MSWin32' ? "die HUP\n" : "\n";};

END {
    $?=$STATUS if $STATUS;
    if ($flag_on_error) {
	print STDERR "FLAG $?\n";
    }
    print OUT "\n";
    print STDOUT "\n";
    close OUT;
    close STDOUT;
    close STDERR;
    1;
}

select STDOUT; $| = 1;
select STDERR; $| = 1;
select STDOUT;
foreach my $arg (@ARGV) {
    my ($key,$val) = split /=/, $arg;
    if ($key eq '--output' or $key eq '-o') {
	open(OUT, '>', $val);
	select OUT;
        $| = 1;
    } elsif ($key eq '--echo' or $key eq '-e') {
	print $val, ' ';
    } elsif ($key eq '--warn' or $key eq '-w') {
	print STDERR $val, ' ';
    } elsif ($key eq '--ppid' or $key eq '-p') {
	# On MSWin32, getppid() is broken. 
	my $ppid = $^O eq 'MSWin32' ? $ENV{_FORK_PPID} : getppid();
	print $ppid, ' ';
    } elsif ($key eq '--pid' or $key eq '-P') {
	my $pid = $^O eq 'MSWin32' ? $ENV{_FORK_PID} : $$;
	print $pid, ' ';
    } elsif ($key eq '--winpid' or $key eq '-W') {
	print $$, ' ';
    } elsif ($key eq '--sleep' or $key eq '-s') {
	sleep $val || 1;
    } elsif ($key eq '--exit' or $key eq '-x') {
	$flag_on_error = 0;
	exit $val || 0;
    } elsif ($key eq '--input' or $key eq '-y') {
	my $y = <STDIN>;
	while ($val-- > 0) {
	    print $y;
	}
	print STDERR "received message $y";
    } elsif ($key eq '--newline' or $key eq '-n') {
	print "\n";
    } elsif ($key eq '--flag' or $key eq '-F') {
	$flag_on_error = 1;
    }
}

$flag_on_error = 0;

exit 0;
