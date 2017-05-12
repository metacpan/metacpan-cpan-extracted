package Sys::CpuAffinity;
use Math::BigInt;
use Carp;
use warnings;
use strict;
use base qw(DynaLoader);
use Data::Dumper;

## no critic (ProhibitBacktick,RequireExtendedFormatting)
## no critic (DotMatch,LineBoundary,Sigils,Punctuation,Quotes,Magic,Checked)
## no critic (NamingConventions::Capitalization,BracedFileHandle)

our $VERSION = '1.12';
our $DEBUG = $ENV{DEBUG} || 0;
our $XS_LOADED = 0;
eval { bootstrap Sys::CpuAffinity $VERSION; $XS_LOADED = 1 };

sub TWO () { Math::BigInt->new(2) }

# sub import { }

#
# Development guide:
#
# when you figure out a new way to perform a task
# (in this case, getting cpu affinity), write the method and insert
# the call into the chain here.
#
# Methods should be named  _getAffinity_with_XXX, _setAffinity_with_XXX,
# or _getNumCpus_from_XXX. The t/inventory.pl file will identify these
# methods so they can be included in the tests.
#
# The new method should return false (0 or '' or undef) whenever it
# knows it is the wrong tool for the current system or any other time
# that it can't figure out the answer.
#
# For XS-based solutions, the stub will go in the distributions
# contrib/  directory, and will be available if it successfully
# compiles during the installation process. See
# _getAffinity_with_xs_sched_getaffinity  for an example of
# how to use a compiled function. All exported XS function names
# should begin with "xs_" and all function names, even the ones
# that aren't exported to XS, should be unique across the whole
# /contrib  space.
#
# Methods that might return with the wrong answer (for example, methods
# that make a guess) should go toward the end of the chain. This
# probably should include methods that read environment variables
# or methods that rely on external commands as these methods are
# easier to spoof, even accidentally.
#

sub getAffinity {
    my ($pid, %flags) = @_; # %flags reserved for future use
    my $wpid = $pid;

    my $mask = 0
	|| _getAffinity_with_taskset($pid)
	|| _getAffinity_with_xs_sched_getaffinity($pid)
	|| _getAffinity_with_xs_pthread_self_getaffinity($pid)
	|| _getAffinity_with_BSD_Process_Affinity($pid)
	|| _getAffinity_with_xs_freebsd_getaffinity($pid)
	|| _getAffinity_with_cpuset($pid)
	|| _getAffinity_with_xs_processor_affinity($pid)
	|| _getAffinity_with_pbind($pid)
	|| _getAffinity_with_xs_processor_bind($pid)
        || _getAffinity_with_psaix($pid)
	|| _getAffinity_with_xs_win32($pid)
	|| _getAffinity_with_xs_irix_sysmp($pid)
	|| _getAffinity_with_Win32Process($wpid)
	|| _getAffinity_with_Win32API($wpid)
	|| 0;

    return if $mask == 0;
    return wantarray ? _maskToArray($mask) : $mask;
}

sub _sanitize_set_affinity_args {
    my ($pid,$mask) = @_;

    if ($DEBUG) {
        print STDERR "sanitize_set_affinity_args: input is ",Dumper(@_),"\n";
    }

    return if ! $pid;
    if (ref $mask eq 'ARRAY') {
	$mask = _arrayToMask(@$mask);
        if ($DEBUG) {
            print STDERR "sanitize_set_affinity_args: ",
                         Dumper($_[1])," => $mask\n";
        }
    }
    my $np = getNumCpus();
    if ($mask == -1 && $np > 0) {
	$mask = (TWO ** $np) - 1;
        if ($DEBUG) {
            print STDERR "sanitize_set_affinity_args: -1 => ",
                         $mask," ",Dumper($mask),"\n";
        }
    }
    if ($mask <= 0) {
	carp "Sys::CpuAffinity: invalid mask $mask in call to setAffinty\n";
	return;
    }

    my $maxmask = TWO ** $np;
    if ($maxmask > 1 && $mask >= $maxmask) {
	my $newmask = $mask & ($maxmask - 1);
	if ($newmask == 0) {
	    carp "Sys::CpuAffinity: mask $mask is not valid for system with ",
	    "$np processors.\n";
	    return;
	} else {
	    carp "Sys::CpuAffinity: mask $mask adjusted to $newmask for ",
	    "system with $np processors\n";
	    $mask = $newmask;
	}
    }
    $_[1] = $mask;
    return 1;
}

sub setAffinity {
    my ($pid, $mask, %flags) = @_; # %flags reserved for future use

    return 0 if ! _sanitize_set_affinity_args($pid, $mask);

    return _setAffinity_with_Win32API($pid,$mask)
	|| _setAffinity_with_xs_win32($pid,$mask)
	|| _setAffinity_with_Win32Process($pid,$mask)
	|| _setAffinity_with_taskset($pid,$mask)
	|| _setAffinity_with_xs_sched_setaffinity($pid,$mask)
	|| _setAffinity_with_BSD_Process_Affinity($pid,$mask)
	|| _setAffinity_with_xs_freebsd_setaffinity($pid,$mask)
        || _setAffinity_with_xs_processor_affinity($pid,$mask)
	|| _setAffinity_with_pbind($pid,$mask)
        || _setAffinity_with_xs_processor_bind($pid,$mask)
	|| _setAffinity_with_xs_pthread_self_setaffinity($pid,$mask)
	|| _setAffinity_with_bindprocessor($pid,$mask)
	|| _setAffinity_with_cpuset($pid,$mask)
	|| _setAffinity_with_xs_irix_sysmp($pid,$mask)
	|| 0;
}

our $_NUM_CPUS_CACHED = 0;
sub getNumCpus {
    if ($_NUM_CPUS_CACHED) {
	return $_NUM_CPUS_CACHED;
    }
    return $_NUM_CPUS_CACHED =
	_getNumCpus_from_xs_Win32API_System_Info()
	|| _getNumCpus_from_xs_cpusetGetCPUCount()
	|| _getNumCpus_from_proc_cpuinfo()
	|| _getNumCpus_from_proc_stat()
	|| _getNumCpus_from_lsdev()
	|| _getNumCpus_from_bindprocessor()
	|| _getNumCpus_from_BSD_Process_Affinity()
	|| _getNumCpus_from_sysctl_freebsd()
	|| _getNumCpus_from_sysctl()
	|| _getNumCpus_from_dmesg_bsd()
        || _getNumCpus_from_xs_solaris()
	|| _getNumCpus_from_dmesg_solaris()
	|| _getNumCpus_from_psrinfo()
	|| _getNumCpus_from_hinv()
	|| _getNumCpus_from_hwprefs()
	|| _getNumCpus_from_system_profiler()
	|| _getNumCpus_from_Win32API_System_Info()
	|| _getNumCpus_from_Test_Smoke_SysInfo()
	|| _getNumCpus_from_prtconf()   # slower than bindprocessor, lsdev
	|| _getNumCpus_from_ENV()
	|| _getNumCpus_from_taskset()
	|| -1;
}

######################################################################

# count processors toolbox

sub _getNumCpus_from_ENV {
    # in some OS, the number of processors is part of the default environment
    # this also makes it easy to spoof the value (is that good or bad?)
    if ($^O eq 'MSWin32' || $^O eq 'cygwin') {
	if (defined $ENV{NUMBER_OF_PROCESSORS}) {
	    _debug("from Windows ENV: nproc=$ENV{NUMBER_OF_PROCESSORS}");
	    return $ENV{NUMBER_OF_PROCESSORS};
	}
    }
    return 0;
}

our %WIN32_SYSTEM_INFO = ();
our %WIN32API = ();

sub __is_wow64 {
    # determines whether this (Windows) program is running the WOW64 emulator
    # (to let 32-bit apps run on 64-bit architecture)

    # used in _getNumCpus_from_Win32API_System_Info to decide whether to use
    # GetSystemInfo  or  GetNativeSystemInfo  in the Windows API.

    return 0 if $^O ne 'MSWin32' && $^O ne 'cygwin';
    return 0 if !_configModule('Win32::API');
    return $Sys::CpuAffinity::IS_WOW64
	if $Sys::CpuAffinity::IS_WOW64_INITIALIZED++;

    my $hmodule = _win32api('GetModuleHandle', 'kernel32');
    return 0 if $hmodule == 0;

    my $proc = _win32api('GetProcAddress', $hmodule, 'IsWow64Process');
    return 0 if $proc == 0;

    my $current = _win32api('GetCurrentProcess');
    return 0 if $current == 0;  # carp ...

    my $bool = 0;
    my $result = _win32api('IsWow64Process', $current, $bool);
    if ($result != 0) {
	$Sys::CpuAffinity::IS_WOW64 = $bool;
    }
    $Sys::CpuAffinity::IS_WOW64_INITIALIZED++;
    return $Sys::CpuAffinity::IS_WOW64;
}

sub _getNumCpus_from_Win32API_System_Info {
    return 0 if $^O ne 'MSWin32' && $^O ne 'cygwin';
    return 0 if !_configModule('Win32::API');

    if (0 == scalar keys %WIN32_SYSTEM_INFO) {
	if (!defined $WIN32API{'GetSystemInfo'}) {
	    my $is_wow64 = __is_wow64();
	    my $lpsysinfo_type_avail
		= Win32::API::Type::is_known('LPSYSTEM_INFO');

	    my $proto = sprintf 'BOOL %s(%s i)',
		    $is_wow64 ? 'GetNativeSystemInfo' : 'GetSystemInfo',
		    $lpsysinfo_type_avail ? 'LPSYSTEM_INFO' : 'PCHAR';

	    $WIN32API{'GetSystemInfo'} = Win32::API->new('kernel32', $proto);
	}

	# does this part break on 64-bit machines? Don't think so.
	my $buffer = chr(0) x 36;
	$WIN32API{'GetSystemInfo'}->Call($buffer);
	($WIN32_SYSTEM_INFO{'PageSize'},
	 $WIN32_SYSTEM_INFO{'...'},
	 $WIN32_SYSTEM_INFO{'...'},
	 $WIN32_SYSTEM_INFO{'...'},
	 $WIN32_SYSTEM_INFO{'NumberOfProcessors'},
	 $WIN32_SYSTEM_INFO{'...'},
	 $WIN32_SYSTEM_INFO{'...'},
	 $WIN32_SYSTEM_INFO{'...'},
	 $WIN32_SYSTEM_INFO{'...'})
	    = unpack 'VVVVVVVvv',   substr $buffer,4;
    }
    return $WIN32_SYSTEM_INFO{'NumberOfProcessors'} || 0;
}


sub _getNumCpus_from_xs_cpusetGetCPUCount { # NOT TESTED irix
    if ($XS_LOADED && defined &xs_cpusetGetCPUCount) {
	return xs_cpusetGetCPUCount();
    } else {
	return 0;
    }
}

sub _getNumCpus_from_xs_Win32API_System_Info {
    if (defined &xs_get_numcpus_from_windows_system_info) {
	return xs_get_numcpus_from_windows_system_info();
    } elsif (defined &xs_get_numcpus_from_windows_system_info_alt) {
	return xs_get_numcpus_from_windows_system_info_alt();
    } else {
	return 0;
    }
}

sub _getNumCpus_from_proc_cpuinfo {

    # I'm told this could give the wrong answer with a "non-SMP kernel"
    # http://www-oss.fnal.gov/fss/hypermail/archives/hyp-linux/0746.html

    return 0 if ! -r '/proc/cpuinfo';

    my $num_processors = 0;
    my $cpuinfo_fh;
    if (open $cpuinfo_fh, '<', '/proc/cpuinfo') {
	while (<$cpuinfo_fh>) {
	    if (/^processor\s/) {
		$num_processors++;
	    }
	}
	close $cpuinfo_fh;
    }
    _debug("from /proc/cpuinfo: nproc=$num_processors");
    return $num_processors || 0;
}

sub _getNumCpus_from_proc_stat {

    return 0 if ! -r '/proc/stat';

    my $num_processors = 0;
    my $stat_fh;
    if (open $stat_fh, '<', '/proc/stat') {
	while (<$stat_fh>) {
	    if (/^cpu\d/i) {
		$num_processors++;
	    }
	}
	close $stat_fh;
    }
    _debug("from /proc/stat: nproc=$num_processors");
    return $num_processors || 0;
}

sub __set_aix_hints {
    my ($bindprocessor) = @_;
    our $AIX_HINTS = { READY => 0 };
    if (!$bindprocessor) {
        $bindprocessor = _configExternalProgram('bindprocessor');
    }
    return unless $bindprocessor;

    my $vp_output = qx('$bindprocessor' -q 2>/dev/null);
    if ($vp_output !~ s/The available process\S+ are:\s*//) {
        return;
    }
    my @vp = split /\s+/, $vp_output;
    @vp = sort { $a <=> $b } @vp;
    $AIX_HINTS->{VIRTUAL_PROCESSORS} = \@vp;
    my %vp = map {; $_ => -1 } @vp;
    my $proc_output = qx('$bindprocessor' -s 0 2>/dev/null);
    if ($proc_output !~ s/The available process\S+ are:\s*//) {
        $AIX_HINTS->{PROCESSORS} = $AIX_HINTS->{VIRTUAL_PROCESSORS};
        $AIX_HINTS->{NUM_CORES} = @vp;
        return;
    }
    my @procs = split /\s+/, $proc_output;
    @procs = sort { $a <=> $b } @procs;
    $AIX_HINTS->{PROCESSORS} = \@procs;
    $AIX_HINTS->{NUM_CORES} = @procs;
    $AIX_HINTS->{READY} = 1;
    if (@procs == @vp) {
        foreach my $proc (@procs) {
            $AIX_HINTS->{PROC_MAP}{$_} = $_;
        }
    } else {
        my $core = -1;
        foreach my $proc (@procs) {
            $core++;
            my $bound_output = qx('$bindprocessor' -b $proc 2>/dev/null);
            if ($bound_output =~ s/The available process\S+ are:\s*//) {
                my @bound_proc = split /\s+/, $bound_output;
                foreach my $bound_proc (@bound_proc) {
                    $AIX_HINTS->{PROC_MAP}{$bound_proc} = $core;
                }
            }
        }
    }
}

sub _is_solarisMultiCpuBinding {
    our $SOLARIS_HINTS;
    return unless $^O =~ /solaris/i;
    if (!$SOLARIS_HINTS || !$SOLARIS_HINTS->{multicpu}) {
        local $?;
        my ($maj,$min) = split /[.]/, qx(uname -v);
        if ($? == 0 && ($maj > 11 || ($maj == 11 && $min >= 2))) {
            $SOLARIS_HINTS->{multicpu} = 'yes';
        } elsif (defined &xs_setaffinity_processor_affinity) {
            $SOLARIS_HINTS->{multicpu} = 'yes';
        } else {
            $SOLARIS_HINTS->{multicpu} = 'no';
        }
    }
    return $SOLARIS_HINTS->{multicpu} eq 'yes';
}

sub _getNumCpus_from_bindprocessor {
    return 0 if $^O !~ /aix/i;
    return 0 if !_configExternalProgram('bindprocessor');
    my $cmd = _configExternalProgram('bindprocessor');
    our $AIX_HINTS;
    __set_aix_hints($cmd) unless $AIX_HINTS;
    return $AIX_HINTS->{NUM_CORES} || 0;
    #my $bindprocessor_output = qx($cmd -s 0 2>/dev/null); # or $cmd -q ?
    my $bindprocessor_output = qx($cmd -q 2>/dev/null); # or $cmd -s 0 ?
    $bindprocessor_output =~ s/\s+$//;
    return 0 if !$bindprocessor_output;

    # Typical output: "The available processors are: 0 1 2 3"
    $bindprocessor_output =~ s/.*:\s+//;
    my @p = split /\s+/, $bindprocessor_output;
    return 0+@p;
}

sub _getNumCpus_from_lsdev {
    return 0 if $^O !~ /aix/i;
    return 0 if !_configExternalProgram('lsdev');
    my $cmd = _configExternalProgram('lsdev');
    my @lsdev_output = qx($cmd -Cc processor 2>/dev/null);
    return 0+@lsdev_output;
}

sub _getNumCpus_from_dmesg_bsd {
    return 0 if $^O !~ /bsd/i;

    my @dmesg;
    if (-r '/var/run/dmesg.boot' && open my $fh, '<', '/var/run/dmesg.boot') {
	@dmesg = <$fh>;
	close $fh;
    } elsif (! _configExternalProgram('dmesg')) {
	return 0;
    } else {
	my $cmd = _configExternalProgram('dmesg');
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
	_debug("dmesg_bsd contains:\n@d");
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
	_debug("dmesg_bsd[2] contains:\n",@d);
	$ncpus = scalar keys %d;
    }
    if (@dmesg < 50) {
	_debug("full dmesg log:\n", @dmesg);
    }
    return $ncpus || 0;
}

sub _getNumCpus_from_xs_solaris {
    return 0 if $^O !~ /solaris/i;
    return 0 if !defined &xs_solaris_numCpus;
    my $n = eval { xs_solaris_numCpus() };
    return $n || 0;
}

sub _getNumCpus_from_sysctl_freebsd {
    return 0 unless defined &xs_num_cpus_freebsd;
    return xs_num_cpus_freebsd() || 0;
}

sub _getNumCpus_from_dmesg_solaris {
    return 0 if $^O !~ /solaris/i;
    return 0 if !_configExternalProgram('dmesg');
    my $cmd = _configExternalProgram('dmesg');
    my @dmesg = qx($cmd 2> /dev/null);

    # a few clues that I see on my system (opensolaris 5.11 i86pc):
    #      ... blah blah is bound to cpu <n>
    #      ^cpu<n>: x86 blah blah
    my $ncpus = 0;
    foreach my $dmesg (@dmesg) {
        if ($dmesg =~ /is bound to cpu (\d+)/) {
	  my $n = $1;
	  if ($ncpus <= $n) {
	    $ncpus = $n + 1;
	  }
        }
        if ($dmesg =~ /^cpu(\d+):/) {
	  my $n = $1;
	  if ($ncpus <= $n) {
	    $ncpus = $n + 1;
	  }
        }
    }

    # this doesn't always work 
    # (www.cpantesters.org/cpan/report/35d7685a-70b0-11e0-9552-4df9775ebe45)
    # what else should we check for in  @dmesg ?
    if ($ncpus == 0) {
      # ...
    }

    return $ncpus;
}

sub _getNumCpus_from_sysctl {
    # sysctl works on a number of systems including MacOS
    return 0 if !_configExternalProgram('sysctl');
    my $cmd = _configExternalProgram('sysctl');
    my @sysctl = qx($cmd -a 2> /dev/null);
    my @results = grep { /^hw.(?:avail|n)cpu\s*[:=]/ } @sysctl;
    _debug("sysctl output:\n@results");
    return 0 if @results == 0;
    my ($ncpus) = $results[0] =~ /[:=]\s*(\d+)/;

    if ($ncpus == 0) {
	my $result = qx($cmd -n hw.ncpu 2> /dev/null);
	_debug("sysctl[2] result: $result");
	$ncpus = 0 + $result;
    }
    if ($ncpus == 0) {
	my $result = qx($cmd -n hw.ncpufound 2> /dev/null);
	_debug("sysctl[3] result: $result");
	$ncpus = 0 + $result;
    }
    if ($ncpus == 0) {
	my $result = qx($cmd -n hw.availcpu 2> /dev/null);
	_debug("sysctl[4] result: $result");
	$ncpus = 0 + $result;
    }


    return $ncpus || 0;

    # there are also sysctl/sysctlbyname system calls
}

sub _getNumCpus_from_psrinfo {
    return 0 if !_configExternalProgram('psrinfo');
    my $cmd = _configExternalProgram('psrinfo');
    my @info = qx($cmd 2> /dev/null);
#   return scalar grep /core/, qx($cmd -t 2>/dev/null);
    return scalar @info;
}

sub _getNumCpus_from_hinv {   # NOT TESTED irix
    return 0 if $^O =~ /irix/i;
    return 0 if !_configExternalProgram('hinv');
    my $cmd = _configExternalProgram('hinv');

    # test debug
    if ($Sys::CpuAffinity::IS_TEST && !$Sys::CpuAffinity::HINV_CALLED++) {
	print STDERR "$cmd output:\n";
	print STDERR qx($cmd);
	print STDERR "\n\n";
	print STDERR "$cmd -c processor output:\n";
	print STDERR qx($cmd -c processor);
	print STDERR "\n\n";
    }

    # found this in Test::Smoke::SysInfo v0.042 in Test-Smoke-1.43 module
    my @processor = qx($cmd -c processor 2> /dev/null);
    _debug('"hinv -c processor" output: ', @processor);
    my ($cpu_cnt) = grep { /\d+.+processors?$/i } @processor;
    my $ncpu = (split ' ', $cpu_cnt)[0];

    if ($ncpu == 0) {
	# there might be output like:
	# PU 30 at Module 001c35/Slot 0/Slice C: 400 Mhz MIPS R12000 Processor
	$ncpu = grep { /^CPU / } @processor;
    }

    return $ncpu;
}

sub _getNumCpus_from_hwprefs {
    return 0 if $^O !~ /darwin/i && $^O !~ /MacOS/i;
    return 0 if !_configExternalProgram('hwprefs');
    my $cmd = _configExternalProgram('hwprefs');
    my $result = qx($cmd cpu_count 2> /dev/null);
    $result =~ s/\s+$//;
    _debug("\"$cmd cpu_count\" output: ", $result);
    return $result || 0;
}

sub _getNumCpus_from_system_profiler {  # NOT TESTED darwin
    return 0 if $^O !~ /darwin/ && $^O !~ /MacOS/i;
    return 0 if !_configExternalProgram('system_profiler');

    # with help from Test::Smoke::SysInfo
    my $cmd = _configExternalProgram('system_profiler');
    my $system_profiler_output
	= qx($cmd -detailLevel mini SPHardwardDataType 2> /dev/null);
    my %system_profiler;
    while ($system_profiler_output =~ m/^\s*([\w ]+):\s+(.+)$/gm) {
	$system_profiler{uc $1} = $2;
    }

    my $ncpus = $system_profiler{'NUMBER OF CPUS'};
    if (!defined $ncpus) {
	$ncpus = $system_profiler{'TOTAL NUMBER OF CORES'};
    }
    return $ncpus;
}

sub _getNumCpus_from_prtconf {
    # solaris has a prtconf command, but I don't think it outputs #cpus.
    return 0 if $^O !~ /aix/i;
    return 0 if !_configExternalProgram('prtconf');
    my $cmd = _configExternalProgram('prtconf');

    # prtconf can take a long time to run, so cache the result
    our $AIX_prtconf_cache;
    if (!defined($AIX_prtconf_cache)) {
        my @result = qx($cmd 2> /dev/null);
        my ($result) = grep { /Number Of Processors:/ } @result;
        return 0 if !$result;
        my ($ncpus) = $result =~ /:\s+(\d+)/;
        $AIX_prtconf_cache = $ncpus || 0;
    }
    return $AIX_prtconf_cache;
}

sub _getNumCpus_from_Test_Smoke_SysInfo {   # NOT TESTED
    return 0 if !_configModule('Test::Smoke::SysInfo');
    my $sysinfo = Test::Smoke::SysInfo->new();
    if (defined $sysinfo && defined $sysinfo->{_ncpu}) {
	# darwin: result might have format  "1 [2 cores]", see
	# www.cpantesters.org/cpan/report/db6067c4-9a66-11e0-91fb-39e97f60f2f7
	$sysinfo->{_ncpu} =~ s/\d+ \[(\d+) cores\]/$1/;
	return $sysinfo->{_ncpu};
    }
    return;
}

sub _getNumCpus_from_taskset {
    return 0 if $^O !~ /linux/i;
    my $taskset = _configExternalProgram('taskset');
    return 0 unless $taskset;

    # neither of these approaches are foolproof
    # 1. read affinity mask of PID 1
    # 2. try different affinity settings until it fails
    #
    # also I don't know what will happen if there are >64 cpus

    my $result = qx($taskset -p 1 2> /dev/null);
    my ($mask) = $result =~ /:\s+(\w+)/;
    if ($mask) {
	my $n = 1+__hex($mask);
	return int(0.5+log($n)/log(2));
    }

    my $n = 0;
    do {
	my $cmd = sprintf '%s -p %x $$', $taskset, 1<<$n;
	my $result = qx($cmd >/dev/null 2>/dev/null);
	$n++;
    } while ($?==0 && $n < 64);

    if ($n > 1) {      # n==1 could be a false positive
	return $n;
    }

    $n = 0;
    while ( do { qx($taskset -pc $n $$ >/dev/null 2>/dev/null); $?==0 } ) {
	$n++;
	last if $n >= 256;
    }
    return 0;
}

######################################################################

# get affinity toolbox

sub _getAffinity_with_Win32API {
    my $opid = shift;
    return 0 if $^O ne 'MSWin32' && $^O ne 'cygwin';
    return 0 if !_configModule('Win32::API');

    my $pid = $opid;
    if ($^O eq 'cygwin') {
	$pid = __pid_to_winpid($opid);
	# return 0 if !defined $pid;
    }
    return 0 if !$pid;

    if ($pid > 0) {
	return _getProcessAffinity_with_Win32API($pid);
    } else { # $pid is a Windows pseudo-process (thread ID)
	return _getThreadAffinity_with_Win32API(-$pid);
    }
}

sub _getProcessAffinity_with_Win32API {
    my $pid = shift;
    my ($processMask, $systemMask, $processHandle) = (' ' x 16, ' ' x 16);

    # 0x0400 - PROCESS_QUERY_INFORMATION,
    # 0x1000 - PROCESS_QUERY_LIMITED_INFORMATION
    $processHandle = _win32api('OpenProcess',0x0400,0,$pid)
	|| _win32api('OpenProcess',0x1000,0,$pid);
    return 0 if ! $processHandle;
    return 0 if ! _win32api('GetProcessAffinityMask', $processHandle,
			    $processMask, $systemMask);

    my $mask = _unpack_Win32_mask($processMask);
    _debug("affinity with Win32::API: $mask");
    return $mask;
}

sub _getThreadAffinity_with_Win32API {
    my $thrid = shift;
    my ($processMask, $systemMask, $threadHandle) = (' 'x16, ' 'x16);

    # 0x0020: THREAD_QUERY_INFORMATION
    # 0x0400: THREAD_QUERY_LIMITED_INFORMATION
    # 0x0040: THREAD_SET_INFORMATION
    # 0x0200: THREAD_SET_LIMITED_INFORMATION
    $threadHandle = _win32api('OpenThread', 0x0060, 0, $thrid)
        || _win32api('OpenThread', 0x0600, 0, $thrid)
        || _win32api('OpenThread', 0x0020, 0, $thrid)
        || _win32api('OpenThread', 0x0400, 0, $thrid);
    if (! $threadHandle) {
	return 0;
    }

    # The Win32 API does not have a  GetThreadAffinityMask  function.
    # SetThreadAffinityMask  will return the previous affinity,
    # but then you have to call it again to restore the original affinity.
    # Also, SetThreadAffinityMask won't work if you don't have permission
    # to change the affinity.

    # SetThreadAffinityMask argument has to be compatible with
    # process affinity, so get process affinity.

    # XXX - this function only works for threads that are contained
    #       by the current process, and that should cover most use
    #       cases of this module. But how would you get the process
    #       id of an arbitrary Win32 thread?
    my $cpid = _win32api('GetCurrentProcessId');

    my $processHandle
	= _win32api('OpenProcess', 0x0400, 0, $cpid)
	|| _win32api('OpenProcess', 0x1000, 0, $cpid);

    local ($!,$^E) = (0,0);
    my $result = _win32api('GetProcessAffinityMask',
			   $processHandle, $processMask, $systemMask);

    if ($result == 0) {
	carp 'Could not determine process affinity ',
	        "(required to get thread affinity)\n";
	return 0;
    }

    $processMask = _unpack_Win32_mask($processMask);
    if ($processMask == 0) {
	carp 'Process affinity apparently set to zero, ',
        	"will not be able to set/get compatible thread affinity\n";
	return 0;
    }

    my $previous_affinity = _win32api('SetThreadAffinityMask',
				      $threadHandle, $processMask);

    if ($previous_affinity == 0) {
	Carp::cluck "Win32::API::SetThreadAffinityMask: $! / $^E\n";
	return 0;
    }

    # hope we can restore it.
    if ($previous_affinity != $processMask) {
	local $! = 0;
	local $^E = 0;
	my $new_affinity = _win32api('SetThreadAffinityMask',
				     $threadHandle, $previous_affinity);
	if ($new_affinity == 0) {

	    # http://msdn.microsoft.com/en-us/library/ms686247(v=vs.85).aspx:
	    #
	    # "If the thread affinity mask requests a processor that is not
	    # selected for the process affinity mask, the last error code
	    # is ERROR_INVALID_PARAMETER." ($! => 87)
	    #
	    # In MSWin32, the result of a fork() is a "pseudo-process",
	    # a Win32 thread that is still contained by its parent.
	    # So on MSWin32 a race condition exists where the parent
	    # process can choose an incompatible set of affinities
	    # during the execution of this function (basically, between
	    # the two calls to  SetThreadAffinityMask , above).

	    carp "Sys::CpuAffinity::_getThreadAffinity_with_Win32API:\n",
		    "set thread $thrid affinity to $processMask ",
		    "in order to retrieve\naffinity, but was unable to ",
		    "restore previous value:\nHandle=$threadHandle, ",
		    "Prev=$previous_affinity, Error=$! / $^E\n";
	}
    }
    return $previous_affinity;
}

sub _unpack_Win32_mask {
    # The Win32 GetProcessAffinityMask function takes
    # "PDWORD" arguments. We pass (arbitrary) integers for these
    # arguments, but on return they are changed to 1-4 bytes
    # representing a packed integer.

    my $packed = shift;
    return unpack "L", substr($packed . "\0\0\0\0", 0, 4);
}



sub _getAffinity_with_Win32Process {
    my $pid = shift;

    return 0 if $^O ne 'MSWin32' && $^O ne 'cygwin';
    return 0 if !_configModule('Win32::Process');
    return 0 if $pid < 0;  # pseudo-process / thread id

    if ($^O eq 'cygwin') {
	$pid = __pid_to_winpid($pid);
	return 0 if !defined $pid;
    }

    my ($processMask, $systemMask, $result, $processHandle) = (' 'x16, ' 'x16);
    if (! Win32::Process::Open($processHandle, $pid, 0)
	|| ref($processHandle) ne 'Win32::Process') {
	return 0;
    }
    if (! $processHandle->GetProcessAffinityMask($processMask, $systemMask)) {
	return 0;
    }
    _debug("affinity with Win32::Process: $processMask");
    return $processMask;
}

sub _getAffinity_with_taskset {
    my $pid = shift;
    return 0 if $^O ne 'linux';
    return 0 if !_configExternalProgram('taskset');
    my $taskset = _configExternalProgram('taskset');
    my $taskset_output = qx($taskset -p $pid 2> /dev/null);
    $taskset_output =~ s/\s+$//;
    _debug("taskset output: $taskset_output");
    return 0 if ! $taskset_output;
    my ($mask) = $taskset_output =~ /: (\S+)/;
    _debug("affinity with taskset: $mask");
    return __hex($mask);
}

sub __hex {
    # hex() method with better support for input > 0xffffffff
    my $mask = shift;
    if (length($mask) > 8) {
        my $mask2 = substr($mask,-8);
        my $mask1 = substr($mask,0,-8);
        return hex($mask2) + (__hex($mask1) << 32);
    } else {
        return hex($mask);
    }
}

sub _getAffinity_with_xs_sched_getaffinity {
    my $pid = shift;
    return 0 if !defined &xs_sched_getaffinity_get_affinity;
    my @mask;
    my $r = xs_sched_getaffinity_get_affinity($pid,\@mask,0);
    if ($r) {
        return _arrayToMask(@mask);
    }
    return;
}

sub _getAffinity_with_xs_DEBUG_sched_getaffinity {
    # to debug errors in xs_sched_getaffinity_get_affinity
    # during t/11-exercise-all.t
    my $pid = shift;
    return 0 if !defined &xs_sched_getaffinity_get_affinity;
    my @mask;
    my $r = xs_sched_getaffinity_get_affinity($pid,\@mask,1);
    if ($r) {
        return _arrayToMask(@mask);
    }
    return;
}

sub _getAffinity_with_pbind {
    my ($pid) = @_;
    return 0 if $^O !~ /solaris/i;
    return 0 if !_configExternalProgram('pbind');
    my $pbind = _configExternalProgram('pbind');
    my $cmd = "$pbind -q $pid";
    my $pbind_output = qx($cmd 2> /dev/null);
    if ($pbind_output eq '' && $? == 0) {

        # pid is unbound  or  pid is invalid?
        if (kill 'ZERO', $pid) {      
            $pbind_output = 'not bound';
        } else {
            warn "_getAffinity_with_pbind: could not signal unbound pid $pid";
            return;
        }
    }

    # possible output:
    #     process id $pid: $index
    #     process id $pid: not bound
    #     pid \d+ \w+ bound to proccessor(s) \d+ \d+ \d+.

    if ($pbind_output =~ /not bound/) {
        my $np = getNumCpus();
        if ($np > 0) {
            return (TWO ** $np) - 1;
        } else {
            carp '_getAffinity_with_pbind: ',
            "process $pid unbound but can't count processors\n";
            return TWO**32 - 1;
        }
    } elsif ($pbind_output =~ /: (\d+)/) {
        my $bound_processor = $1;
        return TWO ** $bound_processor;
    } elsif ($pbind_output =~ / bound to proces\S+\s+(.+)\.$/) {
        my $cpus = $1;
        if (!defined($cpus)) {
            return 0;
        }
        my @cpus = split /\s+/, $1;
        return _arrayToMask(@cpus);
    }
    return 0;
}

sub _getAffinity_with_psaix {
    my ($pid) = @_;
    return 0 if $^O !~ /aix/i;
    my $pscmd = _configExternalProgram('ps');
    return 0 if !$pscmd;
    our $AIX_HINTS;
    __set_aix_hints() unless $AIX_HINTS;

    my ($header,$data) = qx(ps -o THREAD -p $pid 2>/dev/null);
    return 0 unless $data;
    $header =~ s/^\s+//;
    my @h = split /\s+/, $header;
    my @d = split /\s+/, $data;
    my ($ipid) = grep { $h[$_] eq 'PID' } 0 .. $#h;
    my ($ibnd) = grep { $h[$_] eq 'BND' } 0 .. $#h;
    if ($ipid ne '' && $ibnd) {
        my $pidd = $d[$ipid];
        my $bndd = $d[$ibnd];
        if ($pidd == $pid) {
            $bndd =~ s/^\s+//;
            $bndd =~ s/\s+$//;
            if ($bndd eq '-') { # not bound
                return (TWO ** getNumCpus()) - 1;
            }
            if ($AIX_HINTS) {
                $bndd = $AIX_HINTS->{PROC_MAP}{$bndd} || $bndd;
            }
            return TWO ** $bndd;
        }
    }
    warn "ps\\aix: could not parse result:\n$header$data\n";
    return 0;
}

sub _getAffinity_with_xs_processor_affinity {
    my ($pid) = @_;
    return 0 if !defined &xs_getaffinity_processor_affinity;
    my @mask = ();
    my $ret = xs_getaffinity_processor_affinity($pid,\@mask);
    if ($ret == 0) {
        return 0;
    }
    _debug("affinity with getaffinity_xs_processor_affinity: @mask");
    return _arrayToMask(@mask);
}

sub _getAffinity_with_xs_processor_bind {
    my ($pid) = @_;
    return 0 if !defined &xs_getaffinity_processor_bind;
    return 0 if $^O !~ /solaris/i;
    return 0 if _is_solarisMultiCpuBinding();
    my @mask = ();
    my $ret = xs_getaffinity_processor_bind($pid,\@mask);
    if ($ret == 0) {
        return 0;
    }
    _debug("affinity with getaffinity_xs_processor_affinity: @mask");
    return _arrayToMask(@mask);
}

sub _getAffinity_with_BSD_Process_Affinity {
    my ($pid) = @_;
    return 0 if $^O !~ /bsd/i;
    return 0 if !_configModule('BSD::Process::Affinity','0.04');

    my $mask;
    if (! eval {
	my $affinity = BSD::Process::Affinity::get_process_mask($pid);
	$mask = $affinity->get;
        1 }  ) {
        # $MODULE{'BSD::Process::Affinity'} = 0
        _debug("error in _setAffinity_with_BSD_Process_Affinity: $@");
        return 0;
    }
    return $mask;
}

sub _getAffinity_with_cpuset {
    my ($pid) = @_;
    return 0 if $^O !~ /bsd/i;
    return 0 if !_configExternalProgram('cpuset');
    my $cpuset = _configExternalProgram('cpuset');
    my $cmd = "$cpuset -g -p $pid";
    my $cpuset_output = qx($cmd 2> /dev/null);

    # output format:
    #     pid nnnnn mask: i, j, k, ...

    $cpuset_output =~ s/.*:\s*//;
    my @cpus = split /\s*,\s*/, $cpuset_output;
    if (@cpus > 0) {
        return _arrayToMask(@cpus);
    }
    return 0;
}

sub _getAffinity_with_xs_freebsd_getaffinity {
    my $pid = shift;
    return 0 if !defined &xs_getaffinity_freebsd;
    my @mask = ();
    my $ret = xs_getaffinity_freebsd($pid,\@mask,0);
    if ($ret == 0) {
	return 0;
    }
    return _arrayToMask(@mask);
}

sub _getAffinity_with_xs_freebsd_getaffinity_debug {
    my $pid = shift;
    if (!defined &xs_getaffinity_freebsd) {
        if ($^O =~ /bsd/) {
            warn "\$^O=$^O, xs_getaffinity_freebsd not defined";
        }
        return;
    }
    my @mask = ();
    my $ret = xs_getaffinity_freebsd($pid,\@mask,1);
    warn "return value from xs_getaffinity_freebsd: $ret";
    if ($ret == 0) {
	return 0;
    }
    return _arrayToMask(@mask);
}

sub _getAffinity_with_xs_win32 {
    my ($opid) = @_;
    my $pid = $opid;
    if ($^O =~ /cygwin/) {
        $pid = __pid_to_winpid($opid);
        return 0 if !defined $pid;
    }

    if ($pid < 0) {
        return 0 if !defined &xs_win32_getAffinity_thread;
        return xs_win32_getAffinity_thread(-$pid);
    } elsif ($opid == $$) {
        if (defined &xs_win32_getAffinity_proc) {
            return xs_win32_getAffinity_proc($pid);
        } elsif (defined &xs_win32_getAffinity_thread) {
            return xs_win32_getAffinity_thread(0);
        } else {
        }
        return 0;
    } elsif (defined &xs_win32_getAffinity_proc) {
        return xs_win32_getAffinity_proc($pid);
    }
    return 0;
}

sub _getAffinity_with_xs_pthread_self_getaffinity {

    # new in 1.00, may only work when run as root

    my ($pid) = @_;
    return 0 if $^O !~ /bsd/;

    # this function can only be used on the calling process.
    return 0 if $pid != $$;
    return 0 if !defined &xs_pthread_self_getaffinity;
    my $z = xs_pthread_self_getaffinity(0);
    if ($z == 0) {

        # does $z==0 mean that the current thread is not bound (i.e.,
        # bound to all processors)? Or does it mean that the
        # pthread_getaffinity_np() call didn't do anything (but still
        # returned 0/success?)
        # Does pthread_getaffinity_np() always return 0 for normal users
        # and return non-zero for the super-user?

        # must use $_NUM_CPUS_CACHED || ... to pass test t/12#2
        my $np = $_NUM_CPUS_CACHED || getNumCpus();
        my $maxmask = TWO ** $np - 1;

        my $y = _setAffinity_with_xs_pthread_self_setaffinity($pid, $maxmask);
        if ($y) {
            return $maxmask;
        } else {
            return 0;
        }
    }
    return $z;
}

sub _getAffinity_with_xs_irix_sysmp {

    # new in 1.00, not tested

    my ($pid) = @_;
    return 0 if $^O !~ /irix/i;
    return 0 if !defined &xs_irix_sysmp_getaffinity;
    my $result = xs_irix_sysmp_getaffinity($pid);
    if ($result < -1) { # error
        return 0;
    } elsif ($result == -1) { # unrestricted
        my $np = getNumCpus();
        return TWO ** $np - 1;
    } else {  # restricted to a single processor.
        return TWO ** $result;
    }
}

######################################################################

# set affinity toolbox

sub _setAffinity_with_Win32API {
    my ($pid, $mask) = @_;
    return 0 if $^O ne 'MSWin32' && $^O ne 'cygwin';
    return 0 if !_configModule('Win32::API');

    # if $^O is 'cygwin', make sure you are passing the Windows pid,
    # using Cygwin::pid_to_winpid if necessary!

    if ($^O eq 'cygwin') {
        $pid = __pid_to_winpid($pid);
        if ($DEBUG) {
            print STDERR "winpid is $pid ($_[0])\n";
        }
        return 0 if !defined $pid;
    }

    if ($pid > 0) {
        my $processHandle;
        # 0x0200 - PROCESS_SET_INFORMATION
        $processHandle = _win32api('OpenProcess', 0x0200,0,$pid);
        if ($DEBUG) {
            print STDERR "process handle: $processHandle\n";
        }
        return 0 if ! $processHandle;
        my $result = _win32api('SetProcessAffinityMask', $processHandle, $mask);
        _debug("set affinity with Win32::API: $result");
        return $result;
    } else {
        # negative pid indicates Windows "pseudo-process", which should
        # use the Thread functions.
        # Thread access rights definitions:
        # 0x0020: THREAD_QUERY_INFORMATION
        # 0x0400: THREAD_QUERY_LIMITED_INFORMATION
        # 0x0040: THREAD_SET_INFORMATION
        # 0x0200: THREAD_SET_LIMITED_INFORMATION
        my $threadHandle;
        local $! = undef;
        local $^E = 0;
        $threadHandle = _win32api('OpenThread', 0x0060, 0, -$pid)
            || _win32api('OpenThread', 0x0600, 0, -$pid)
            || _win32api('OpenThread', 0x0040, 0, -$pid)
            || _win32api('OpenThread', 0x0200, 0, -$pid);
        return 0 if ! $threadHandle;
        my $previous_affinity = _win32api('SetThreadAffinityMask',
                                          $threadHandle, $mask);
        if ($previous_affinity == 0) {
            carp 'Sys::CpuAffinity::_setAffinity_with_Win32API: ',
                 "SetThreadAffinityMask call failed: $! / $^E\n";
        }
        return $previous_affinity;
    }
}

sub _setAffinity_with_Win32Process {
    my ($pid, $mask) = @_;
    return 0 if $^O ne 'MSWin32';   # cygwin? can't get it to work reliably
    return 0 if !_configModule('Win32::Process');

    if ($^O eq 'cygwin') {
        $pid = __pid_to_winpid($pid);

        if ($DEBUG) {
            print STDERR "cygwin pid $_[0] => winpid $pid\n";
        }
        return 0 if !defined $pid;
    }

    my $processHandle;
    if (! Win32::Process::Open($processHandle, $pid, 0)
        || ref($processHandle) ne 'Win32::Process') {
        return 0;
    }

    # Seg fault on Cygwin? We really prefer not to use it on Cygwin.
    local $SIG{SEGV} = 'IGNORE';

    # SetProcessAffinityMask: "only available on Windows NT"
    use Config;
    my $v = $Config{osvers};
    if ($^O eq 'MSWin32' && ($v < 3.51 || $v >= 6.0)) {
        if ($DEBUG) {
            print STDERR 'SetProcessAffinityMask ',
                         "not available on MSWin32 osvers $v?\n";
        }
        return 0;
    }
    # Don't trust Strawberry Perl $Config{osvers}. Win32::GetOSVersion
    # is more reliable if it is available.
    if (_configModule('Win32')) {
        if (!Win32::IsWinNT()) {
            if ($DEBUG) {
                print STDERR 'SetProcessorAffinityMask ',
                             "not available on MSWin32 OS Version $v\n";
            }
            return 0;
        }
    }

    my $result = $processHandle->SetProcessAffinityMask($mask);
    _debug("set affinity with Win32::Process: $result");
    return $result;
}

sub _setAffinity_with_taskset {
    my ($pid, $mask) = @_;
    return 0 if $^O ne 'linux' || !_configExternalProgram('taskset');
    my $cmd = sprintf '%s -p %x %d 2>&1',
		    _configExternalProgram('taskset'), $mask, $pid;

    my $taskset_output = qx($cmd 2> /dev/null);
    my $taskset_status = $?;

    if ($taskset_status) {
        _debug("taskset output: $taskset_output");
    }

    return $taskset_status == 0;
}

sub _setAffinity_with_xs_sched_setaffinity {
    my ($pid,$mask) = @_;
    return 0 if !defined &xs_sched_setaffinity_set_affinity;
    my @mask = _maskToArray($mask);
    return xs_sched_setaffinity_set_affinity($pid,\@mask);
}

sub _setAffinity_with_BSD_Process_Affinity {
    my ($pid,$mask) = @_;
    return 0 if $^O !~ /bsd/i;
    return 0 if !_configModule('BSD::Process::Affinity','0.04');

    if (not eval {
	my $affinity = BSD::Process::Affinity::get_process_mask($pid);
	$affinity->set($mask)->update;
        1}) {
        _debug("error in _setAffinity_with_BSD_Process_Affinity: $@");
        return 0;
    }
}

sub _getNumCpus_from_BSD_Process_Affinity {
    return 0 if $^O !~ /bsd/i;
    return 0 if !_configModule('BSD::Process::Affinity','0.04');
    my $n = BSD::Process::Affinity::current_set()->get;
    $n = log( $n+1.01 ) / log(2);
    return int($n);
}

sub _setAffinity_with_bindprocessor {
    my ($pid,$mask) = @_;
    return 0 if $^O !~ /aix/i;
    return 0 if $pid < 0;
    return 0 if !_configExternalProgram('bindprocessor');
    my $cmd = _configExternalProgram('bindprocessor');
    our $AIX_HINTS;
    __set_aix_hints($cmd) unless $AIX_HINTS;

    my @mask = _maskToArray($mask);
    my @cores = map { $AIX_HINTS->{PROCESSORS}[$_] } @mask;
    if (@cores == $AIX_HINTS->{NUM_CORES}) {
        return system("'$cmd' -u $pid") == 0;
    } elsif (@cores > 1) {
        warn "_setAffinity_with_bindprocessor: will only set one core on aix";
    }
    return system("'$cmd' $pid $cores[0]") == 0;
}

sub _setAffinity_with_pbind {
    my ($pid,$mask) = @_;
    return 0 if $^O !~ /solaris/i;
    return 0 if !_configExternalProgram('pbind');
    my $pbind = _configExternalProgram('pbind');
    my @mask = _maskToArray($mask);

    my $cpus = join ",", @mask;
    my $np = getNumCpus();
    my $c1;
    if (@mask == $np) {
        # unbind
        $c1 = system("'$pbind' -u $pid > /dev/null 2>&1");
    } else {
        $c1 = system("'$pbind' -b -c $cpus -s $pid > /dev/null 2>&1");
    }
    return !$c1;
}

sub _setAffinity_with_xs_processor_affinity {
    my ($pid,$mask) = @_;
    return 0 if $^O !~ /solaris/i;
    return 0 if !defined &xs_setaffinity_processor_affinity;
    my @mask = _maskToArray($mask);
    my $ret = xs_setaffinity_processor_affinity($pid, \@mask);
    if ($ret == 0) {
        return 0;
    }
    return 1;
}

sub _setAffinity_with_xs_processor_bind {
    my ($pid,$mask) = @_;
    return 0 if $^O !~ /solaris/i;
    return 0 if !defined &xs_setaffinity_processor_bind;
    return 0 if _is_solarisMultiCpuBinding();
    my @mask = _maskToArray($mask);
    my $ret = xs_setaffinity_processor_bind($pid, \@mask);
    if ($ret == 0) {
        return 0;
    }
    return 1;
}

sub _setAffinity_with_cpuset {
    my ($pid, $mask) = @_;
    return 0 if $^O !~ /bsd/i;
    return 0 if !_configExternalProgram('cpuset');

    my $lmask = join ',' => _maskToArray($mask);
    my $cmd = _configExternalProgram('cpuset') . " -l $lmask -p $pid";
    my $c1 = system "$cmd 2> /dev/null";
    return !$c1;
}

sub _setAffinity_with_xs_freebsd_setaffinity {
    my ($pid,$mask) = @_;
    return 0 if !defined &xs_setaffinity_freebsd;
    my @mask = _maskToArray($mask);
    return xs_setaffinity_freebsd($pid,\@mask);
}

sub _setAffinity_with_xs_win32 {
    my ($opid, $mask) = @_;

    my $pid = $opid;
    if ($^O =~ /cygwin/) {
        $pid = __pid_to_winpid($opid);
        return 0 if !defined $pid;
    }

    if ($pid < 0) {
        if (defined &xs_win32_setAffinity_thread) {
            my $r = xs_win32_setAffinity_thread(-$pid,$mask);
            _debug("xs_win32_setAffinity_thread -$pid,$mask => $r");
            return $r if $r;
        }
        return 0;
    } elsif ($opid == $$) {
        if (defined &xs_win32_setAffinity_proc) {
            _debug('xs_win32_setAffinity_proc $$');
            return xs_win32_setAffinity_proc($pid,$mask);
        }
        if ($^O eq 'cygwin' && defined &xs_win32_setAffinity_thread) {
            my $r = xs_win32_setAffinity_thread(0, $mask);
            return $r if $r;
        }
        return 0;
    } elsif (defined &xs_win32_setAffinity_proc) {
        my $r = xs_win32_setAffinity_proc($pid, $mask);
        _debug("xs_win32_setAffinity_proc +$pid,$mask => $r");
        return $r;
    }
    return 0;
}

sub _setAffinity_with_xs_pthread_self_setaffinity {

    # new in 1.00, may only work when run as root

    my ($pid, $mask) = @_;
    return 0 if $^O !~ /bsd/i;

    # this function only works with the calling process
    return 0 if $$ != $pid;
    return 0 if !defined &xs_pthread_self_setaffinity;
    return &xs_pthread_self_setaffinity($mask);
}

sub _setAffinity_with_xs_irix_sysmp {

    # new in 1.00, not tested

    my ($pid, $mask) = @_;

    return 0 if $^O !~ /irix/i;
    return 0 if !defined &xs_irix_sysmp_setaffinity;

    # Like the  pbind  function in solaris, Irix's sysmp function can only
    #   * bind a process to a single specific CPU, or
    #   * bind a process to all CPUs

    my @mask = _maskToArray($mask);

    my $np = getNumCpus();
    my $c1;
    if ($np > 0 && $mask + 1 == TWO ** $np) {
        return xs_irix_sysmp_setaffinity($pid, -1);
    } else {
        my $element = 0;
        return xs_irix_sysmp_setaffinity($pid, $mask[$element]);
    }
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _maskToArray {
    my ($mask) = @_;
    my @mask = ();
    my $i = 0;
    while ($mask > 0) {
        if ($mask & 1) {
            push @mask, $i;
        }
        $i++;
        $mask >>= 1;
    }
    return @mask;
}

sub _arrayToMask {
    my @procs = @_;
    my $mask = Math::BigInt->new(0);
    for my $proc (@procs) {
        $mask |= TWO ** $proc;
    }
    return $mask;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub __pid_to_winpid {
    my ($cygwinpid) = @_;
    if ($] >= 5.008 && defined &Cygwin::pid_to_winpid) {
        return Cygwin::pid_to_winpid($cygwinpid);
    } else {
        return __poor_mans_pid_to_winpid($cygwinpid);
    }
}

sub __poor_mans_pid_to_winpid {
    my ($cygwinpid) = @_;
    my @psw = qx(/usr/bin/ps -W 2> /dev/null);
    foreach my $psw (@psw) {
        $psw =~ s/^[A-Z\s]+//;
        my ($pid,$ppid,$pgid,$winpid) = split /\s+/, $psw;
        next if ! $pid;
        if ($pid == $cygwinpid) {
            return $winpid;
        }
    }
    warn "Could not resolve cygwin pid $cygwinpid into winpid.\n";
    return $cygwinpid;
}

######################################################################

# configuration code

sub _debug {
    my @msg = @_;
    return if !$DEBUG;
    print STDERR 'Sys::CpuAffinity: ',@msg,"\n";
    return;
}

our %MODULE = ();
our %PROGRAM = ();
our %INLINE_CODE = ();

sub _configModule {
    my $module = shift;
    my $version = shift || "";
    return $MODULE{$module} if defined $MODULE{$module};

    if (eval "require $module") {        ## no critic (StringyEval)
	my $v = eval "\$$module" . "::VERSION";
	if (!$@ && (!$version || $version <= $v)) {
	    _debug("module $module is available.");
	    return $MODULE{$module} = 1;
	} else {
	    _debug("module $module $version not available ($v)");
	    return $MODULE{$module} = 0;
	}
    } else {
        _debug("module $module $version not available: $@");
        return $MODULE{$module} = 0;
    }
}

our @PATH = ();

sub _configExternalProgram {
    my $program = shift;
    return $PROGRAM{$program} if defined $PROGRAM{$program};
    if (-x $program) {
        _debug("Program $program is available in $program");
        return $PROGRAM{$program} = $program;
    }

    if ($^O ne 'MSWin32') {
        my $which = qx(which $program 2> /dev/null);
        $which =~ s/\s+$//;

        if ($which =~ / not in /                # negative output on irix
            || $which =~ /no \Q$program\E in /  # negative output on solaris
            || $which =~ /Command not found/    # negative output on openbsd
            || ! -x $which                      # not executable, may be junk
            ) {

            $which = '';
        }
        if ($which) {
            _debug("Program $program is available in $which");
            return $PROGRAM{$program} = $which;
        }
    }

    # poor man's which
    if (@PATH == 0) {
        @PATH = split /:/, $ENV{PATH};
        push @PATH, split /;/, $ENV{PATH};
        push @PATH, '.';
        push @PATH, '/sbin', '/usr/sbin';
    }
    foreach my $dir (@PATH) {
        if (-x "$dir/$program") {
            _debug("Program $program is available in $dir/$program");
            return $PROGRAM{$program} = "$dir/$program";
        }
    }
    return $PROGRAM{$program} = 0;
}

######################################################################

# some Win32::API specific code

our %WIN32_API_SPECS
    = ('GetActiveProcessorCount' => [ 'kernel32',
                'DWORD GetActiveProcessorCount(WORD g)' ],
       'GetCurrentProcess' => [ 'kernel32',
                'HANDLE GetCurrentProcess()' ],
       'GetCurrentProcessId' => [ 'kernel32',
                'DWORD GetCurrentProcessId()' ],
       'GetCurrentThread' => [ 'kernel32',
                'HANDLE GetCurrentThread()' ],
       'GetCurrentThreadId' => [ 'kernel32',
                'int GetCurrentThreadId()' ],
       'GetLastError' => [ 'kernel32', 'DWORD GetLastError()' ],
       'GetModuleHandle' => [ 'kernel32', 'HMODULE GetModuleHandle(LPCTSTR n)' ],
       'GetPriorityClass' => [ 'kernel32',
                'DWORD GetPriorityClass(HANDLE h)' ],
       'GetProcAddress' => [ 'kernel32',
			   'DWORD GetProcAddress(HINSTANCE a,LPCTSTR b)' ],
#			   'DWORD GetProcAddress(HINSTANCE a,LPCWSTR b)' ],
       'GetProcessAffinityMask' => [ 'kernel32',
                'BOOL GetProcessAffinityMask(HANDLE h,PDWORD a,PDWORD b)' ],
       'GetThreadPriority' => [ 'kernel32',
                'int GetThreadPriority(HANDLE h)' ],
       'IsWow64Process' => [ 'kernel32', 'BOOL IsWow64Process(HANDLE h,PBOOL b)' ],
       'OpenProcess' => [ 'kernel32',
                'HANDLE OpenProcess(DWORD a,BOOL b,DWORD c)' ],
       'OpenThread' => [ 'kernel32',
                'HANDLE OpenThread(DWORD a,BOOL b,DWORD c)' ],
       'SetProcessAffinityMask' => [ 'kernel32',
                'BOOL SetProcessAffinityMask(HANDLE h,DWORD m)' ],
       'SetThreadAffinityMask' => [ 'kernel32',
                'DWORD SetThreadAffinityMask(HANDLE h,DWORD d)' ],
       'SetThreadPriority' => [ 'kernel32',
                'BOOL SetThreadPriority(HANDLE h,int n)' ],
       'TerminateThread' => [ 'kernel32',
                'BOOL TerminateThread(HANDLE h,DWORD x)' ],
    );
our %WIN32_API_SPECS_ 
    = map { $_ => $WIN32_API_SPECS{$_}[1] } keys %WIN32_API_SPECS;

sub _win32api {                 ## no critic (RequireArgUnpacking)
                                ## (we want spooky action-at-a-distance)
    my $function = shift;
    return if !_configModule('Win32::API');
    if (!defined $WIN32API{$function}) {
        __load_win32api_function($function);
    }
    return if !defined($WIN32API{$function}) || $WIN32API{$function} == 0;

    return $WIN32API{$function}->Call(@_);
}

sub __load_win32api_function {
    my $function = shift;
    my $spec = $WIN32_API_SPECS{$function};
    if (!defined $spec) {
        croak "Sys::CpuAffinity: bad Win32::API function request: $function\n";
    }

    local ($!, $^E) = (0, 0);

    my $spec_ = $WIN32_API_SPECS_{$function};
    $WIN32API{$function} = Win32::API->new('kernel32',$spec_);

    if ($!) {
        carp 'Sys::CpuAffinity: ',
            "error initializing Win32::API function $function: $! / $^E\n";
        $WIN32API{$function} = 0;
    }
    return;
}

######################################################################

1; # End of Sys::CpuAffinity

__END__

######################################################################

=head1 NAME

Sys::CpuAffinity - Set CPU affinity for processes

=head1 VERSION

Version 1.12

=head1 SYNOPSIS

    use Sys::CpuAffinity;

    $num_cpus = Sys::CpuAffinity::getNumCpus();

    $mask = 1 | 4 | 8 | 16;   # prefer CPU's # 0, 2, 3, 4
    $success = Sys::CpuAffinity::setAffinity($pid,$mask);
    $success = Sys::CpuAffinity::setAffinity($pid, \@preferred_cpus);

    $mask = Sys::CpuAffinity::getAffinity($pid);
    @cpus = Sys::CpuAffinity::getAffinity($pid);

=head1 DESCRIPTION

The details of getting and setting process CPU affinities
varies greatly from system to system. Even among the different
flavors of Unix there is very little in the way of a common
interface to CPU affinities. The existing tools and libraries
for setting CPU affinities are not very standardized, so
that a technique for setting CPU affinities on one system
may not work on another system with the same architecture.

This module seeks to do one thing and do it well:
manipulate CPU affinities through a common interface
on as many systems as possible, by any means necessary.

The module is composed of several subroutines, each one
implementing a different technique to perform a CPU affinity
operation. A technique might try to import a Perl module,
run an external program that might be installed on your system,
or invoke some C code to access your system libraries.
Usually, a technique is applicable to only a single
or small group of operating systems, and on any particular
system, most of the techniques would fail.
Regardless of your particular system and configuration,
it is hoped that at least one of the techniques will work
and you will be able to get and set the CPU affinities of
your processes.

=head1 DEPENDENCIES

No modules are required by Sys::CpuAffinity, but there are
techniques for manipulating CPU affinities in other
existing modules, and Sys::CpuAffinity will use these
modules if they are available:

    Win32::API, Win32::Process   [MSWin32, cygwin]
    BSD::Process::Affinity       [FreeBSD]

=head1 CONFIGURATION AND ENVIRONMENT

It is important that your C<PATH> variable is set correctly so that
this module can find any external programs on your system that can
help it to manipulate CPU affinities (for example, C<taskset> on Linux,
C<cpuset> on FreeBSD).

If C<$ENV{DEBUG}> is set to a true value, this module will produce
some output that may or may not be good for debugging.

=head1 SUPPORTED SYSTEMS

The techniques for manipulating CPU affinities for Windows
(including Cygwin) and Linux have been refined and tested
pretty well. Some techniques applicable to BSD systems
(particularly FreeBSD) and Solaris have been tested a little bit.
The hope is that this module will include more techniques for
more systems in future releases. See the L</"NOTE TO DEVELOPERS">
below for information about how you can help.

MacOS, OpenBSD are explicitly not supported,
as there does not appear to be any public interface for specifying
the CPU affinity of a process directly on those platforms.

On NetBSD, getting and setting CPU affinity is supported B<only for
the calling process>, and, AFAICT, B<only when run as the super-user>.
Which is to say, you can do this:

    use Sys::CpuAffinity;
    # run this process on CPUs 0, 1, 3
    Sys::CpuAffinity::setAffinity($$, [0, 1, 3]);

but not this:

    use Sys::CpuAffinity;
    $pid = `ps | grep emacs` + 0;
    # run another process on CPUs 0, 1, 3
    Sys::CpuAffinity::setAffinity($pid, [0, 1, 3]);

=head1 SUBROUTINES/METHODS

=over 4

=item C<$bitmask = Sys::CpuAffinity::getAffinity($pid)>

=item C<@preferred_cpus = Sys::CpuAffinity::getAffinity($pid)>

Retrieves the current CPU affinity for the process
with the specified process ID.
In scalar context, returns a bit-mask of the CPUs that the
process has affinity for, with the least significant bit
denoting CPU #0. The return value is actually a
L<Math::BigInt> value, so it can store a bit mask on systems
with an arbitrarily high number of CPUs.

In list context, returns a list of integers indicating the
indices of the CPU that the process has affinity for.

So for example, if a process in an 8 core machine
had affinity for cores # 2, 6, and 7, then
in scalar context, C<getAffinity()> would return

    (1 << 2) | (1 << 6) | (1 << 7) ==> 196

and in list context, it would return

    (2, 6, 7)

A return value of 0 or C<undef> indicates an error
such as an invalid process ID.

=back

=over 4

=item C<$success = Sys::CpuAffinity::setAffinity($pid, $bitmask)>

=item C<$success = Sys::CpuAffinity::setAffinity($pid, \@preferred_cpus)>

Sets the CPU affinity of a process to the specified processors.
First argument is the process ID. The second argument is either
a bitmask of the desired processors to assign to the PID, or an
array reference with the index values of processors to assign to
the PID.

    # two ways to assign to CPU #'s 1 and 4:
    Sys::CpuAffinity::setAffinity($pid, 0x12); # 0x12 = (1<<1) | (1<<4)
    Sys::CpuAffinity::setAffinity($pid, [1,4]);

As a special case, using a C<$bitmask> value of C<-1> will clear
the CPU affinities of a process -- setting the affinity to all
available processors.

On some platforms, notably AIX and Irix, it is only possible to
bind a process to a single CPU. If the processor mask argument to
C<setAffinity> specifies more than one processor (but less than the
total number of processors in your system), then this function might
only bind the process one of the specified processors.

=back

=over 4

=item C<$ncpu = Sys::CpuAffinity::getNumCpus()>

Returns the module's best guess about the number of
processors on this system.

=back

=head1 BUGS AND LIMITATIONS

This module may not work or produce undefined results on
systems with more than 32 CPUs, though support for these
larger systems has improved with v1.07.

Please report any bugs or feature requests to
C<bug-sys-cpuaffinity at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-CpuAffinity>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 INCOMPATIBILITIES

None known, but they are likely to arise as this module makes a
lot of assumptions about how to provide input and interpret output
for many different system utilities on many different platforms.
Please report a bug if you suspect this module of misusing any
system utilities.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sys::CpuAffinity

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-CpuAffinity>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sys-CpuAffinity>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sys-CpuAffinity>

=item * Search CPAN

L<http://search.cpan.org/dist/Sys-CpuAffinity/>

=back

=head1 NOTE TO DEVELOPERS

This module seeks to work for as many systems in as many
configurations as possible. If you know of a tool, a function,
a technique to set CPU affinities on a system -- any system,
-- then let's include it in this module.

Feel free to submit code through this module's request tracker:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-CpuAffinity>

or directly to me at C<< <mob at cpan.org> >> and it will
be included in the next release.

=head1 ACKNOWLEDGEMENTS

L<BSD::Process::Affinity|BSD::Process::Affinity> for demonstrating
how to get/set affinities on BSD systems.

L<Test::Smoke::SysInfo|Test::Smoke::SysInfo> has some fairly portable
code for detecting the number of processors.

L<http://devio.us/> provided a free OpenBSD account that allowed
this module to be tested on that platform.

=head1 AUTHOR

Marty O'Brien, C<< <mob at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2017 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut








######################################################################

Notes and to do list:

Why worry about CPU affinity? See
http://www.ibm.com/developerworks/linux/library/l-affinity.html?ca=dgr-lnxw41Affinity
Other reasons are:
    bind expensive processes to subset of CPUs, leaving at least
    one CPU for other tasks or other users

See http://www.ibm.com/developerworks/aix/library/au-processinfinity.html
for hints about cpu affinity on AIX

From v0.90, test to get num CPUs failed on Irix.

Rumors of cpu affinity on other systems:
    BSD:  pthread_setaffinity_np(), pthread_getaffinity_np()
          copy XS code from BSD::Resource::Affinity
          FreeBSD:  /cpuset, cpuset_setaffinity(), cpuset_getaffinity()
          NetBSD:   /psrset
    Irix: /dplace, cpusetXXX() methods (with -lcpuset)
          pthread_setrunon_np(int), pthread_getrunon_np(int*) to affine 
              the current thread with a single CPU.
          sysmp(MP_MUSTRUN_PID,cpu_id,process_id)
          sysmp(MP_RUNANYWHERE_PID,process_id)
          sysmp(MP_GETMUSTRUN_PID,process_id)
              for binding a process to a single specific processor
    Solaris:  /pbind, /psrset, processor_bind(), pset_bind()

    using /psrset in this module is not recommended
      * processor sets are *exclusive*. processors assigned to a processor set
        can only be used by processes assigned to that set
      * processor sets can only be changed by sysadmin
      * /cpuset in Irix has these same issues (different from /cpuset command
            in FreeBSD)

    Solaris:  Solaris::Lgrp module
        lgrp_affinity_set(P_PID,$pid,$lgrp,LGRP_AFF_xxx)
        lgrp_affinity_get(P_PID,$pid,$lgrp)
        affinity_get

    AIX:  /bindprocessor, bindprocessor() in <sys/processor.h>
        bindprocessor -q     lists virtual processors
        bindprocessor -s 0   lists available cores
        lsdev -Cc processor  lists available cores, consistent with bind... -s 0
 
        bindprocessor -u pid    unbind process pid

    MacOS: thread_policy_set(),thread_policy_get() in <mach/thread_policy.h>

        In MacOS it is possible to assign threads to the same
        processor, but generally not to assign them to any particular
        processor. MacOS is totally unsupported for now.

    DragonflyBSD: all CPAN tests are from single-core systems, so who knows
        whether any of this code works on that platform.

    There also hasn't been a CPAN tester with AIX yet.


how to find the number of processors:
    AIX:  sysconf(_SC_NPROCESSORS_CONF), sysconf(_SC_NPROCESSORS_ONLN)
          prtconf | grep "Number Of Processors:" | cut -d: -f2
    Solaris:   processor_info(), p_online()
    MacOS:     hwprefs cpu_count, system_profiler | grep Cores: | cut -d: -f2
               do something with `sysctl -a`
    AIX:       prtconf
               solaris also has prtconf, but don't think it has cpu data
    BSD also has `sysctl`, they tell me
        AIX:   `smtctl | grep "Bind processor "`  ... not reliable
        AIX:   `lsdev -Cc processor`  -- all processors
        AIX:    `bindprocessor -q`    -- all shares of processors

Some systems have a concept of "processor groups" or "cpu sets"
that can we could either exploit or be exploited by

Some systems have a concept of "strong" affinity and "weak" affinity.
Where the distinction is important, let's use "strong" affinity
by default.

Some systems have a concept of the maximum number of processors that
they can suppport.

Currently (0.91-1.04), constant parameters to Win32 API functions are
hard coded, not extracted from the local header files.

##########################################

Issues in 1.02-1.04

   1. darwin:  hwprefs  and  sysctl  give different results?
     www.cpantesters.org/cpan/report/3982d2fa-9c2a-11e0-a04e-9d9517dc0771
   2. openbsd: dmesg_bsd  and  sysctl  give different results?
     www.cpantesters.org/cpan/report/84d41dda-9942-11e0-a324-58f41aecacb6
     www.cpantesters.org/cpan/report/0c6e981c-a2dd-11e0-a324-58f41aecacb6
   3. linux: /usr/bin/taskset available but still cannot count CPUs? (x16)
       /www.cpantesters.org/cpan/report/92ab9df8-a6fc-11e0-829d-5250641c9bbe
      xs_sched_getaffinity keeps segfaulting (x4)
   4. getNumCpus_from_Win32API_System_Info: garbage result on WOW64 systems

Issues in 1.09
   1. linux might have more than 64 cpus, so xs_sched_getaffinity_get_affinity
      and xs_sched_setaffinity_set_affinity should also work in AV space; see
      Linux::CPUAffinity
   2. fix setaffinity_processor_bind.xs, getaffinity_processor_bind.xs
      for solaris
   3. Not tested on Windows 10
   4. Solaris XS. processor_bind usage matches old processor_bind man page,
      not current page, doesn't look like you can use processor_bind() on
      more than one core.
      Solaris 11.2 has "Multi-CPU Binding" and we may need to distinguish
      between systems that have it and systems that don't.
      blogs.oracle.com/observatory/entry/multi_cpu_binding_mcb:
         ``[MCB] is available through a new API called "processor_affinity(2)"''
