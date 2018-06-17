################################################################
# system-limits.PL
#
# probe the limitations of this system including the maximum
# number of simultaneous child processes and the maximum number
# of open filehandles.
#
# this information is used to create the  Forks/Super/SysInfo.pm  
# file which will inform certain settings in your Forks::Super 
# installation.
#
################################################################

use lib q(lib);
use strict;
use warnings;
use Config;
use POSIX;

our $VERSION = '0.94';

my $limits_file = $ARGV[0] || "t/out/limits.$^O.$]";
my $limits2 = $ARGV[1] || "t/out/limits.$^O";
my %LIMITS;
if (-f $limits2) {
    open my $fh, '<', $limits2;
    # sys| values are independent of your perl installation
    while (<$fh>) {
        s/\s+$//;
        my ($key,$val) = split /:/, $_, 2;
        $LIMITS{'sys|' . $key} = $val;
    }
    close $fh;
    unless ($LIMITS{'sys|valid'}) {
        %LIMITS = ();
    }
}
$LIMITS{file} = $limits_file;
$LIMITS{sysfile} = $limits2;
our $MAIN_PID = $$;

my $pid = 0;
if ($^O eq 'MSWin32') {
    if ("@ARGV" !~ / --bg /) {
        $pid = system 1, "$^X $0 @ARGV --bg";
    }
} elsif ($INC{'perl5db.pl'}) {
    $pid = 0;
} else {
    $pid = fork;
}
if ($pid) {
    print $pid;
    for (my $i = 0; $i < 5; $i++) {
	if (! -r $limits_file) {
	    sleep 1;
	}
    }
    print STDERR "\n\n";
    if (! -r $limits_file) {
	warn "System limitations file $limits_file still not found.\n ";
    }

    if ($^O eq 'cygwin') {
	# clean up the stray process with the same PGID as this process.
	# If that works, it will suppress the "WSFO time out ..." error.
	my $target_pgid = $$;
	if (fork() == 0) {
	    $0="system-limits.PL cygwin cleanup";
	    sleep 30;
	    my @proc_table = qx(/usr/bin/ps);
	    shift @proc_table;             # skip header
	    foreach my $ps (@proc_table) {
		next if $ps =~ m(/usr/bin/ps);
		$ps =~ s/^\s+//;
		my @ps = split /\s+/, $ps;
		if ($ps[2] == $target_pgid && $ps[0] != $target_pgid) {
		    sleep 10;
		    system("taskkill /f /pid $ps[3]");
		}
	    }
	    exit;
	}
    }
    exit;
}
unless ($INC{'perl5db.pl'}) {
    close $_ for *STDOUT, *STDERR, *STDIN;
    if ($ENV{QQQUIET}) {
        open TTY, $^O eq 'MSWin32' ? '>nul' : '>/dev/null';
    } else {
        open TTY, $^O eq 'MSWin32' ? '>con' : '>/dev/tty';
    }
    *STDOUT = *STDERR = *TTY;
}

# for best results, only one process should be testing limits at a time
open(LOCK, ">>", "t/out/.lock-flim");
flock LOCK, 2;

END {
    if ($$ == $MAIN_PID) {
	close LOCK;
	unlink "t/out/.lock-flim";
    }
}

$LIMITS{system} = $^O;
$LIMITS{version} = $];
write_limits();

# XXX - what else is interesting? 
#       max pending signals?

our $DARWIN = $^O eq 'darwin' || $^O eq 'MacOS';
# MacOS hangs somewhere in this script.

&get_Time_HiRes_tolerance;
&count_number_of_cpus;
&find_max_open_filehandles;     # on some systems:  ulimit -n
&find_max_open_sockets;         # TODO
&find_socket_capacity;
&find_pipe_capacity;            # on some systems:  512 * ulimit -p
&wait_waitpid_results;
&explore_sync_options;
&explore_alternate_alarm;
&check_proc_process_table;
&probe_ssh_test_env;


# gnukfreebsd/midnightbsd can see "Maximal count of pending signals 
# (120) exceeded" messages in t/32.
&find_max_fork(
    $^O eq 'gnukfreebsd' || $^O eq 'midnighbsd' ? 110 : 300
);  # run last because it might crash the program
print "Created system limitations file in: $limits_file in ",time-$^T,"s\n";

close LOCK;

#############################################################################

sub write_limits {
    $DARWIN && print STDERR "    write_limits(@_)\n";

    my (%new_data) = @_;
    $LIMITS{$_}=$new_data{$_} for keys %new_data;
    my @l2 = ();

    open(my $lhf, '>', $LIMITS{file});
    foreach my $key (sort keys %LIMITS) {
        my $val = $LIMITS{$key};
        if ($key =~ s/^sys\|//) {
            push @l2, "$key:$val\n";
        }
	print $lhf "$key:$val\n";
    }
    close $lhf;
    if (@l2 && $limits2) {
        open my $lh2, '>', $limits2;
        print $lh2 @l2;
        close $lh2;
    }
}

#############################################################################

sub get_Time_HiRes_tolerance {
    $DARWIN && print STDERR "  in get_Time_HiRes_tolerance()\n";

    # I found an insidious bug where this code:
    #    do {
    #       $t1 = Time::HiRes::time();
    #       $t2 = Time::HiRes::time();
    #       $t2 < $t1
    #    };
    # could return *TRUE*!
    #
    # On opensolaris 5.11 (running on Oracle VM Virtualbox, which was
    # running on Windows 7), this can be as much as 0.03s.
    #
    # Even on Windows 7/Cygwin, it can be 0.0005s
    #
    # www.cpantesters.org/cpan/report/df00514e-153d-11e1-b03e-8398e1de4735:
    # this value is 0.89s ?!?!?!
    #

    # Ideally, this subroutine is run on a lightly loaded system.
    return if defined $LIMITS{'sys|TimeHiRes_tol'};
    unless (eval 'use Time::HiRes (); 1') {
	write_limits(TimeHiRes_tol => '0E0');
    }
    my ($max,$t,$u,$diff) = (0, Time::HiRes::time());
    my $v = $t + 10;
    while ($t < $v) {
	($u,$t) = ($t,Time::HiRes::time());
	$diff = $u-$t;
	$max=$diff if $max<$diff;
    }
    if ($max > 0) {
	print STDOUT
            "Observed time on this system skipping backwards by ${max}s.\n";
    } else {
        print STDOUT "No timing anomalies observed on this system.\n";
    }
    write_limits('TimeHiRes_tol' => $max * 1.1);
}


# sub checkif_sleep_alarm_compatible
# wasn't deemed as reliable as moving this check
# directly into  SysInfo.pm.PL


#
# determine the maximum number of simultaneous background processes
#
sub find_max_fork {
    $DARWIN && print STDERR "  in find_max_fork\n";

    return if $LIMITS{'sys|maxfork'};
    if ($DARWIN) {
        &write_limits('sys|maxfork' => 10);
    }
    my $N = shift;
    my $limits_file = $LIMITS{file};
    if (-f $limits_file) {
	unlink $limits_file;
    }

    print "";
    undef $@;
    my $r = eval {
	unlink "$limits_file.pid";
	for (my $i=1; $i<=$N; $i++) {
	    undef $@;
	    my $pid;
	    eval { $pid = fork() };    # CORE::fork, not Forks::Super::fork
	    if ($@ || !defined $pid) {
		print "Cannot fork more than $i child processes.\n";
		1 while wait > -1;
		exit 0;
	    } elsif ($pid == 0) {
		print "";
		$0 = "system-limits.PL \&find_max_fork";
		sleep 10;
		exit 0;
	    }
	    if ($i > 1) {
		&write_limits('sys|maxfork' => $i, 'sys|valid' => 1);
	    }
	}
	1 while wait > -1;

        if ($N < 2000) {
            print "$^O-$] successfully forked $N processes.\n";
	    return find_max_fork(2000);
	}
	print "$^O-$] successfully forked $N processes.\n";
        $N;
    };
    print "Result: ",defined($r)?$r:'<undef>'," / $@\n";
    return $r;
}

#
# determine the maximum number of open filehandles allowed
# by a process on this system. The module doesn't (currently)
# do anything with this information.
#
sub find_max_open_filehandles {
    $DARWIN && print STDERR "  in find_max_open_filehandles\n";
    
    # in BSD, this information can be obtained from
    # sysctl kern.maxfiles[=new_value]
    # sysctl kern.maxfilesperproc[=new_value]

    # in Linux, check out the files. They can be written to.
    # /proc/sys/kernel|fs/file-max  [max open filehandles]
    # /proc/sys/kernel/inode-max
    # /proc/sys/kernel/file-nr   [filehandles in use]
    # Per process limits from:  ulimit -n ; sudo ulimit -n <n>

    # Solaris: add to /etc/system:
    #     set rlim_fd_max = xxxx
    #     set rlim_fd_cur = xxxx



    # we also want to get the error number for the
    # "Too many open files" and "No such file or directory"
    # error messages -- in a different locale we cannot
    # count on $! containing any particular text.

    if ($DARWIN) {
        # sensible defaults for MacOS until we figure out where MacOS
        # is hanging in this script
        &write_limits('maxfilehandle' => 1024,
                      'maxfilehandle_msg' => "Too many open filehandles",
                      'maxfilehandle_errno' => 24);
        return;
    }


    my $i = 0;
    undef $!;
    my $j = $$;
    my @fh = ();
    while (open (my $fh, ">", "xxx.$j")) {
	$i++;
	push @fh, $fh;
    }
    my $err = 0 + $!;
    close $_ for @fh;
    # print "Msg for $i open files: $err\n";
    $! = $err;
    &write_limits('maxfilehandle' => $i,
		  'maxfilehandle_msg' => $!,
		  'maxfilehandle_errno' => $err);
    unlink "xxx.$j";
    print "Can open $i file handles simultaneously\n";

    #################################
    # also figure out the errno
    # for file not found.
    #################################

    $! = 0;
    open my $xh, '<', 'qwpor/qwer/qw/t/346/234/t';
    &write_limits('fnf_errno' => 0+$!,
		  'fnf_msg' => $!);

    return $i;
}

sub find_max_open_sockets {
    # TODO
}

# what values do CORE::wait and CORE::waitpid return
# for bogus inputs? What are the side effects on $? ?
sub wait_waitpid_results {
    $DARWIN && print STDERR "  in wait_waitpid_results\n";

    use POSIX ':sys_wait_h';
    my %info = ();
    my $pid = CORE::fork();
    if (defined($pid) && $pid==0) {
	$0 = "system-limits.PL wait_waitpid_results";
	sleep 3;
	exit;
    }
    $info{active_waitpid_result} = waitpid $pid, &WNOHANG;
    $info{active_waitpid_status} = $?;

    # XXX - not idiot proof - $pid+1 could be a valid process identifier
    $info{bogus_waitpid_result} = waitpid $pid+1, &WNOHANG;
    $info{bogus_waitpid_status} = $?;

    waitpid $pid, 0;

    $info{reaped_waitpid_result} = waitpid $pid, &WNOHANG;
    $info{reaped_waitpid_status} = $?;

    local $SIG{CHLD} = 'IGNORE';
    $pid = CORE::fork();
    exit if $pid == 0;
    sleep 1;
    $info{ignore_waitpid_result} = waitpid $pid, 0;
    $info{ignore_waitpid_status} = $?;
    if ($info{ignore_waitpid_result} == $pid) {
	$info{ignore_waitpid_result} = 'undef';
	$info{ignore_waitpid_status} = 'undef';
    }

    write_limits( %info );
}

#
# what options are available to this system for interprocess synchronization?
#
sub explore_sync_options {
    $DARWIN && print STDERR "  in explore_sync_options\n";

    my @sync = ();
    @_ = ();

    if ($^O eq 'MSWin32' || $^O =~ /cygwin/i) {
	if (eval { require Win32::Semaphore; 1 }) {
	    print "Win32 semaphores are available for ",
	    	"ipc synchronization\n";
	    push @sync, "Win32";
	    write_limits( sync_options => join('/', @sync) );
	}

	if (eval { require Win32::Mutex; 1 }) {
	    print "Win32 mutexes are available for ",
	    	"ipc synchronization\n";
	    push @sync, "Win32Mutex";
	    write_limits( sync_options => join('/', @sync) );
	}
    }

    if (eval {
	# exercise IPC::Semaphore
	no warnings 'prototype';
        no warnings 'redefine';
	require IPC::SysV;
	require IPC::Semaphore;
	IPC::SysV->import(qw(IPC_PRIVATE S_IRUSR S_IWUSR IPC_CREAT IPC_NOWAIT));
	my $sem = IPC::Semaphore->new(&IPC_PRIVATE, 2,
				      &S_IRUSR | &S_IWUSR | &IPC_CREAT);
	$sem->setall(1,0);
	$sem->setval(1,1);
	$sem->remove;
	eval { alarm 0 };
	1 } ) {

	print "SysV semaphores are available for ipc synchronization\n";
	push @sync, "IPCSemaphore";
	write_limits( sync_options => join('/', @sync) );
    }

    # advisory file locking ? It actually might not work so well on
    # Cygwin, or with NFS filesystems, and it could be slower than 
    # the other methods. So make this the last option.        
    my $file = "foo.$$";
    if (fork() == 0) {
	open my $fh, ">>", $file;
	flock $fh, 2;
	sleep 5;
	close $fh;
	exit;
    }
    sleep 2;
    open my $fh, '>>', $file;
    my $t = time;
    eval { eval { alarm 30 }; flock $fh, 2; alarm 0; };
    $t = time - $t;
    close $fh;
    if ($t > 1 && $t < 20) {
	print "advisory filelocking available for ipc synchronization\n";
	push @sync, "Semaphlock";
	write_limits( sync_options => join('/', @sync) );
    }
    unlink $file;

    write_limits( sync_options => join('/', @sync) );
}

sub signame_to_signum {
    use Config;
    my $sig = shift;
    my @signames = split ' ',$Config{sig_name};
    my @signums = split ' ',$Config{sig_num};
    for my $i (0 .. $#signames) {
        if ($signames[$i] eq $sig) {
            return $signums[$i];
        }
    }
    return $sig;
}

# usual method of making a child process timeout in Forks::Super
# is to use `alarm`. Occasionally (I'm looking at you, freebsd)
# this is not a good option, and we have to resort to the
# poor man's alarm (see &poor_mans_alarm in Forks/Super/Job/OS.pm).
#
# If you get test failures for t/40g-timeout.t and t/65e-daemon.t,
# this is a good place to start.
#
# more investigation needed, but it looks like the alternate
# alarm is needed for systems where SIGALRM cannot interrupt
# a system call in a grandchild process
#
# RT#118474 - maybe MacOS/darwin should use the alt alarm
sub explore_alternate_alarm {
    $DARWIN && print STDERR "  in explore_alternate_alarm\n";

    if (defined $ENV{PREFER_ALT_ALARM}) {
        write_limits( prefer_alt_alarm => $ENV{PREFER_ALT_ALARM}+0 );
    } elsif ($^O =~ /bsd|darwin/) {
        write_limits( prefer_alt_alarm => 1 );
    } else {
        write_limits( prefer_alt_alarm => 0 );
    }
    return;
}

# There exist systems where Proc::ProcessTable is installed
# but it segfaults anyway.
sub check_proc_process_table {
    $DARWIN && print STDERR "  in check_proc_process_table\n";

    my $pid = fork;
    if ($pid == 0) {
	require Proc::ProcessTable;
	Proc::ProcessTable->new->table;
	exit 0;
    }
    waitpid $pid, 0;
    if ($?) {
	write_limits( proc_processtable_ok => 0 );
    } else {
	write_limits( proc_processtable_ok => 1 );
    }
}

#
# try to guess how many processors this system has.
# Eventually we could use that information to set
# a default value of $Forks::Super::MAX_PROC in the
# installed code.
#
# See also: Sys::CpuAffinity getNumCpus() method
#           Forks::Super::Job::OS::get_number_of_processors() method
#
sub count_number_of_cpus {
    $DARWIN && print STDERR "  in count_number_of_cpus\n";

    my ($ncpu, $fh);
    return if $LIMITS{'sys|ncpu'};

    $ncpu = 0;
    my $sys = 0;
    if (eval "require Sys::CpuAffinity; 1") {
	$ncpu = Sys::CpuAffinity::getNumCpus();

	# darwin: result might have format "1 [2 cores]"
	$ncpu =~ s{\d+ \[(\d+) cores\]}{$1};
        $sys = !!$ncpu;
    }
    if ($ncpu == 0 && eval "require Test::Smoke::SysInfo;1") {
	my $sysinfo = Test::Smoke::SysInfo->new();
	$ncpu = $sysinfo && $sysinfo->{_ncpu};
        $sys = !!$ncpu;
    }

    if ($ncpu == 0 && $^O eq "MSWin32") {
	$ncpu = $ENV{NUMBER_OF_PROCESSORS};
        $sys = !$ncpu;
    }
    if ($ncpu == 0 && open($fh,'<','/proc/cpuinfo')) {
	$ncpu = grep /^processor\s/, <$fh>;
	close $fh;
        $sys = !!$ncpu;
    }
    if ($ncpu == 0 && open($fh,'<','/proc/stat')) {
	$ncpu = grep /^cpu\d/i, <$fh>;
	close $fh;
        $sys = !!$ncpu;
    }
    if ($ncpu == 0) {
	$ncpu = grep /\d+.+processors?$/i, qx(hinv -c processor 2>/dev/null);
        $sys =!!$ncpu;
    }
    if ($ncpu == 0) {
	$ncpu = () = qx(bindprocessor -q 2>/dev/null);
        $sys =!!$ncpu;
    }
    if ($ncpu == 0) {
	$ncpu = grep /^hw.ncpu:/, qx(sysctl -a 2>/dev/null);
        $sys =!!$ncpu;
    }
    if ($ncpu == 0) {
	$ncpu = () = qx(psrinfo 2> /dev/null);
        $sys =!!$ncpu;
    }
    if ($ncpu == 0) {
	$ncpu = qx(hwprefs cpu_count 2>/dev/null);
        $sys =!!$ncpu;
    }

    if ($ncpu && $ncpu > 0) {
	print "There are $ncpu cpus on this system.\n";
        if ($sys) {
            write_limits( 'sys|ncpu' => $ncpu + 0 );
        } else {
            write_limits( ncpu => $ncpu + 0 );
        }
    } else {
	print "I am having trouble detecting the number\n";
	print "of processors on your system. Consider\n";
	print "installing the  Sys::CpuAffinity  module\n";
	print "before running this script.\n";
	write_limits( ncpu => "1.0" );
    }
}

# does this host have a simple way to conduct the remote tests (t/49*.t)?
sub probe_ssh_test_env {
    $DARWIN && print STDERR "  in probe_ssh_test_env\n";

    return if $LIMITS{'sys|test_ssh_target'};
    write_limits( 'sys|test_ssh_target', '0');

    my $ENV_USER = $ENV{USER} || 'xxxxx';
    my $ENV_HOST = $ENV{HOSTNAME} || 'xhxhxhxh';
    chomp(my $hostname = qx(hostname));
    $hostname ||= 'knknknknknk';
    my $ip = eval "use Sys::HostAddr;1" 
             ? Sys::HostAddr->new->main_ip : "299.1.1.1";

    foreach my $host ('$ENV_HOST', '$ip', 'localhost', '$hostname') {
        foreach my $user ('$ENV_USER','') {

            my $cmdtmp = "ssh ";
            if ($user) {
                $cmdtmp .= " -l $user";
            }
            $cmdtmp .= " $host";

            my $cmd = $cmdtmp;
            $cmd =~ s/\$ENV_USER/$ENV_USER/;
            $cmd =~ s/\$ENV_HOST/$ENV_HOST/;
            $cmd =~ s/\$hostname/$hostname/;
            $cmd =~ s/\$ip/$ip/;
            my $token = sprintf "%06X", rand() * 0xFFFFFF;

            my $null = $^O eq 'MSWin32' ? 'nul' : '/dev/null';
            my $ssh_output = qx($cmd echo $token < $null 2> $null);
            my $ssh_status = $?;
            chomp($ssh_output);

            if ($ssh_output eq $token && $ssh_status == 0) {
                print STDERR "Suitable ssh test configuration: $cmdtmp\n";
                write_limits('test_ssh_target', $cmdtmp);
                return;
            }
        }
    }
    print STDERR "No suitable ssh test configuration!\n";
}

sub find_socket_capacity {
    $DARWIN && print STDERR "  in find_socket_capacity\n";

    return if $LIMITS{'sys|socket_capacity'};

    if ($DARWIN) {
        write_limits("sys|socket_capacity" => 16384);
        return;
    }
    
    my $socket_capacity = 
	_get_capacity(16384, 1,
		      qq[use Socket;
		         socketpair DUMMY,WRITER,AF_UNIX,SOCK_STREAM,PF_UNSPEC]);
    print "Default socket capacity is about $socket_capacity bytes\n";
    &write_limits('sys|socket_capacity' => $socket_capacity);
    close DUMMY;
    close WRITER;
}

sub find_pipe_capacity {
    $DARWIN && print STDERR "  in find_pipe_capacity\n";

    return if $LIMITS{'sys|pipe_capacity'};
    if ($DARWIN) {
        write_limits("sys|pipe_capacity" => 4096);
        return;
    }
    my $pipe_capacity =
	_get_capacity(256, 2, qq[pipe DUMMY,WRITER]);
    print "Default pipe capacity is about $pipe_capacity bytes\n";
    &write_limits('sys|pipe_capacity' => $pipe_capacity);
    close DUMMY;
    close WRITER;
}

sub _get_capacity {
    my ($packetsize, $timeout, $create_WRITER) = @_;
    my $capacity = __get_capacity($packetsize,$timeout,$create_WRITER);
    while ($capacity <= 0) {
	if ($capacity > -2) {
	    return 0 if $packetsize <= 1;
	    print "Packet size of $packetsize was too large. Retrying\n";
	    $packetsize = int($packetsize / 64);
	} elsif ($capacity == -2) {
	    return 0 if $timeout > 300;
	    print "Capacity not found with timeout=$timeout. Retrying\n";
	    $timeout *= 2;
	}
	$capacity = __get_capacity($packetsize,$timeout,$create_WRITER);
    }
    return $capacity;
}

#####################################################################
# to find the capacity of a pipe or socket on this system,
# the idea is to keep writing bytes to the handle until it blocks.
# Windows is pretty cantankerous and it is hard to recover from the
# deadlock when a write operation blocks: the 4-arg select won't
# work with pipes (and it doesn't work that well with sockets,
# anyway), and alarm() won't interrupt an I/O operation.
# The portable solution is overkill on non-Windows systems but
# gets the job done -- test the socket in a separate process
# (NOT a psuedo-process/thread) and let the process kill itself
# when it times out.
#####################################################################
sub __get_capacity {
    my ($packetsize, $timeout, $create_WRITER, $output_file) = @_;
    $output_file ||= "./test-capacity.out";
    my $pid_file = "./test-capacity.pid";
    if ($packetsize < 1) {
	$packetsize = 1;
    }

    # capacity == -1  means the packetsize was too large: decrease packetsize
    # capacity == -2  means the pipe did not block: increase timeout
    my $capacity = -1;
    my $code = <<"__END_SLAVE_CODE__";
use IO::Handle;
use strict;
\$| = 1;
$create_WRITER;
*WRITER->autoflush(1);
binmode WRITER;
my \$output = " " x $packetsize;
my \$written = 0;
for (;;) {
 # print WRITER \$output;
 syswrite WRITER, \$output;
 \$written += length \$output;
 open F, ">", \"$output_file\";
 print F time - \$^T >= $timeout ? -2 : \$written;
 close F;
}
__END_SLAVE_CODE__
;

    unlink $output_file, $pid_file;
    if (fork() == 0) {
	$0 = "system-limits.PL __get_capacity";
	sleep $timeout + 1;
	open my $pf, '<', $pid_file;
	my $pid = 0 + <$pf>;

	# hopefully, one of these will do the job on your system
	kill ('TERM', $pid)
	    || kill ('HUP', $pid)
	    || !system ("TASKKILL /f /pid $pid")
	    || do {
		warn "Attempts to kill pid \"$pid\" failing ...\n"; 0
	}
	|| !system ("kill -TERM $pid") 
	    || kill ('BREAK', $pid);
	exit 0;
    }

    my $pid = open(SLAVE, "| $^X");

    open my $pf, '>', $pid_file;
    print $pf $pid;
    close $pf;

    print SLAVE $code;
    close SLAVE;

    sleep 1;
    open(CAP, '<', $output_file);
    $capacity = (<CAP>)[-1];
    close CAP;
    unlink $output_file, $pid_file;
    return $capacity + 0;
}

__END__

RT#105454 - speed up system-limits.PL, especially when it
    is run for a second time (say, for a different version of perl):

some information is system-specific, not perl specific.
Perhaps we could store some information in a more general
t/out/limits.$^O file:
   ncpu
   maxfork
   system
