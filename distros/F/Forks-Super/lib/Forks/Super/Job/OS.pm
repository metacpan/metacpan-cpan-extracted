#
# Forks::Super::Job::OS
# implementation of
#     fork { name => ... , os_priority => ... ,
#            cpu_affinity => 0x... }
#

package Forks::Super::Job::OS;
use Forks::Super::Config ':all';
use Forks::Super::Debug qw(:all);
use Forks::Super::Util qw(isValidPid IS_WIN32 IS_CYGWIN);
use Carp;
use strict;
use warnings;
require Forks::Super::Job::OS::Win32 if &IS_WIN32 || &IS_CYGWIN;

our $VERSION = '0.95';

our $CPU_AFFINITY_CALLS = 0;
our $OS_PRIORITY_CALLS = 0;

sub _preconfig_os {
    my $job = shift;
    if (defined $job->{cpu_affinity}) {
        $job->{cpu_affinity_call} = ++$CPU_AFFINITY_CALLS;
        $job->{cpu_affinity_orig} =
            CONFIG('Sys::CpuAffinity') ? Sys::CpuAffinity::getAffinity($$):-1;
    }
    if (defined $job->{os_priority}) {
        $job->{os_priority_call} = ++$OS_PRIORITY_CALLS;
        $job->{os_priority_orig} = get_os_priority($job);
    }
    return;
}

#
# If desired and if the platform supports it, set
# job-specific operating system settings like
# process priority and CPU affinity.
# Should only be run from a child process
# immediately after the fork.
#
sub Forks::Super::Job::_config_os_child {
    my $job = shift;

#    if ($job->{setsid}) {
#      use POSIX ();
#      eval { print STDERR "\n\nsetsid\n\n"; POSIX::setsid(); }
#    }

    if (defined $job->{name}) {
	$0 = $job->{name}; # might affect ps(1) output
    } else {
	$job->{name} = $$;
    }

    if (defined $job->{umask}) {
	umask $job->{umask};
    }

    if (&IS_WIN32) {
	$ENV{_FORK_PPID} = $$;
    }
    if (defined $job->{os_priority}) {
	set_os_priority($job);
    }

    if (defined $job->{cpu_affinity}) {
	validate_cpu_affinity($job) && set_cpu_affinity($job);
    }
    return;
}

sub get_os_priority {
    my ($job) = @_;
    local $@ = undef;
    my $z = eval { getpriority(0,0) };
    return $z if !$@;
    if (&IS_WIN32) {
        if (CONFIG('Win32::API')) {
            require Forks::Super::Job::OS::Win32;
            return Forks::Super::Job::OS::Win32::get_priority($job);
        }
    }
    return -1;
}

sub set_os_priority {
    my ($job) = @_;
    my $priority = $job->{os_priority} || 0;

    local $@ = undef;
    my $z = eval {
	setpriority(0,0,$priority);
    };
    return 1 if !$@;

    if (&IS_WIN32) {
	if (!CONFIG('Win32::API')) {
	    if ($job->{os_priority_call} == 1) {
		carp 'Forks::Super::Job::_config_os_child(): ',
		    "cannot set child process priority on MSWin32.\n",
		    "Install the Win32::API module to enable this feature.\n";
	    }
	    return;
	}

	require Forks::Super::Job::OS::Win32;
	return Forks::Super::Job::OS::Win32::set_os_priority($job, $priority);
    }

    if ($job->{os_priority_call} == 1) {
	carp 'Forks::Super::Job::_config_os_child(): ',
	    "failed to set child process priority on $^O\n";
    }
    return;
}

sub set_cpu_affinity {
    my ($job) = @_;
    my $n = $job->{cpu_affinity};

    if ($n == 0 || (ref($n) eq 'ARRAY' && @$n==0)) {
	carp 'Forks::Super::Job::_config_os_child(): ',
	    "desired cpu affinity set to zero. Is that what you really want?\n";
    }

    if (CONFIG('Sys::CpuAffinity')) {
	return Sys::CpuAffinity::setAffinity($$, $n);
    } elsif ($job->{cpu_affinity_call} == 1) {
	carp_once 'Forks::Super::_config_os_child(): ',
	    "cannot set child process's cpu affinity.\n",
	    "Install the Sys::CpuAffinity module to enable this feature.\n";
    }
    return;
}

sub validate_cpu_affinity {
    my $job = shift;
    $job->{_cpu_affinity} = $job->{cpu_affinity};
    my $np = get_number_of_processors();
    if ($np <= 0) {
	$np = 0;
    }
    if (ref($job->{cpu_affinity}) eq 'ARRAY') {
	my @cpu_list = grep { $_ >= 0 && $_ < $np } @{$job->{cpu_affinity}};
	if (@cpu_list == 0) {
	    carp 'Forks::Super::Job::_config_os_child: ',
	        "desired cpu affinity [ @{$job->{cpu_affinity}} ] ",
	        "does not specify any of the valid $np processors ",
	        "available on your system.\n";
	    return 0;
	}
	if (@cpu_list < @{$job->{cpu_affinity}}) {
	    $job->{cpu_affinity} = [ @cpu_list ];
	}
    } else {
	if ($np > 0 && $job->{cpu_affinity} >= (2 ** $np)) {
	    $job->{cpu_affinity} &= (2 ** $np) - 1;
	}
	if ($job->{cpu_affinity} <= 0) {
	    carp 'Forks::Super::Job::_config_os_child: ',
	        "desired cpu affinity $job->{_cpu_affinity} does ",
	        "not specify any of the valid $np processors that ",
	        "seem to be available on your system.\n";
	    return 0;
	}
    }
    return 1;
}

sub get_cpu_load {
    if (CONFIG('Sys::CpuLoadX')) {
	my $load = Sys::CpuLoadX::get_cpu_load();
	if ($load >= 0.0) {
	    return $load;
	} else {
	    carp_once 'Forks::Super::Job::OS::get_cpu_load: ',
	        'Sys::CpuLoadX module is installed but still ',
	        "unable to get current CPU load for $^O $].";
	    return -1.0;
	}
    }

    if (-r '/proc/loadavg' && $^O ne 'cygwin') {
	if (open my $fh, '<', '/proc/loadavg') {
            my $line = <$fh>;
            close $fh;
            if ($line =~ /^(\d+[.,]\d+)\s+(\d+[.,]\d+)\s+(\d+[.,]\d+)/) {
                return $1;
            }
        }
    }

    # else pray for `uptime`.
    local %ENV = %ENV;
    $ENV{'LC_NUMERIC'} = 'POSIX';    # ensure decimal separator is a .
    my $uptime = qx(uptime 2>/dev/null);
    $uptime =~ s/\s+$//;
    my @uptime = split /[\s,]+/, $uptime;
    if (@uptime > 2) {
	if ($uptime[-3] =~ /\d/ && $uptime[-3] >= 0.0) {
	    return $uptime[-3];
	}
    }

    my $install = 'Install the Sys::CpuLoadX module';
    carp_once "Forks::Super: max_load feature not available.\n",
        "$install to enable this feature.\n";
    return -1.0;
}

my $_num_procs_cached;
sub get_number_of_processors {
    return $_num_procs_cached
	|| _get_number_of_processors_from_Sys_CpuAffinity()
	|| _get_number_of_processors_from_proc_cpuinfo()
	|| _get_number_of_processors_from_dmesg_bsd()
	|| _get_number_of_processors_from_psrinfo()
	|| _get_number_of_processors_from_ENV()
	|| $Forks::Super::SysInfo::NUM_PROCESSORS
	|| do {
	    my $install = 'Install the Sys::CpuAffinity module';
	    carp_once 'Forks::Super::get_number_of_processors(): ',
	        "feature unavailable.\n",
	        "$install to enable this feature.\n";
	    -1
    };
}

sub _get_number_of_processors_from_Sys_CpuAffinity {
    if (CONFIG('Sys::CpuAffinity')) {
	return $_num_procs_cached = Sys::CpuAffinity::getNumCpus();
    }
    return 0;
}

sub _get_number_of_processors_from_proc_cpuinfo {
    if (-r '/proc/cpuinfo') {
	my $num_processors = 0;
	my $procfh;
	if (open my $procfh, '<', '/proc/cpuinfo') {
	    while (<$procfh>) {
		if (/^processor\s/) {
		    $num_processors++;
		}
	    }
	    close $procfh;
	}
	return $_num_procs_cached = $num_processors;
    }
    return;
}

sub _get_number_of_processors_from_psrinfo {
    # it's rumored that  psrinfo -v  on solaris reports number of cpus
    if (CONFIG('/psrinfo')) {
	my $cmd = CONFIG('/psrinfo') . ' -v';
	my @psrinfo = qx($cmd 2>/dev/null);     ## no critic (Backtick)
	my $num_processors = grep { /Status of processor \d+/ } @psrinfo;
	return $_num_procs_cached = $num_processors;
    }
    return;
}

sub _get_number_of_processors_from_ENV {
    # sometimes set in Windows, can be spoofed
    if ($ENV{NUMBER_OF_PROCESSORS}) {
	return $_num_procs_cached = $ENV{NUMBER_OF_PROCESSORS};
    }
    return 0;
}

sub _get_number_of_processors_from_dmesg_bsd {
    # imported from  Sys::CpuAffinity::_getNumCpus_from_dmesg_bsd. 
    # this is one of the few reliably methods we have for openbsd,
    # where Sys::CpuAffinity can't be installed.
    return 0 if $^O !~ /bsd/i;

    my @dmesg;
    if (-r '/var/run/dmesg.boot' && open my $fh, '<', '/var/run/dmesg.boot') {
	@dmesg = <$fh>;
	close $fh;
    } elsif (! CONFIG('/dmesg')) {
	return 0;
    } else {
	my $cmd = CONFIG('/dmesg');
	@dmesg = qx($cmd 2> /dev/null);
    }

    # on the version of FreeBSD that I have to play with
    # (8.0), dmesg contains this message:
    #
    #       FreeBSD/SMP: Multiprocessor System Detected: 2 CPUs
    #
    # so we'll go with that.
    #
    # on NetBSD, the message is:
    #
    #       cpu3 at mainbus0 apid 3: AMD 686-class, 1975MHz, id 0x100f53

    # try FreeBSD format
    my @d = grep { /Multiprocessor System Detected:/i } @dmesg;
    my $ncpus;
    if (@d > 0) {
	debug("dmesg_bsd contains:\n@d") if $Forks::Super::DEBUG;
	($ncpus) = $d[0] =~ /Detected: (\d+) CPUs/i;
    }

    # try NetBSD format. This will also probably work for OpenBSD.
    if (!$ncpus) {
	# 1.05 - account for duplicates in @dmesg
	my %d = ();
	@d = grep { /^cpu\d+ at / } @dmesg;
	foreach my $dmesg (@d) {
	    if ($dmesg =~ /^cpu(\d+) at /) {
		$d{$1}++;
	    }
	}
	debug("dmesg_bsd[2] contains:\n",@d) if $Forks::Super::DEBUG;
	$ncpus = scalar keys %d;
    }
    if (@dmesg < 50 && $Forks::Super::DEBUG) {
	debug("full dmesg log:\n", @dmesg);
    }
    return $_num_procs_cached = $ncpus || 0;
}


# impose a timeout on a process from a separate small process.
# Usually, this is not the best way to get a process to shutdown
# after a timeout. Starting and stopping a new process has
# overhead for the operating system. It uses up a precious
# space in the process table. It terminates the process without
# prejudice, not allowing the process to clean itself up or
# otherwise trap a signal.
#
# But sometimes it is the best way if
#   * alarm() is not implemented on your system
#   * SIGALRM might not get delivered during a system call
#   * alarm() and sleep() are not compatible on your system
#   * you want to timeout a process that you will start with exec()
#   * you need to use alarm/SIGALRM for something else in your program
#
sub poor_mans_alarm {
    my ($pid, $time) = @_;

    if ($pid < 0) {
	# don't want to run in a separate process to kill a thread.
	if (CORE::fork() == 0) {
	    $0 = "PMA[2]($pid,$time)";
	    sleep(1), kill(0,$pid) || exit for 1..$time;
	    kill -9, $pid;
	    exit;
	}
    }

    # program to monitor a pid:
    my ($z,$p,$t) = ("PMA($pid,$time)",$pid,$time);
    my $prog = "\$0='$z';sleep 1,kill(0,$p)||exit for 1..$t;kill -9,$p";

    if (&IS_WIN32) {
	$prog .= ";system 'taskkill /f /pid $pid >nul'";
	my $pma_pid = system 1, qq[$^X -e "$prog"];
	if ($Forks::Super::Debug::DEBUG) {
	    debug("set poor man's alarm for $pid/$time in process $pma_pid");
	}
	return $pma_pid;
    } else {
	my $pm_pid = CORE::fork();
	if (!defined $pm_pid) {
	    carp 'FSJ::OS::poor_mans_alarm: fork to monitor process failed';
	    return;
	}
	if ($pm_pid == 0) {
	    exec($^X, '-e', $prog);
	}
	return $pm_pid;
    }
}

1;

__END__
