use Forks::Super ':test';
use Forks::Super::Config ':all';
use Test::More tests => 5;
use Carp;
use strict;
use warnings;


#
# 60-os.t
#
# test features that interact with the operating system,
# like setting the priority of a background process
# or setting the CPU affinity of a background process
#

######################################################################

# update priority

my $output = "t/out/test-os.$$";

SKIP: {
    my $pid1 = fork { sub => sub { sleep 10 } };
    sleep 1;
    my $p1 = get_os_priority($pid1);

    if ($p1 >= 19) { # min priority on Unix
	skip "update priority test. Process is already at min priority", 2;
    }
    # change of plus 1 from default should be meaningful 
    # and valid on both Win32, Unix
    my $pid2 = fork { sub => sub { sleep 10 }, os_priority => $p1 + 1 };
    sleep 1;
    my $p2 = get_os_priority($pid2);
    ok($p1 != $p2, "priority has changed  $p1 / $p2");
    ok($p2 == $p1 + 1, "priority has changed by right amount");
}

######################################################################

# update cpu affinity - doesn't work very well on all platforms.

 SKIP: {
     if (!Forks::Super::Config::CONFIG_module("Sys::CpuAffinity")) {
	 skip "cpu affinity test: requires Sys::CpuAffinity", 2;
     }

     my $np = Sys::CpuAffinity::getNumCpus();
     if ($np == 1) {
	 skip "cpu affinity test: single-core system detected", 2;
     }
     if ($np <= 0) {
	 skip "cpu affinity test: could not detect number of processors!", 2;
     }
     if ($^O =~ /darwin/i || $^O =~ /aix/i || $^O =~ /^hp/i) {
	 skip "cpu affinity test: unsupported or poorly supported platform", 2;
     }
     if ((Sys::CpuAffinity::getAffinity($$)||0) <= 0) {
	 skip "cpu affinity test: "
	     . "Sys::CpuAffinity::getAffinity() not functioning on $^O/$]", 2;
     }

     my $pid3 = fork { sub => sub { sleep 10 }, cpu_affinity => 0x02 };
     if (!isValidPid($pid3)) {
	 ok(0, "fork failed with cpu_affinity option");
     } else {
	 # give some time for the right cpu affinity to be set
	 sleep 5;
	 my $affinity = Sys::CpuAffinity::getAffinity($pid3);
	 for (1 .. 5) {
	     last if $affinity == 0x02;
	     sleep 2;
	     $affinity = Sys::CpuAffinity::getAffinity($pid3);
	 }
	 ok($affinity == 0x02, "set cpu affinity $affinity==2")
	     or do {
		 sleep 5;
		 $affinity = Sys::CpuAffinity::getAffinity($pid3);
		 diag("final affinity: $affinity");
	 };
     }

     my $pid4 = fork { sub => sub { sleep 10 }, cpu_affinity => [ 0 ] };
     if (!isValidPid($pid4)) {
	 ok(0, "fork failed with cpu_affinity => \\\@list option");
     } else {
	 sleep 5;
	 my $affinity = Sys::CpuAffinity::getAffinity($pid4);
	 ok($affinity == 1, "set cpu affinity $affinity==1 with arrayref");
     }
}

######################################################################

# Win32-specific test. A spawned job should have the same CPU affinity
# from the psuedo-process (thread) that spawned it

SKIP: {
    if ($^O ne 'MSWin32') {
	skip "cpu affinity test of Win32 Process object on $^O", 1;
    }
    if (!Forks::Super::Config::CONFIG_module('Sys::CpuAffinity')) {
	skip "cpu affinity test, Sys::CpuAffinity module not installed", 1;
    }

    unlink "$output";
    my $pid = fork {
	cmd => [ $^X, "t/external-command.pl", 
		 "-o=$output", "--winpid", "-s=6" ],
	cpu_affinity => 1
    };
    sleep 2;
    open(my $T, '<', $output);
    my $winpid = <$T>;
    close $T;

    my $phandle = Forks::Super::Job::OS::Win32::get_process_handle($winpid);

#    diag("\$winpid is $winpid\n", (grep{/$winpid/}qx(TASKLIST)),
#	 "\$phandle is $phandle\n");

    if ($phandle) {
	my ($proc_affinity, $sys_affinity) = (' 'x16, ' 'x16);
	my $result 
	    = Forks::Super::Job::OS::Win32::win32api("GetProcessAffinityMask",
					     $phandle, $proc_affinity,
					     $sys_affinity);
	$proc_affinity = unpack "L", substr($proc_affinity."\0\0\0\0",0,4);
	$sys_affinity = unpack "L", substr($sys_affinity."\0\0\0\0",0,4);
	my $result2 = Sys::CpuAffinity::getAffinity($winpid);

#	diag("proc_affinity: $proc_affinity");
#	diag("sys_affinity:  $sys_affinity");
#	diag("SCU::getAffinity($winpid): $result2");

	ok($result != 0 && $proc_affinity == 1, 
	   "MSWin32 set affinity on external Win32::Process $proc_affinity==1"
	   ." $result/$result2");
    } else {
	ok(0, "could not obtain handle to external process on pid $winpid");
    }
}

waitall;
unlink $output;

######################################################################

sub get_os_priority {
    my ($pid) = @_;

    # freebsd: on error, getpriority returns -1 and sets $!

    my $p;
    local $! = 0;
    eval {
	$p = getpriority(0, $pid);
    };
    if ($@ eq '') {
	if ($p == -1 && $!) {
	    carp "get_os_priority($pid): $!";
	    return -99;
	}
	return $p;
    }

    if ($^O eq 'MSWin32') {
	return Forks::Super::Job::OS::Win32::get_priority($pid);
    }
    return;
}
