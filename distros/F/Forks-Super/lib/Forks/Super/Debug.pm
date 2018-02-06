#
# Forks::Super::Debug package - manage Forks::Super module-specific
#         debugging messages
#

package Forks::Super::Debug;
use Forks::Super::Util 'IS_WIN32';
use IO::Handle;
# use Signals::XSIG;
use Exporter;
use Carp;
use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(debug $DEBUG carp_once);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);
our $VERSION = '0.92';
our $DUMPSIG;
our $EM = 0;

our ($DEBUG, $DEBUG_FH, %_CARPED, 
     $OLD_SIG__WARN__, $OLD_SIG__DIE__, $OLD_CARP_VERBOSE);


if (defined $ENV{FORKS_SUPER_ENABLE_DUMP}) {
    enable_dump($ENV{FORKS_SUPER_ENABLE_DUMP});
}


## no critic (BriefOpen,TwoArgOpen)

# initialize $DEBUG_FH.
do {
    if (uc($ENV{FORKS_SUPER_DEBUG} || '') eq 'TTY') {
	my $console = $^O eq 'MSWin32' ? 'CON' : '/dev/tty';
	eval { open($DEBUG_FH, '>:encoding(UTF-8)', $console) } 
	or eval { open($DEBUG_FH, '>', $console) }
	or 0;
    } else {
	0;
    }
} or open($DEBUG_FH, '>&2')
    or $DEBUG_FH = *STDERR
    or carp_once('Forks::Super: Debugging not available in module!');

## use critic
$DEBUG_FH->autoflush(1);
$DEBUG = !!$ENV{FORKS_SUPER_DEBUG} || '0';

sub init {
}

sub debug {
    my @msg = @_;
    # TODO: consider locking the filehandle or other synchronization
    if ($EM) {
        print {$DEBUG_FH} $$,'E ',Forks::Super::Util::Ctime(),' ',@msg,"\n";
    } else {
        print {$DEBUG_FH} $$,' ',Forks::Super::Util::Ctime(),' ',@msg,"\n";
    }
    return;
}

# sometimes we only want to print a warning message once
sub carp_once {
    my @msg = @_;
    my ($p,$f,$l) = caller;
    my $z = '';
    if (ref $msg[0] eq 'ARRAY') {
	$z = join ';', @{$msg[0]};
	shift @msg;
    }
    return if $_CARPED{"$p:$f:$l:$z"}++;
    return carp @msg;
}

# load or emulate Carp::Always for the remainder of the program
sub use_Carp_Always {
    if (!defined $OLD_CARP_VERBOSE) {
	$OLD_CARP_VERBOSE = $Carp::Verbose;
    }
    $Carp::Verbose = 'verbose';
    if (!defined($OLD_SIG__WARN__)) {
	$OLD_SIG__WARN__ = $SIG{__WARN__} || 'DEFAULT';
	$OLD_SIG__DIE__ = $SIG{__DIE__} || 'DEFAULT';
    }
    ## no critic (RequireCarping)
    $SIG{__WARN__} = sub { warn &Carp::longmess };
    $SIG{__DIE__} = sub { warn &Carp::longmess };
    return 1;
}

# stop emulation of Carp::Always
sub no_Carp_Always {
    $Carp::Verbose = $OLD_CARP_VERBOSE || 0;
    $SIG{__WARN__} = $OLD_SIG__WARN__ || 'DEFAULT';
    $SIG{__DIE__} = $OLD_SIG__DIE__ || 'DEFAULT';
    return;
}

#############################################################################

sub enable_dump {
    my $sig = shift;
    if ($sig =~ /\D/) {
	if (exists $SIG{uc $sig}) {
	    $DUMPSIG = uc $sig;
	} else {
	    carp "Forks::Super::Debug::enable_dump: ",
	    	"$sig is not a valid signal name. Using 'QUIT'";
	    $DUMPSIG = 'QUIT';
	}
    }
    if ($sig) {
	$DUMPSIG ||= 'QUIT';
	$SIG{$DUMPSIG} = sub { parent_dump(1); }
    } else {
	if ($DUMPSIG) {
	    $SIG{$DUMPSIG} = 'DEFAULT';
	}
	$DUMPSIG = '';
    }
}

my $parent_dumps = 0;
sub parent_dump {
    # do something like what a Java virtual machine does when it gets
    # a SIGQUIT signal -- print out some information about the
    # currently running jobs. It will help users identify "stuck" jobs

    # what would we want to know?
    #
    #   parent: current stack trace
    #
    #   all jobs
    #   --------
    #     job id
    #     current state
    #     creation time
    #     cmd/exec: command
    #     sub/not code ref: name of subroutine
    #     sub/code ref:     caller
    #
    #   queued jobs
    #   -----------
    #     last queue check, reason for last deferral (*)
    #
    #   active/suspended jobs
    #   ---------------------
    #     start time
    #     current pid
    #   X child_fh summary
    #   X sub/natural: stack trace from child (*)
    #
    #   completed jobs
    #   --------------
    #     completion time (total run time)
    #     exit status
    #     reaped? reap time
    #   X output produced, input consumed (*)
    #
    # other stuff we want to know:
    # ----------------------------
    #     total jobs on queue
    #     total active jobs
    #     total completed jobs
    #     completed job distribution of run times
    my ($dump_completed_jobs) = @_;
    no warnings 'once';

    if ($$ != $Forks::Super::MAIN_PID) {
	# this is not the main fork, so we should do the
	# default SIGQUIT behavior. i.e., QUIT.
	exit 21 if &IS_WIN32;
	exec $^X, '-e', 'kill "QUIT",$$; sleep 1; die';
    }

    $parent_dumps++;

    open my $TTY, '>>', &IS_WIN32 ? 'CON' : '/dev/tty';

    print $TTY scalar localtime(time), "\n";
    print $TTY "Full Forks::Super v$Forks::Super::VERSION ",
    	"job dump process $$\n";
    # if $MAX_PROC is a coderef, this output will be like "CODE(0x0123ABCD)"
    print $TTY "Default maximum background procs:  $Forks::Super::MAX_PROC\n";
    print $TTY "Default maximum CPU load:          $Forks::Super::MAX_LOAD\n";
    print $TTY "Child fork ok:                     ",
    	"$Forks::Super::CHILD_FORK_OK\n";
    print $TTY "Default busy system busy behavior: $Forks::Super::ON_BUSY\n";
    if (defined($Forks::Super::IPC_DIR) && $Forks::Super::IPC_DIR ne '') {
	print $TTY "Default IPC directory:  $Forks::Super::IPC_DIR\n";
    }
    
    print $TTY "\n";

    # parent process
    print $TTY "PARENT PROCESS\n--------------\n";
    print $TTY &Carp::longmess, "\n\n";

    # signal active jobs to give us their stack traces, if applicable
    my $children_signalled = 0;
    foreach my $job (@Forks::Super::ALL_JOBS) {
	if ($job->is_active && $job->{_enable_dump}
	    && ($job->{style} eq 'natural' || $job->{style} eq 'sub')) {

	    $children_signalled += $job->kill($DUMPSIG);
	}
    }

    # active jobs
    my $header = 0;
    my ($num_active, $num_deferred, $num_complete, $num_other) = (0,0,0,0);
    my $num_reaped = 0;
    foreach my $job (@Forks::Super::ALL_JOBS) {
	if ($job->is_active || $job->{state} eq 'SUSPENDED') {
            if (!$header++) {
                print $TTY "ACTIVE JOBS\n-----------\n\n";
            }
	    _dump_job($TTY, $job);
	    $num_active++;
	}
    }

    # queued jobs
    $header = 0;
    foreach my $job (@Forks::Super::ALL_JOBS) {
	if ($job->is_deferred) {
            if (!$header++) {
                print $TTY "QUEUED JOBS\n-----------\n\n";
            }
	    _dump_job($TTY, $job, 'queue');
	    $num_deferred++;
	}
    }

    # complete jobs
    my @run_times = ();
    if ($dump_completed_jobs) {
	$header = 0;
	foreach my $job (@Forks::Super::ALL_JOBS, 
			 @Forks::Super::Job::ARCHIVED_JOBS) {
	    if ($job->is_complete) {
                if (!$header++) {
                    print $TTY "COMPLETE JOBS\n-------------\n\n";
                }
		_dump_job($TTY, $job);
		push @run_times, $job->{end} - $job->{start};
		$num_complete++;
		$num_reaped++ if $job->is_reaped;
	    }
	}
    }

    # other ?
    $header = 0;
    foreach my $job (@Forks::Super::ALL_JOBS, 
		     @Forks::Super::Job::ARCHIVED_JOBS) {
	if (!$job->is_active && !$job->is_complete
                && !$job->is_deferred && !$job->is_suspended) {
            if (!$header++) {
                print $TTY "OTHER JOBS\n----------\n\n";
            }
	    _dump_job($TTY,$job);
	    $num_other++;
	}
    }

    # summary
    if ($num_active || $num_complete || $num_deferred || $num_other) {
	print $TTY "SUMMARY\n-------\n";
	print $TTY "Active jobs  : $num_active\n" if $num_active;
	print $TTY "Deferred jobs: $num_deferred\n" if $num_deferred;
	if ($num_complete) {
	    my ($x,$x2) = (0,0);
            for my $run_time(@run_times) {
                $x += $run_time;
                $x2 += $run_time * $run_time;
            }
	    $x /= @run_times;
 	    $x2 /= @run_times;
	    $x2 -= $x*$x;
	    $x2 = $x2 > 0 ? sqrt($x2) : 0.0;  # stdev of run times
	    printf $TTY ("Completed jobs: %d (%d reaped)  "
			 . "Run time: %.3fs +/- %.3fs\n",
			 $num_complete, $num_reaped, $x, $x2);
	}
	print $TTY "Other jobs    : $num_other\n" if $num_other;
	print $TTY "\n";
    }
    close $TTY;
    return;
}

sub _dump_job {
    my ($fh, $job, $style) = @_;
    print $fh "Job";
    if ($job->{name}) {
	print $fh " name=$job->{name}";
    }
    if (!defined($job->{real_pid})) {
	print $fh " jobid=$job->{pid}";
    } elsif ($job->{pid} == $job->{real_pid}) {
	print $fh " jobid=$job->{pid}";
    } else {
	print $fh " jobid=$job->{real_pid}/$job->{pid}";
    }
    print $fh " ", $job->{state}, "\n";

    # XXX - print info about IPC channels

    if ($job->{style} eq 'natural') {
	print $fh "\tStyle: natural\n";
    } elsif ($job->{style} eq 'sub') {
	if (ref($job->{sub}) eq 'CODE') {
	    print $fh "\tStyle: Perl subroutine (CODE ref)\n";
	} else {
	    print $fh "\tStyle: Perl subroutine ($job->{sub})\n";
	}
    } elsif ($job->{style} eq 'cmd') {
	my $cmd = $job->{cmd};
	if (ref($cmd) eq 'ARRAY') {
	    $cmd = join ' ', @$cmd;
	}
	print $fh "\tStyle: external command ($cmd)\n";
    } elsif ($job->{style} eq 'exec') {
	my $cmd = $job->{exec};
	if (ref($cmd) eq 'ARRAY') {
	    $cmd = join ' ', @$cmd;
	}
	print $fh "\tStyle: exec ($cmd)\n";
    } else {
	print $fh "\tStyle: $job->{style}\n";
    }

    print $fh "\tCreated: ", scalar localtime($job->{created}), "\n";

    if ($job->{state} eq 'DEFERRED') {
	print $fh "\tQueued : ", scalar localtime($job->{queued}), "\n";
	print $fh "\tQ Prio.: ", $job->{queue_priority}, "\n";
	if ($job->{queue_message}) {
	    print $fh "\tLast queue msg: ", $job->{queue_message}, "\n";
	}
    }

    if ($job->{start}) {
	print $fh "\tStarted: ", scalar localtime($job->{start}), "\n";
    }
    if ($job->{end}) {
	print $fh "\tFinished: ", scalar localtime($job->{end}), "\n";
	print $fh "\tRun time: ", ($job->{end}-$job->{start}), "s\n";
    }
    if ($job->{reaped}) {
	print $fh "\tReaped  : ", scalar localtime($job->{reaped}), "\n";
	print $fh "\tExit status: ", $job->{status}, "\n";
    }

    if ($job->is_active && $job->{_enable_dump}
	&& ($job->{style} eq 'natural' || $job->{style} eq 'sub')) {

	# try to load stacktrace
	my $f = $job->{_enable_dump};
	my $st_h;
	if (open $st_h, '<', $job->{_enable_dump}) {
	    local $_;
	    print $fh "\tStack trace:\n";
	    while (<$st_h>) {
		next if /Forks::Super::Debug::child_dump/; 
		next if /^$DUMPSIG at /;
		print $fh "\t$_";
	    }
	    close $st_h;
	}
	unlink $job->{_enable_dump};
    }


    print $fh "\n";
    return;
}

sub child_dump {
    my $job = &Forks::Super::Job::this;
    if ($job->{_enable_dump}) {
	if (open my $fh, '>', $job->{_enable_dump} . '.tmp') {
	    print $fh &Carp::longmess;
	    close $fh;
	    rename $job->{_enable_dump} . '.tmp', $job->{_enable_dump};
	}
    }
    return;
}

#############################################################################

# display some information about filehandles that were opened by
# Forks::Super and are still open. I didn't intend for anyone else
# to use this, but feel free.
sub __debug_open_filehandles {
    use POSIX ();

    print STDERR "Open FH count is ",
           "$Forks::Super::Job::Ipc::__OPEN_FH in ",
           scalar keys %Forks::Super::Job::Ipc::__OPEN_FH, " fds\n";

    # where are the open filehandles?
    my %jobs;
    while ( my($fileno, $job) = each %Forks::Super::Job::Ipc::__OPEN_FH) {

	my $pid = $job->{real_pid} || $job->{pid};
	$jobs{$pid} ||= [];

	push @{$jobs{$pid}}, $fileno;
    }

    foreach my $pid (sort {$a <=> $b} keys %jobs) {

	my @filenos = @{$jobs{$pid}};
	my ($m,$n) = (0,0);
	foreach (@filenos) {
	    $n++;
	    if (defined POSIX::close($_)) {
		$m++;
	    }
	}
	print STDERR "Open FH in $pid: @filenos   Close $m/$n\n";
    }
    return;
}

1;

=head1 NAME

Forks::Super::Debug - debugging and logging routines for Forks::Super distro

=head1 VERSION

0.92

=head1 VARIABLES

=head2 $DEBUG

Many routines in the L<Forks::Super|Forks::Super> module look at this
variable to decide whether to invoke the L<"debug"> function. So if
this variable is set to true, a lot of information about what the
L<Forks::Super|Forks::Super> module is doing will be written to the
debugging output stream.

If the environment variable C<FORKS_SUPER_DEBUG> is set, the C<$DEBUG>
variable will take on its value. Otherwise, the default value of this
variable is zero.

=head2 $DEBUG_FH

An output file handle for all debugging messages. Initially, this module
tries to open C<$DEBUG_FH> as an output handle to the current tty (C<CON>
on MSWin32). If that fails, it will try to dup file descriptor 2 (which
is usually C<STDERR>) or alias C<$DEBUG_FH> directly to C<*STDERR>.

The initial setting can be overwritten at runtime. See C<t/15-debug.t>
in this distribution for an example.

=head1 FUNCTIONS

=head2 debug

Output the given message to the current C<$DEBUG_FH> file handle.
Usually you check whether C<$DEBUG> is set to a true value before
calling this function.

=head2 carp_once

Like L<"carp" in Carp|Carp/"carp">, but remembers what warning 
messages have already been printed and suppresses duplicate messages.
This is useful for heavily used code paths that usually work, but tend
to produce an enormous number of warnings when they don't.

    use Forks::Super::Debug 'carp_once';
    for (1 .. 9999) {
        $var = &some_function_that_should_be_zero_but_sometimes_isnt;
        if ($var != 0) {
            carp_once "var was $var, not zero!";
        }
    }

should produce at most one warning in the lifetime of the program,

C<carp_once> can take a list reference as an optional first argument
to provide additional context for the warning message. This code,
for example, will produce one warning message for every different 
value of C<$!> that can be produced.

    while (<$fh>) {
        local $! = 0;
        do_something($_);
        if ($!) {
            carp_once [$!], "do_something() did something!: $!";
        }
    }

=head2 enable_dump

Writes information about all known jobs to the console in response
to an OS signal.

This feature is inspired by the many implementations of the Java
Virtual Machine that can dump a list of all thread stack traces
when the JVM receives a C<SIGQUIT> signal.

C<Forks::Super::Debug::enable_dump> is this module's attempt to
emulate this feature. When the program receives the specified signal,
it will dump information about all known jobs to the console.

C<enable_dump> takes one argument. If the argument evaluates to false,
the process dump will be disabled and all signals will revert to
their default behavior. If the argument is a signal name, the program
will respond to that signal by dumping information about all processes
to the console. If the argument is a true value but not a signal name,
the program will respond to C<SIGQUIT> signals.

This feature may also be enabled upon import of 
L<Forks::Super|Forks::Super> using the C<ENABLE_DUMP> arg. For example,

    use Forks::Super ENABLE_DUMP => 'USR1';

will configure the program to respond to C<SIGUSR1> events. The module
can also enable this feature based on the value of the
C<< $ENV{FORKS_SUPER_ENABLE_DUMP} >> environment variable.

=head1 EXPORTS

This module exports the C<$DEBUG> variable and the C<debug> and
C<carp_once> methods.
The C<:all> tag exports all of these symbols.

=head1 SEE ALSO

L<Forks::Super|Forks::Super>, L<Carp|Carp>

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
