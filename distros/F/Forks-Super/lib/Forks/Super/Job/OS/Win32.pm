#
# Forks::Super::Job::OS::Win32 - operating system manipulation for
#          Windows (and sometimes Cygwin)
#
# It is hard to test all the different possible OS-versions
# (98,2000,XP,Vista,7,...) and different configurations
# (32- vs 64-bit, for one), so expect this module to be
# incomplete, to not always do things in the best way on all
# systems. The highest ambitions for this module are to not
# cause too many general protection faults and to fail gracefully.
#

package Forks::Super::Job::OS::Win32;
use Forks::Super::Config qw(:all);
use Forks::Super::Debug qw(:all);
use Forks::Super::Util qw(IS_WIN32 IS_CYGWIN);
use Carp;
use strict;
use warnings;

if (!&Forks::Super::Util::IS_WIN32ish) {
    Carp::confess "Loaded Win32-only module into \$^O=$^O!\n";
}

# Starting point for details about the Windows Process and
# Thread API:
#   http://msdn.microsoft.com/en-us/library/ms684847(VS.85).aspx


our $VERSION = '0.92';
our ($_THREAD_API, $_THREAD_API_INITIALIZED, %SYSTEM_INFO);

##################################################################

# Accessing the Windows API functions
# ===================================
#
# The  Win32::API  module makes it easy to use functions in a
# DLL if you know the function prototype. 
#
# %_WIN32_API_SPECS lists the Windows API functions that we may
# want to call in this distribution and their function prototypes
# in the Kernel32.dll library.

# some structs we need to enumerate all the threads of a process
# and all processes running on the system
eval {
    require Win32::API;

    my @threadentry32spec = qw(
	DWORD dwSize;
	DWORD cntUsage;
	DWORD thread_id;
	DWORD owner_process_id;
	LONG tpBasePri;
	LONG tpDeltaPri;
	DWORD dwFlags; );

    my @processentry32spec = qw(
        DWORD dwSize;
        DWORD cntUsage;
        DWORD th32ProcessID;
        DWORD th32DefaultHeapID;
        DWORD th32ModuleID;
        DWORD cntThreads;
        DWORD th32ParentProcessID;
        LONG  pcPriClassBase;
        DWORD dwFlags;
        TCHAR szExeFile[260];
    );

    Win32::API::Struct->typedef( THREADENTRY32 => @threadentry32spec );
    Win32::API::Struct->typedef( PROCESSENTRY32 => @processentry32spec );

    if ($Win32::API::VERSION < 0.70) {
	die "Win32::API >=v0.71 is strongly recommended ",
	    "(your version: ",
	    $Win32::API::VERSION, ")";
    }

    1;

} or carp 'Win32::API module is highly recommended ';


our %_WIN32_API_SPECS = (
    # Prototypes for the API function we are interested in
    GetActiveProcessorCount => 'DWORD GetActiveProcessorCount(WORD g)',
    GetCurrentProcess => 'HANDLE GetCurrentProcess()',
    GetCurrentProcessId => 'DWORD GetCurrentProcessId()',
    GetCurrentThread => 'HANDLE GetCurrentThread()',
    GetCurrentThreadId => 'int GetCurrentThreadId()',
    GetExitCodeProcess => 'BOOL GetExitCodeProcess(HANDLE h,LPDWORD x)',
    GetExitCodeThread => 'BOOL GetExitCodeThread(HANDLE h,LPDWORD x)',
    GetLastError => 'DWORD GetLastError()',
    GetPriorityClass => 'DWORD GetPriorityClass(HANDLE h)',
    GetProcessAffinityMask => 
        'BOOL GetProcessAffinityMask(HANDLE h,PDWORD a,PDWORD b)',
    GetThreadPriority => 'int GetThreadPriority(HANDLE h)',
    OpenProcess => 'HANDLE OpenProcess(DWORD a,BOOL b,DWORD c)',
    OpenThread => 'HANDLE OpenThread(DWORD a,BOOL b,DWORD c)',
    ResumeThread => 'DWORD ResumeThread(HANDLE h)',
    SetPriorityClass => 'BOOL SetPriorityClass(HANDLE h,DWORD c)',
    SetProcessAffinityMask => 'BOOL SetProcessAffinityMask(HANDLE h,DWORD m)',
    SetThreadAffinityMask => 'DWORD SetThreadAffinityMask(HANDLE h,DWORD d)',
    SetThreadPriority => 'BOOL SetThreadPriority(HANDLE h,int n)',
    SuspendThread => 'DWORD SuspendThread(HANDLE h)',
    TerminateProcess => 'BOOL TerminateProcess(HANDLE h,UINT x)',
    TerminateThread => 'BOOL TerminateThread(HANDLE h,DWORD x)',

    CreateSnapshot => 'HANDLE CreateToolhelp32Snapshot(DWORD a,DWORD b)',
    Process32First => 'BOOL Process32First(HANDLE h,LPPROCESSENTRY32 b)',
    Process32Next => 'BOOL Process32Next(HANDLE h,LPPROCESSENTRY32 b)',
    Thread32First => 'BOOL Thread32First(HANDLE h,LPTHREADENTRY32 b)',
    Thread32Next => 'BOOL Thread32Next(HANDLE h,LPTHREADENTRY32 b)',
);

# make a system call to a kernel32.dll function
sub win32api {
    my $function = shift;
    if (!defined $_THREAD_API->{$function}) {
	return if !CONFIG('Win32::API');
	my $spec = $_WIN32_API_SPECS{$function};
	if (!defined $spec) {
	    croak 'Forks::Super::Job::OS::Win32: ',
	        "requested unrecognized Win32 API function $function!\n";
	}

	local $! = undef;
	$_THREAD_API->{$function} = Win32::API->new('Kernel32', $spec);
	if ($!) {
	    $_THREAD_API->{'_error'} = "$! / $^E";
	}
    }
    return $_THREAD_API->{$function}->Call(@_);
}

sub _load_win32api {
    my $function = shift;
    return if !CONFIG('Win32::API');
    my $spec = $_WIN32_API_SPECS{$function};
    if (!defined $spec) {
	croak 'Forks::Super::Job::OS::Win32: ',
	    "requested unrecognized Win32 API function $function!\n";
    }

    local $! = undef;
    $_THREAD_API->{$function} = Win32::API->new('Kernel32', $spec);
    if ($!) {
	$_THREAD_API->{'_error'} = "$! / $^E";
    }
    return $_THREAD_API->{$function};
}

##################################################################

sub get_thread_handle {
    my $thread_id = shift;
    my $set_info = shift || '';

    if (!defined $thread_id) {
	$thread_id = win32api('GetCurrentThreadId');
    }
    $thread_id = abs($thread_id);

    # Thread access rights:
    # from http://msdn.microsoft.com/en-us/library/ms686769(VS.85).aspx
    #
    # did these values change since 2010?
    # === current as of 2011m07 ===
    # 0x0040: THREAD_QUERY_INFORMATION
    # 0x0800: THREAD_QUERY_LIMITED_INFORMATION (v>=2003)
    # 0x0020: THREAD_SET_INFORMATION
    # 0x0400: THREAD_SET_LIMITED_INFORMATION (v>=2003)
    # === was in 2010m08? ===
    # 0x0020: THREAD_QUERY_INFORMATION
    # 0x0400: THREAD_QUERY_LIMITED_INFORMATION
    # 0x0040: THREAD_SET_INFORMATION
    # 0x0200: THREAD_SET_LIMITED_INFORMATION

    if ($set_info =~ /term/i) { # need terminate privilege
	# 0x0001: THREAD_TERMINATE
	return 0
	    || win32api('OpenThread', 0x0001, 0, $thread_id);
    }
    if ($set_info =~ /susp/i) { # need suspend-resume privilege
	# 0x0002: THREAD_SUSPEND_RESUME
	return 0
	    || win32api('OpenThread', 0x0002, 0, $thread_id);
    }

    foreach my $perm (0x0060, 0x0C00, 0x0600, 0x0040, 0x0020) {
      local $! = 0;
      my $handle = win32api('OpenThread', $perm, 1, $thread_id);
      if ($DEBUG) {
	debug("OpenThread($perm,1) => $handle $! $^E");
      }
      return $handle if $handle;
    }

    # nothing yet
    if ($DEBUG) {
      debug("Couldn't get a handle to thread id $thread_id.");
      debug("Here are all the thread ids that this process knows about.");
      my @known_threads = _enumerate_threads_for_process( $$ );
      debug("[ @known_threads ]");
    }


    return 0;

    return 0
	# 0x0060: THREAD_SET_INFORMATION | THREAD_QUERY_INFORMATION
	|| win32api('OpenThread', 0x0060, 1, $thread_id)

	# 0x0C00: THREAD_QUERY_LIMITED_INFORMATION
	#         | THREAD_SET_LIMITED_INFORMATION
	|| win32api('OpenThread', 0x0C00, 1, $thread_id)

	# 0x0040: THREAD_SET_INFORMATION
	# 0x0020: THREAD_QUERY_INFORMATION
	|| win32api('OpenThread', $set_info ? 0x0040 : 0x0020, 1, $thread_id)

	# 0x0200: THREAD_SET_LIMITED_INFORMATION
	# 0x0400: THREAD_QUERY_LIMITED_INFORMATION
	|| win32api('OpenThread', $set_info ? 0x0200 : 0x0400, 1, $thread_id);
}

sub get_process_handle {
    my $process_id = shift;
    my $set_info = shift || 0;

    if (!defined $process_id) {
	# on Cygwin,  GetCurrentProcessId() != $$
	$process_id = win32api('GetCurrentProcessId');
    }

    # Process access rights:
    # from http://msdn.microsoft.com/en-us/library/ms684880(VS.85).aspx
    # If there is a reason the these values are inconsistent with the
    # THREAD_xxx_INFORMATION values, nobody knows what it is.
    #
    # 0x0400: PROCESS_QUERY_INFORMATION
    # 0x1000: PROCESS_QUERY_LIMITED_INFORMATION
    # 0x0200: PROCESS_SET_INFORMATION
    return win32api('OpenProcess', 0x0600, 0, $process_id)
	|| win32api('OpenProcess', 0x1200, 0, $process_id)
	|| win32api('OpenProcess', $set_info ? 0x0200 : 0x0400, 0, $process_id)
	|| ($set_info == 0 && win32api('OpenProcess', 0x1000, 0, $process_id));
}

sub get_current_thread_id {
    # XXX - if $$<0, then this result should always be the same as -$$, right?
    local $! = 0;
    my $result = win32api('GetCurrentThreadId');
    return $result;
}

#############################################################################

# DWIM Unix-style emulation of signals to Windows processes and threads
# =====================================================================
#
# "Signals" (note scare quotes) are quite idiosyncratic in Windows.
# Perl's  kill  function and  %SIG  signal handler magic work very
# differently on processes ($$>0) and threads ($$<0). Sending a
# signal to a thread can sometimes terminate the whole process, so
# we have to be careful what we do.
#
# Here's a summary of best case emulation:
# ----------------------------------------
#
# ZERO        always(*) ok to use CORE::kill
#             cannot be handled
#             (* - actually kill 'ZERO', ... fails because it signals a
#             zombie process)
#
# KILL        always ok to use CORE::kill
#             terminates thread or process
#             cannot be handled
#
# INT,QUIT,BREAK to a process
#             always ok to use CORE::kill
#             default behavior is to terminate process
#             but %SIG handlers are respected
#
# STOP,CONT   never ok to use CORE::kill
#             CORE::kill would terminate the process
#             even CORE::kill to a thread would terminate the whole process
#             use Windows API to suspend/resume the process or thread
#
# CHLD,CLD    not ok to use CORE::kill
#             CORE::kill would terminate process, even if called on a thread
#             IGNORE this signal, or send SIGZERO
#
# *kill to a process   
#             mostly ok to use CORE::kill
#             cannot be handled
#             terminates the process
#
# INT,QUIT,BREAK to a thread
# *kill to a thread
#             CORE::kill will respect a %SIG handler
#             CORE::kill ok *IF* any signal handler is defined in the thread
#             without a %SIG handler, the whole process will be terminated
#             *IF* you are not *SURE* that a signal handler is installed,
#                 use the API to terminate the thread
#
# Other signals to a process
# There aren't any other known signals on Windows, but in case an unrecognized
#     one shows up ...
#	      CORE::kill will terminate the process (I guess)
#             Signal handlers are ignored
#             Don't know what DWIM behavior is for arbitrary signal,
#                 terminate (with API) or ignore would be reasonable defaults
#
# Other signals to a thread
#             CORE::kill will respect a %SIG handler
#             CORE::kill will terminate the whole process w/o a %SIG handler
#             Don't use CORE::kill unless you're *SURE* a signal handler exists
#             Don't know what DWIM behavior is for arbitrary signal,
#                  terminate (with API) or ignore are reasonable defaults
#
# Non-Windows signals:
#             cannot be handled,
#             cannot be used directly with CORE::kill
#             translate them into "similar" Windows signals
#             FREEZE,TSTP,TTIN,TTOU ==> treat like SIGSTOP, use API to suspend
#             THAW ==> treat like SIGCONT, use API to resume
#             JVM1,JVM2,LWP,URG,WINCH      ==> ignore or treat like SIGZERO
#                 send SIGZERO with CORE::kill ok
#
# * Windows "kill" signals are ABRT ALRM FPE HUP ILL NUMxx PIPE SEGV TERM


# DWIM Unix-style signal to Windows processes and threads
sub signal_procs {
    my ($signal, $kill_proc_group, @pids) = @_;
    # XXX - $kill_proc_group directive is inconsistently applied.
    #       See sigkill_process

    if ($DEBUG) {
	debug('FSJ::OS::Win32: ',
	      "Sending signal $signal to pids: ", join(' ',@pids));
    }

    # signals that should have no effect on Windows processes and threads
    if ($signal eq 'CHLD' || $signal eq 'CLD' || $signal eq 'JVM1'
	    || $signal eq 'JVM2' || $signal eq 'LWP' || $signal eq 'URG'
	    || $signal eq 'WINCH') {
	$signal = 'ZERO';
    }

    my @signalled = ();
    my @terminated = ();
    my $tasklist = '';
    foreach my $pid (sort {$a <=> $b} @pids) {
	my $termref = signal_process($signal, $pid, $kill_proc_group);
	if ($termref) {
	    push @signalled, $pid;
	    push @terminated, @$termref;
	}
    }
    return (\@signalled, \@terminated);
}

sub signal_process {
    my ($signal, $pid, $kill_proc_group) = @_;
    if ($pid < 0) {
	return signal_thread($signal, -$pid);
    } elsif ($signal eq 'ZERO' || $signal eq '0') {
	return [] if sigzero_process($pid);
    } elsif (Forks::Super::Util::is_continue_signal($signal)) {
	return [] if resume_process($pid);
    } elsif (Forks::Super::Util::is_stop_signal($signal)) {
	return [] if suspend_process($pid);
    } elsif (Forks::Super::Util::is_kill_signal($signal)) {
	return [$pid] if sigkill_process($signal, $pid, $kill_proc_group);
    } else {
	carp_once 'Forks::Super::Win32::signal_process: '
	    . "signal $signal not recognized, treating as SIGKILL";
	if (CORE::kill($kill_proc_group ? -9 : 'KILL', $pid)) {
	    return [$pid];
	}
    }
    return;
}

# DWIM Unix-style signal to a Win32 thread
sub signal_thread {
    my ($signal, $thread_id) = @_;
    local $! = 0;

    if (Forks::Super::Util::is_kill_signal($signal)) {
	if (terminate_thread($thread_id)) {
	    return [ -$thread_id ];
	}
    } elsif (Forks::Super::Util::is_stop_signal($signal)) {
	if (suspend_thread($thread_id)) {
	    return [];
	}
    } elsif (Forks::Super::Util::is_continue_signal($signal)) {
	if (resume_thread($thread_id)) {
	    return [];
	}
    } elsif ($signal eq 'ZERO' || $signal eq '0') {
	if (sigzero_thread($thread_id)) {
	    return [];
	}
    } else {
	# XXX - should we ignore an unrecognized signal or terminate the
	#       thread on an unrecognized signal? for now let's ignore

	# Usually don't want to use CORE::kill to signal a thread
	# because if the signal isn't handled (with a %SIG handler),
	# then the entire process will be killed.

	carp_once [$signal], 'Forks::Super::kill(): ',
	      "Called on MSWin32 with SIG$signal\n",
	      "Ignored because this module can't find a suitable way to\n",
	      "express that signal on MSWin32.\n";
    }
    return;
}

sub terminate_process {
    my ($pid,$exitCode) = @_;
    # 0x0001: PROCESS_TERMINATE
    my $procHandle = win32api('OpenProcess', 0x0001, 1, $pid);
    if ($procHandle) {
	my $z = win32api('TerminateProcess',$procHandle,$exitCode || 0);
	if (!$z) {
	    carp "Forks::Super::Win32: terminate_process: \$^E=",
                    0+$^E," $^E\n";
	} else {
	    return $z;
	}
    }
    if (!CONFIG('Win32::API')) {
	return !system "TASKKILL /F /PID $pid > nul 2>&1";
    }
    return 0;
}

sub terminate_process_tree {
    my ($pid, $exitCode) = @_;

    # v0.70: use system "TASKKILL" command only if we can't terminate
    # the processes through WMI or through the Win32 API.

    my $children = _find_child_processes($pid);
    if ($children && ref $children) {
	terminate_process($_, $exitCode) for @$children;
	return terminate_process($pid, $exitCode);
    }
    return _terminate_process_tree_with_taskkill( $pid );
}

sub _find_child_processes {
    my ($pid) = @_;
    my %child_map = _process_tree_map();
    if (!%child_map) {
	return;
    }
    my @c = @{$child_map{$pid} || []};
    for (my $i=0; $i<@c; $i++) {
	push @c, @{$child_map{$c[$i]} || []};
    }
    return [ @c ];
}

sub _process_tree_map {
    # create a map of processes to all their direct child processes
    # try to do this with WMI or with the Win32 API
    my %child_map;
    if (CONFIG('DBD::WMI')) {
	my $dbh = DBI->connect('dbi:WMI:');
	my $sth = $dbh->prepare("SELECT * FROM Win32_Process");
	$sth->execute;
	while (my $proc = $sth->fetchrow) {
	    my $pid = $proc->{ProcessId};
	    my $ppid = $proc->{ParentProcessId};
	    if ($pid && $ppid) {
		push @{$child_map{$ppid}}, $pid;
	    }
	}
	$dbh->disconnect;
    } elsif (CONFIG('Win32::API')) {
	# TH32CS_PROCESS: 0x00000002
	my $snapshot = win32api('CreateSnapshot', 0x00000002, 0);
	if (!$snapshot) {
	    carp "No process snapshot available (",
		    win32api('GetLastError'), ")\n$^E\n";
	    return;
	}

	my $process_entry = Win32::API::Struct->new('PROCESSENTRY32');
	$process_entry->{dwSize} = 304;
	$process_entry->{$_} = '0000'
	    for qw(cntUsage th32ProcessID th32DefaultHeapID th32ModuleID 
		   cntThreads th32ParentProcessID dwFlags th32MemoryBase 
		   th32AccessKey pcPriClassBase);
	$process_entry->{szExeFile} = "\0";
	$process_entry->{th32ParentProcessID} = 0;

	my $z = win32api('Process32First', $snapshot, $process_entry);
	if (!$z) {
	    carp $^E;
	    return;
	}
	while ($z) {
	    my $pid = $process_entry->{th32ProcessID};
	    my $ppid = $process_entry->{th32ParentProcessID};
	    if ($pid && $ppid) {
		push @{$child_map{$ppid}}, $pid;
	    }
	    $z = win32api('Process32Next', $snapshot, $process_entry);
	}
    }
    return %child_map;
}

sub _terminate_process_tree_with_taskkill {
    my $pid = shift;
    my $c1 = system "TASKKILL /T /F /PID $pid >nul 2>&1";
    return !$c1;
}

sub _enumerate_threads_for_process {
    my $process_id = shift;

    if (!defined $process_id) {
	Carp::cluck '_enumerate_threads_for_process ',
	    "called with no process id!\n";
	return;
    }

    # 0x00000004: TH32CS_SNAPTHREAD
    # 0x00000008: TH32CS_SNAPMODULE
    my $snapshot = win32api('CreateSnapshot', 0x00000004, $process_id);
    if (!$snapshot) {
	carp "\n\nNo thread snapshot available for pid $process_id $$.\n\n"
	  . win32api('GetLastError') . "\n\n$^E\n\n=======\n";
	return;
    }
    my $thread_entry = Win32::API::Struct->new('THREADENTRY32');
    $thread_entry->{dwSize} = 28;
    $thread_entry->{$_} = '0000'
      for qw(cntUsage thread_id owner_process_id tpBasePri tpDeltaPri dwFlags);

    my $z = win32api('Thread32First', $snapshot, $thread_entry);
    if (!$z) {

	if (1) {
	    # try again, although the process may be dead or invalid
	    $snapshot = win32api('CreateSnapshot', 0x0000000C, $process_id);
	    return if !$snapshot;
	    $z = win32api('Thread32First',$snapshot,$thread_entry);
	    return if !$z;
	} else {
	    carp $^E;
	    return;
	}
    }

    my @threads_for_process = ();
    while ($z) {
	if ($thread_entry->{owner_process_id} == $process_id) {
	    push @threads_for_process, $thread_entry->{thread_id};
	}
	$z = win32api('Thread32Next', $snapshot, $thread_entry);
    }
    return @threads_for_process;
}

sub suspend_process {
    my $pid = shift;
    if ($pid == $$) {
	# suspend the current thread ...
	croak 'implement me: suspend the current thread';
    }
    # there is no SuspendProcess function in the API, so instead we have to
    # enumerate all the threads in the process
    # and call suspend thread on each one.

    # SuspendThread is not particularly safe (you could suspend a thread
    # while it is allocating memory, or has a lock on some mutex, and
    # hang your program). That's the way it goes sometimes.

    my @thread_ids = _enumerate_threads_for_process($pid);
    return if @thread_ids == 0;

    foreach my $thread_id (@thread_ids) {
	debug("suspending thread $thread_id in process $pid...") if $DEBUG;
	suspend_thread($thread_id);
    }
    suspend_thread($pid);
    return 1;
}

sub resume_process {
    my $pid = shift;
    # now do the opposite of suspend_process: enumerate all
    # the threads of a process and call ResumeThread on them
    my @thread_ids = _enumerate_threads_for_process($pid);
    return if @thread_ids == 0;

    foreach my $thread_id (@thread_ids) {
	debug("resuming thread $thread_id in process $pid ...") if $DEBUG;
	resume_thread($thread_id);
    }
    resume_thread($pid);
    return 1;
}

sub terminate_thread {
    my ($thread_id) = @_;
    my $handle = get_thread_handle($thread_id, 'terminate');
    return 0 if !$handle;
    local $! = 0;
    my $result = win32api('TerminateThread', $handle, 0);
    if ($!) {
	carp "Forks::Super::Job::OS::Win32::terminate_thread(): $! / $^E";
    }
    return $result;
}

sub suspend_thread {
    my ($thread_id) = @_;
    my $handle = get_thread_handle($thread_id, 'suspend');
    if (!$handle) {
	return 0;
    }

    local $! = 0;
    my $result = win32api('SuspendThread', $handle);
    if ($!) {
	carp "Forks::Super::Job::OS::Win32::suspend_thread(): $! / $^E";
    }
    if (&IS_CYGWIN) {
	$result = win32api('SuspendThread', $handle);
    }
    return $result > -1;
}

sub resume_thread {
    my ($thread_id) = @_;
    my $handle = get_thread_handle($thread_id, 'suspend');
    return 0 if !$handle;

    local $! = 0;
    # Win32 threads maintain a "suspend count". If you call
    # SuspendThread on a thread five times, you have to call
    # ResumeThread five times to reactivate it.
    my $result;
    do {
	$result = win32api('ResumeThread', $handle);
    } while ($result > 1);
    if ($!) {
	carp "Forks::Super::Job::OS::Win32::resume_thread(): $! / $^E";
    }
    return $result > -1;
}

sub sigzero_process {
    # CORE::kill 'ZERO' is safe for processes and threads
    # **BUT** kill 'ZERO' will return 1 for a zombie process
    # (or rather, a process launched with "system 1,..." that
    # is not sufficiently detached from the process that 
    # launched it), which is usually not what we want.

    # Getting a handle to a process and checking that the result
    # of  GetExitCodeProcess  != 259 (STILL_ACTIVE) is just a
    # little bit slower but it is exactly what we usually want.

    my $pid = shift;
    my $handle = get_process_handle($pid, 0);
    if ($handle != 0) {

	my $xcode = pack('I',1);

	# "numeric" input suppresses warnings in perl 5.8, Win32::API 0.58
	$xcode = "0   ";

	my $z = win32api('GetExitCodeProcess',$handle,$xcode);

	if ($z && (unpack('I',$xcode))[0]==259) {
	    return $pid;
	}
    }
    return;
}

sub sigzero_thread {
    my ($thread_id) = @_;
    my $handle = get_thread_handle($thread_id);
    if ($DEBUG) {
      debug("SIGZERO sent to thread $thread_id. Handle is $handle.");
    }
    return 0 if !$handle;

    my $xcode = pack('I', 0);
    $xcode = "0   ";

    my $result = win32api('GetExitCodeThread',$handle,$xcode);
    $xcode = unpack('I', $xcode);

    # 259: STILL_ACTIVE
    return $result != 0 && $xcode == 259;
}

sub sigkill_process {
    my ($signal, $pid, $kill_proc_group) = @_;
    my $signo =  Forks::Super::Util::signal_number($signal);
    my $result;

    if (0 && $kill_proc_group) {
	my $children = _find_child_processes($pid);
	if ($children && ref $children) {
	    $result = [ 
		map { 
		    my $x = sigkill_process($signal, $_, 0);
		    $x ? @$x : ()
		} @$children, $pid
		];
	    return $result;
	}
    }

    if ($signal eq 'INT' || $signal eq 'QUIT' || $signal eq 'BREAK') {

	# sending SIGINT, SIGQUIT, or SIGBREAK to a process is
	# emulated differently on Windows than for most other signals.
	# By default they will terminate a process, but they can
	# be handled by a %SIG entry more or less like in Unix.

	debug("CORE::kill $signal => $pid") if $Forks::Super::DEBUG;
	if (CORE::kill $signal, $pid) {
	    $result = [$pid];
	} else {
	    debug("CORE::kill $signal,$pid  not successful")
		if $Forks::Super::DEBUG;
	    if (sigkill_process_harder($signo, $pid)) {
		$result = [$pid];
	    }
	}
    } else {
	if (terminate_process($pid, $signo)) {
	    $result = [$pid];
	    debug("terminate_process($pid,$signal) successful") if $DEBUG;
	} else {
	    debug("terminate_process($pid,$signal) not successful") if $DEBUG;
	}
    }
    Forks::Super::Sigchld::handle_CHLD(-1);
    return $result;
}

sub sigkill_process_harder {
    my ($signo, $pid) = @_;
    my $result;

    # this didn't work ... does the process exist?
    my $handle = get_process_handle($pid, 0);
    if ($handle != 0) {
	my $xcode = pack('I',0);
	my $z = win32api('GetExitCodeProcess',$handle,$xcode);
	if ($z && unpack('I',$xcode)==259) {
	    # yep, the process exists

	    # Maybe this is a detached process (like from 
	    # Forks::Super::Job::_postlaunch_daemon_Win32).
	    # CORE::kill  doesn't seem to work so well with
	    # those processes. Let's try something else:

	    # In any case, this next section is a refactor candidate

	    if (Forks::Super::Config::CONFIG('Win32::Process')) {
		my ($obj, $flags);
		my $oresult = Win32::Process::Open($obj, $pid, $flags);
		if ($oresult) {
		    $oresult = $obj->Kill($signo);
		    if ($oresult) {
			$result = [$pid];
		    }
		}
	    } else {
		# let's try the same thing using the handle
		# XXX - not tested

		$handle = get_process_handle($pid, 1) || $handle;
		$z = win32api('TerminateProcess',$handle,15);
		if ($z) {
		    $result = [$pid];
		}
	    }
	}
    }
    return $result;
}

######################################################################

# Process and thread priority
# http://msdn.microsoft.com/en-us/library/ms685100(v=VS.85).aspx
#
# Windows recognizes 6 different "process priorities" and 7 different
# "thread priorities". The relative priority of any program thread is
# the sum of its process priority and its thread priority.
#
# Process priorities        Base, possible priorities
# ------------------     -------------------------------------------
#         IDLE                4    1,2,3, 4 ,5,6,15
#     BELOW_NORMAL            6    1,4,5, 6 ,7,8,15
#        NORMAL               8    1,6,7, 8 ,9,10,15
#     ABOVE_NORMAL           10    1,8,9, 10 ,11,12,15
#         HIGH               13    1,11,12, 13 ,14,15,15
#       REALTIME             24    16,22,23, 24 ,25,26,31
#
# When a new job begins with the $job->{os_priority} set, 
# we will try to set the process and thread priorities for the
# new job to align with the caller's desired priority.
#
# With a natural fork or fork to sub, we can only manipulate the
# thread priority. We can do this from  Forks::Super::Job::_config_os_child.
#
# With a cmd or exec fork we can manipulate both the process and
# thread priorities. We should set this immediately after the
# command has been launched.
#
# If possible, set only the thread priority.

sub get_thread_priority {
    my $thread_id = shift;
    if (!defined $thread_id) {
	$thread_id = win32api('GetCurrentThreadId');
    }
    my $handle = get_thread_handle($thread_id);
    local $! = undef;
    my $p = win32api('GetThreadPriority', $handle);
    if ($!) {
	carp "Problem retrieving priority for Windows thread $thread_id: ",
	"$! / $^E\n";
    }
    return $p;
}

sub get_priority {
    my ($pid) = @_;
    if (!defined $pid) {
	$pid = $$;
    }
    my $process_priority = 0;
    my $thread_priority = 0;
    if ($pid < 0) {
	$thread_priority = get_thread_priority(-$pid);
	$process_priority = get_process_base_priority(undef);
    } else {
	$process_priority = get_process_base_priority($pid);
	my @t = _enumerate_threads_for_process($pid);
	if (@t > 0) {
	    $thread_priority = get_thread_priority($t[0]);
	}
    }
    if ($thread_priority == -15) {
	return $process_priority == 24 ? 16 : 1;
    } elsif ($thread_priority == +15) {
	return $process_priority == 24 ? 31 : 15;
    }
    return $process_priority + $thread_priority;
}

sub set_thread_priority {
    # thread priority is one of: -15,-2..2,15
    # if the process priority class is REALTIME_PRIORITY_CLASS (0x100),
    # then acceptable values are -15,-7..6, 15

    my ($thread_id, $priority) = @_;
    if (!defined $thread_id) {
	$thread_id = win32api('GetCurrentThreadId');
    }
    my $handle = get_thread_handle($thread_id);
    return 0 if !$handle;
    return win32api('SetThreadPriority', $handle, $priority);
}

sub set_os_priority_process {
    # in this method we have the option of setting both
    # process and thread priority
    my ($process_id, $priority) = @_;
    my $handle = get_process_handle($process_id, 1);
    if (!$handle) {
	carp_once 'Forks::Super::Win32::set_os_priority_process: ',
	    "no handle for PID $process_id";
	return;
    }
    if ($priority < 1) {
	carp 'Forks::Super::Win32: ',
	    "changing os priority setting from $priority to 1 ",
	    '(valid range is 1-31)';
	$priority = 1;
    }
    if ($priority > 31) {
	carp 'Forks::Super::Win32: ',
	    "changing os priority setting from $priority to 31 ",
	    '(valid range is 1-31)';
	$priority = 31;
    }

    # Windows process priority classes:
    #     http://msdn.microsoft.com/en-us/library/ms686219(v=VS.85).aspx
    our ($IDLE,$BELOW,$NORMAL,$ABOVE,$HIGH,$REAL)
	= (0x40,0x4000,0x20,0x8000,0x80,0x200);

    # best way to map each desired prio from 1 to 31 to a priority class/
    # thread priority pair
    my $priorities =
	(undef,
	 [$NORMAL,-15],[$IDLE,-2],
	 [$IDLE,-1],[$IDLE,0],
	 [$BELOW,-1],[$BELOW,0],
	 [$NORMAL,-1],[$NORMAL,0],[$NORMAL,1],
	 [$ABOVE,0], [$ABOVE,1],
	 [$HIGH,-1], [$HIGH,0], [$HIGH,1], [$HIGH,2],[$REAL,-15],
	 [$REAL,-7],[$REAL,-6],[$REAL,-5],[$REAL,-4],
	 [$REAL,-3],[$REAL,-2],[$REAL,-1],[$REAL,0],
	 [$REAL,1],[$REAL,2],[$REAL,3],[$REAL,4],
	 [$REAL,5],[$REAL,6],[$REAL,15],)[$priority] || [$NORMAL,0];

    local $! = 0;
    my $result = win32api('SetPriorityClass', $handle, $priorities->[0]);
    if ($result) {
	my @threads = _enumerate_threads_for_process($process_id);
	foreach my $thr (@threads) {
	    $result *= set_thread_priority($thr, $priorities->[1]);
	}
    }
    if ($result) {
	return $result + $priority / 100;
    } else {
	carp "Forks::Super::Job: set process priority failed: $! / $^E\n";
    }
    return;
}

sub set_os_priority {
    my ($job, $desired_priority) = @_;
    if ($job->{style} eq 'cmd' || $job->{style} eq 'exec') {
	# set os priority later ...
	return;
    }
    my $thread_id = get_current_thread_id();
    my $handle = get_thread_handle($thread_id);
    if (!$handle) {
	carp_once 'Forks::Super::Job::OS::set_os_priority: ',
	    "no Win32 handle available for thread\n";
	return;
    }

    # we don't want to muck with the process priority from here ...
    # we will just set the thread priority
    my $base_priority = get_process_base_priority();
    if ($desired_priority < 1) {
	$desired_priority = 1;
    } elsif ($desired_priority > 31) {
	$desired_priority = 31;
    }
    my @fifteens = (15) x 31;
    my $thread_priority = 
	([],[],[],[],
	 [0,-15,-2,-1,0,1,2,2,2,2,@fifteens], [],
	 [0,-15,-15,-2,-2,-1,0,1,2,2,2,@fifteens], [],
	 [0,-15,-15,-15,-2,-2,-2,-1,0,1,2,2,2,@fifteens], [],
	 [0,-15,-15,-15,-15,-2,-2,-2,-2,-1,0,1,2,2,@fifteens], [], [],
	 [0,-15,-15,-15,-15,-15,-2,-2,-2,-2,-2,-2,-1,0,1,2,2,@fifteens],
	 [],[],[],[],[],[],[],[],[],[],
	 [0,(-15)x16,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,15]
	)[$base_priority]->[$desired_priority];

    local $! = 0;
    my $result =
	Forks::Super::Job::OS::Win32::set_thread_priority(
	    $thread_id,$thread_priority);
    if ($result) {
	if ($job->{debug}) {
	    debug("updated thread priority to $thread_priority for job $$");
	}
	return $result + $thread_priority / 100;
    } else {
	carp "Forks::Super::Job: set os_priority failed: $! / $^E\n";
    }
    return;
}

sub get_process_priority_class { # for the current process
    my $pid = shift;
    my $phandle = get_process_handle($pid, 0);
    if (!$phandle) {
        carp "FSJ::OS::Win32::get_process_priority_class: ",
             "no handle for pid $pid";
        return;
    }
    local $! = 0;
    my $result = win32api('GetPriorityClass', $phandle);
    if ($!) {
	carp_once 'Forks::Super::Job::OS: ',
	    "Error retrieving current process priority class $! / $^E\n";
    }
    return $result;
}

sub get_process_base_priority {
    my $pid = shift;
    my $class = get_process_priority_class($pid) || -1;
    if ($class == 0x0100) { #      0x0100: realtime
	return 24;
    } elsif ($class == 0x20) { #   0x0020: normal
	return 8;
    } elsif ($class == 0x40) { #   0x0040: idle
	return 4;
    } elsif ($class == 0x80) { #   0x0080: high
	return 13;
    } elsif ($class == 0x4000) { # 0x4000: below normal
	return 6;
    } elsif ($class == 0x8000) { # 0x8000: above normal
	return 10;
    } else {
	carp 'Forks::Super::Win32::get_process_base_priority: ',
		"unknown priority class $class";
	return 8;
    }
}

###############################################################
#
# To spawn a new process in MSWin32, TMTOWTDI. Depending
# on what  Win32::XXX  modules are available, some ways
# suck less than the other ways.
#
# 1. Use  $pid=open $fh,"|$cmd", attach $pid to a
#    Win32 handle with Win32::Process::Open.
#    Wait on the process.
#
# 2. Like #1, but use  open $fh,"$cmd|"  construction
#
# 3. Use Win32::Process::Create, wait on the process. 
#
# 4. Just call  system() , which waits on the process
#    for you.
#
# 5. Just call  open $fh,"|$cmd" and wait.
#
# #1,#2,#3 require Win32::Process module.
#
# #3 doesn't hand off redirected filehandles properly,
# so that shouldn't be used when there is IPC.
#
# #4,#5 doesn't give you access to a Win32 handle, so you
# can't set OS priority, CPU affinity, suspend/resume,
# etc.
#
# 6.  system 1, @cmd
#
# Problem solved.
#
# And don't get me started on all the ways to kill a
# Win32 process.

sub system1_win32_process {
    my ($job, @cmd) = @_;
    $Forks::Super::Job::WIN32_PROC = '__system1__';
    $ENV{'__FORKS_SUPER_PARENT_THREAD'} = $$;
    $Forks::Super::Job::WIN32_PROC_PID = system 1, @cmd;
    if ($? == 255 << 8) {
	# system 1, ...  failed. XXX - what should we do?
	croak "system 1,{@cmd}  call failed: $! $^E";
    }
    $job->{pgid} = $Forks::Super::Job::WIN32_PROC_PID;
    $job->set_signal_pid($Forks::Super::Job::WIN32_PROC_PID);
    if (defined($job->{cpu_affinity}) && CONFIG('Sys::CpuAffinity')) {
	Sys::CpuAffinity::setAffinity(
	    $Forks::Super::Job::WIN32_PROC_PID, $job->{cpu_affinity});
    }
    if (defined($job->{os_priority})) {
	set_os_priority_process(
	    $Forks::Super::Job::WIN32_PROC_PID, $job->{os_priority})
    }

    # XXX - The process might get handled in the SIGCHLD handler
    # and CORE::waitpid might return 0/-1, right? - XXX
    my $z = CORE::waitpid $Forks::Super::Job::WIN32_PROC_PID, 0;
    my $c1 = $?;
    $Forks::Super::Job::WIN32_PROC = undef;
    return $c1;
}

1;
