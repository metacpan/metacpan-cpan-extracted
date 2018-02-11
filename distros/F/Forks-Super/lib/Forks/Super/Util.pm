#
# Forks::Super::Util - useful routines that could be helpful
#                      to any of the other Forks::Super::Xxx
#                      packages
#

package Forks::Super::Util;
use Exporter;
use Cwd;
use Carp;
use strict;
use warnings;

use constant IS_WIN32 => $^O =~ /os2|Win32/i;
use constant IS_CYGWIN => $^O =~ /cygwin/i;
use constant IS_WIN32ish => &IS_WIN32 || &IS_CYGWIN;

our @ISA = qw(Exporter);
our $VERSION = '0.93';
our @EXPORT_OK = qw(Ctime is_number isValidPid pause qualify_sub_name shquote
		    is_socket is_pipe IS_WIN32 IS_CYGWIN okl DEVNULL DEVTTY);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our (%SIG_NO, @SIG_NAME, $Time_HiRes_avail,
    $something_productive, $something_else_productive);
our $_PAUSE = 0;
our $DEFAULT_PAUSE = 0.10; # s. Warning: may also be set in Forks/Super.pm
our $DEFAULT_PAUSE_IO = 0.05;

$Time_HiRes_avail = eval  'use Time::HiRes; 1' || 0;
if (!$Time_HiRes_avail) {
    *Time::HiRes::time = \&time;
    *Time::HiRes::sleep = \&__fake_Time_HiRes_sleep;
}
my $Time_HiRes_sleep_avail = defined &Time::HiRes::sleep;


sub __fake_Time_HiRes_sleep {
    my $delay = shift;
    my $n = 0;
    while ($delay >= 1) {
	$delay--;
	CORE::sleep 1;
	$n++;
    }
    if ($delay > 0) {
	$n += $delay;
	select undef,undef,undef,$delay;
    }
    return $n || 0.01;
}

sub Ctime {
    my $t = Time::HiRes::time(); #Time();
    return sprintf '%02d:%02d:%02d.%03d: ',
        ($t/3600)%24, ($t/60)%60, $t%60, ($t*1000)%1000;
}

sub is_number {
    my $s = shift;
    return 0 if !defined($s);
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;

    # www.cpantesters.org/cpan/report/dda92dc8-663c-11e3-bd14-e3bee4621ba3:
    # "Out of memory during ridiculously large request". Does this mean
    # that $s is too long?
    if (length($s) > 100) {
	return 0 if $s =~ /[^0-9eE.+-]/;
    }

    # from Scalar::Util::PP::looks_like_number:
    return $s =~ /^ [+-]? [0-9]+ $/x ||
	$s =~ /^ ([+-]?)
                 (?=[0-9]|\.[0-9])
                 [0-9]*
                 (\.[0-9]*)?
                 ([Ee]([+-]?[0-9]+))?
              $/x;
}

# portable function call to check the return value of fork()
# and see if the call succeeded. For a fork() call that
# results in a "deferred" job, this function will
# return zero.
sub isValidPid {
    my ($pid, $is_wait) = @_;

    if (ref($pid) && $pid->isa('Forks::Super::Job')) {
	# DWIM - if the job is completed, isValidPid() was probably called from
	#    the output of a waitpid/wait call, so test {real_pid} and not {pid}
	#    DWIM behavior can be overridden with $is_wait argument.

	$is_wait ||= 0;
	if ($is_wait < 0) {
	    $pid = $pid->{pid};
	} elsif ($is_wait > 0) {
	    $pid = $pid->{real_pid};
	} elsif ($pid->is_complete) {
	    $pid = $pid->{real_pid} || $pid->{pid}
	} else {
	    $pid = $pid->{pid};
	}
    }
    return 0 if !defined($pid) || !is_number($pid);
    if (&IS_WIN32) {
	# -200000 is too high to be a pseudo-process id on Windows?
	# also see &Forks::Super::Deferred::FIRST_DEFERRED_ID
	return $pid > 0 || ($pid > -200000 && $pid <= -2);
    } else {
	return $pid > 0;
    }
}

sub set_productive_pause_code (&) {
    return $something_productive = shift;
}

# specify another piece of code that can be run 
# one time at the end of each  pause  call.
# Not used in  Forks::Super v0.54, but might be good
# for something some day.
sub set_other_productive_pause_code (&) {
    return $something_else_productive = shift;
}

# productive "sleep" function
sub pause {
    my $start = Time::HiRes::time();
    my $delay = shift || ($DEFAULT_PAUSE ||= 0.25);
    my $unproductive = shift;
    my $expire = $start + $delay;

    $_PAUSE++; # prevent too much productive code from nested pause calls

    my $time_left = $expire - Time::HiRes::time();
    while ($time_left > 0) {
	if ($_PAUSE < 2 && $something_productive && !$unproductive) {
	    $something_productive->();
	    $time_left = $expire - Time::HiRes::time();
	    last if $time_left <= 0;
	}


	if ($Time_HiRes_sleep_avail) {
	    Time::HiRes::sleep($time_left >= $DEFAULT_PAUSE
			       ? $DEFAULT_PAUSE : $time_left);
	} elsif ($time_left >= 1) {
	    CORE::sleep 1 + ($time_left >= 2);
	} else {
	    select undef,undef,undef,$time_left;
	}


	$time_left = $expire - Time::HiRes::time();
    }

    if ($_PAUSE <= 1 && !$unproductive) {
	if ($something_else_productive) {
	    $something_else_productive->();
	} elsif ($something_productive) {
	    $something_productive->();
	}
    }
    $_PAUSE = 0;
    return Time::HiRes::time() - $start;
}

sub _pause_no_Time_HiRes {
    return;
}

#
# prepend package qualifier from current context to a scalar subroutine name.
# Useful when passing an unqualified name of a subroutine declared in the
# calling package to a Forks::Super or Forks::Super::Xxx method
# that takes a code ref.
#
sub qualify_sub_name {
    my $name = shift;
    my $invalid_package = shift || 'Forks::Super';
    if (ref $name eq 'CODE' || $name =~ /::/ || $name =~ /\'/) {
	return $name;
    }

    my $i = 2;
    my $calling_package = caller($i);
    while ($calling_package =~ /$invalid_package/) {
	$i++;
	$calling_package = caller($i);
    }
    return join '::', $calling_package, $name;
}

sub signal_name {
    my $num = shift;
    if ($num =~ /\D/) {
	return $num;
    }
    _load_signal_data();
    return $SIG_NAME[$num];
}

sub signal_number {
    my $name = shift;
    _load_signal_data();
    return $SIG_NO{$name};
}

# signal names that are normally instructions to terminate a program
# this list may need some work
my %_kill_sigs = (HUP => 1, INT => 1, QUIT => 1,
		  ILL => 1, ABRT => 1, KILL => 1,
		  SEGV => 1, TERM => 1, BREAK => 1,
                  ZERO => 0);
sub is_kill_signal {
    my ($sig) = @_;
    if ($sig !~ /\D/) {
	_load_signal_data();
	$sig = $SIG_NAME[$sig];
    }
    return defined($_kill_sigs{$sig}) ? $_kill_sigs{$sig} : 0;
}

sub is_stop_signal {
    my ($sig) = @_;
    if ($sig !~ /\D/) {
	_load_signal_data();
	$sig = $SIG_NAME[$sig];
    }
    return $sig eq 'STOP' || $sig eq 'TSTP' || $sig eq 'FREEZE' ||
	$sig eq 'TTIN' || $sig eq 'TTOU';
}

sub is_continue_signal {
    my ($sig) = @_;
    if ($sig !~ /\D/) {
	_load_signal_data();
	$sig = $SIG_NAME[$sig];
    }
    return $sig eq 'CONT' || $sig eq 'THAW';
}

sub _load_signal_data {
    return if @SIG_NAME > 0;
    use Config;
    @SIG_NAME = split / /, $Config{sig_name};
    my $i = 0;
    %SIG_NO = map { $_ => $i++ } @SIG_NAME;
    return;
}

sub _has_POSIX_signal_framework {
    return !&IS_WIN32; # XXX - incomplete, but covers the most important case
}

sub is_socket {
    my $handle = shift;

    return 1 if ref $handle eq 'REF';

#    if (&Forks::Super::Job::_INSIDE_END_QUEUE) {
#	return 1 if ref $handle eq 'REF';
#    }

    my $th = tied *$handle;
    if (ref($th)) {
	return 1 if $th->isa('Forks::Super::Tie::IPCSocketHandle');
	return 0 if $th->isa('Forks::Super::Tie::IPCFileHandle');
	return 0 if $th->isa('Forks::Super::Tie::IPCPipeHandle');
    }
    if (defined $$handle->{is_socket}) {
	return $$handle->{is_socket};
    }
    return defined getsockname($handle);
}

sub is_pipe {
    my $handle = shift;
    if (defined $$handle->{is_pipe}) {
	return $$handle->{is_pipe};
    }

    my $th = tied *$handle;
    if (ref($th)) {
	return 0 if $th->isa('Forks::Super::Tie::IPCFileHandle');
	return 0 if $th->isa('Forks::Super::Tie::IPCSocketHandle');
	return 1 if $th->isa('Forks::Super::Tie::IPCPipeHandle');
    }
    if (defined $handle->{std_delegate}) {
	$handle = $handle->{std_delegate};
    }
    return eval { $handle->opened } && -p $handle;
}

sub abs_path {
    # robust call to Cwd::abs_path
    # $dir may or may not exist
    my ($dir) = @_;
    return if !defined $dir;

    if ($] < 5.008 && ! -e $dir) {
	# poor man's Cwd::abs_path
	# may fail on non-unix, non-Windows platforms
	if ($dir =~ m{^(?:\w:)?[/\\]}) {
	    return $dir;
	} else {
	    my $cwd = Cwd::getcwd();
	    return $cwd . '/' . $dir;
	}
    }

    my $z = eval {
	my $dir2 = Cwd::abs_path($dir);
	if ($dir2 && $dir ne $dir2) {
	    $dir = $dir2;
	}
	1;
    };
    if (!$z) {
	if (&IS_WIN32) {
	    if ($dir !~ m{^[A-Za-z]:[/\\]}) {
		my $cwd = Cwd::getcwd();
		$dir = "$cwd/$dir";
	    }
	} elsif ($dir !~ m{^[/\\]}) {
	    my $cwd = Cwd::getcwd();
	    $dir = "$cwd/$dir";
	}
    }
    return $dir;
}

sub filter (&\@) {
    my ($filter, $list) = @_;
    my ($out,$re) = ([],[]);
    local $_;
    push @{$filter->() ? $out : $re}, $_ foreach @$list;
    @{$_[1]} = @$re;
    return @$out;
}

# shell quote for a single command-line argument on POSIX shells
sub shquote {  # borrowed heavily from String::ShellQuote 1.04
    local $_ = shift;
    return q{''} if !defined($_) || $_ eq '';
    s/\x00//g;   # no way to quote null bytes?
    if (m|[^\w!%+,\-./:=@^]|) {
        s/'/'\\''/g;
        s|((?:'\\''){2,})|q{'"} . (q{'} x (length($1) / 4)) . q{"'}|ge;
        $_ = qq{'$_'};
        s/^''//;
        s/''$//;
    }
    return $_;
}

# shell quote for a single command-line argument on MSWin32 cmd shell
sub cmdquote {
    # TODO
    @_;
}

sub okl {
    # pass a unit test automatically if $ENV{TEST_LENIENT} is set.
    # Use in special circumstances (e.g. high CPU load, flaky network)
    # for special tests (e.g., timing tests, external connectivity tests)
    # that might fail for reasons beyond your control.
    my ($condition,$message) = @_;
    $message ||= '';
    if ($ENV{TEST_LENIENT}) {
	if (!$condition) {
	    return Test::More::ok(1, "$message (LENIENT PASS)") && 0;
	} else {
	    return Test::More::ok(1, "$message (lenient)");
	}
    } else {
	return Test::More::ok($condition, $message);
    }
}

sub DEVNULL {
    &IS_WIN32 ? "nul" : "/dev/null";
}

sub DEVTTY {
    &IS_WIN32 ? "con" : "/dev/tty";
}

1;

=head1 NAME

Forks::Super::Util - utility routines for Forks::Super module

=head1 VERSION

0.93

=head1 SYNOPSIS

    use Forks::Super::Util qw(functions to import);
    use Forks::Super::Util qw(:all);

=head1 DESCRIPTION

A collection of useful and mostly unrelated routines for things
that the L<Forks::Super|Forks::Super> distribution needs to do.

=head1 SUBROUTINES

In alphabetical order.

=head2 $absolute_path = abs_path($relative_path)

Slightly more portable, slightly more robust, and slightly more
taint-resistant function to return the absolute path of a
specified file or directory. The input file need not exist.
If the input is already an absolute path and is not tainted,
then the output of this function will not be tainted, either.

=head2 Ctime

Returns a millisecond-resolution timestamp for the current time,
like C<14:38:19.018>; helpful for logging methods. If the
L<Time::HiRes|Time::HiRes> module is not available, the result will
show 0 in the milliseconds place, like C<14:38:19.000>.

=head2 @match = filter \&condition, @list

Returns the elements of a list that satisfy some condition
B<while removing those elements from the original list as
a side effect>. Like Perl's C<grep> and C<map> functions,
each element of the list will be loaded into C<$_> before
the code block is evaluated.
The C<@list> argument must be a named array.

Examples:

    @x = (1..10);
    @y = filter { $_ % 2 } @x;
    # result: @y => (1,3,5,7,9); @x => (0,2,4,6,8)

    # trivial passthru filter
    @x = @ARGV;
    @y = filter { 1 } @x;
    # result: @y => @ARGV; @x => ()


=head2 $bool = is_continue_signal($signal_name_or_number)

Returns true if the specified signal is generally used to
resume a suspended process. See L<"is_stop_signal">.

=head2 $bool = is_kill_signal($signal_name_or_number)

Returns true if the specified signal is I<generally> used to terminate
a process, for some vague definition of I<generally>.
See also L<"is_stop_signal"> and L<"is_continue_signal">.

=head2 $bool = is_number($scalar)

A ripoff of L<Scalar::Util/"looks_like_number"> to tell if a scalar
input is a number.

=head2 $bool = is_pipe($handle)

Returns true if, as far as the C<Forks::Super> module can tell,
the specified I/O handle is a pipe handle. See also L<"is_socket">.

=head2 $bool = is_socket($handle)

Returns true if, as far as the C<Forks::Super> module can tell,
the specified I/O handle is a socket handle. See also L<"is_pipe">.

=head2 $bool = is_stop_signal($signal_name_or_number)

Returns true if the specified signal is generally used to suspend
a process. See L<"is_continue_signal">.

=head2 isValidPid($pid)

Portable function call to check if the return value of L<Forks::Super/"fork">
is a valid process id (On Windows, forked processes are I<pseudo-processes>
with negative process identifiers, so the conventional C<< if ($pid > 0) ... >>
check is not portable).

Returns 0 when a L<Forks::Super/fork> call creates a "deferred" job
(see L<Forks::Super/"Deferred processes">).

=head2 pause($delay)

A B<productive> and B<interruption-resistant> drop-in replacement for
the builtin L<sleep|perlfunc/"sleep"> function or 
L<Time::HiRes::sleep|Time::HiRes/"sleep">. 

This function carries out "productive" tasks periodically while waiting
for the timer to expire. 

In programs that use L<Forks::Super|Forks::Super>,
the default "productive" behavior is to check for completed background
processes and to dispatch deferred jobs. On Windows systems that lack a
proper framework for handling C<SIGCHLD> framework, using this function
in place of C<sleep> is one of the best ways to make sure that completed
and deferred processes receive the attention they need. You can override
the default behavior by passing a code reference to the
L<"set_productive_pause_code"> function.

Since the "productive" code could take an arbitrarily long time to execute,
the actual delay can be longer, and sometimes much longer, than the
requested delay.

The return value of this function is the estimated number of seconds
that the function actually waited.

=head2 $qualified_name = qualify_sub_name($unqualified_sub_name_or_code_ref)

Prepends a package qualifier from the current context, if necessary,
from current execution context of a scalar subroutine name. Used when
an unqualified subroutine name is passed in any L<Forks::Super|Forks::Super>
function argument that expects a code reference.

    package Foo;
    sub do_something_in_background { ... }

    # invokes Forks::Super::Util::qualify_sub_name 
    $job = fork { sub => 'do_something_in_background' };
    print $job->{sub};   # ---> Foo::do_something_in_background

=head2 set_productive_pause_code($coderef)

Specifies the code that the L<"pause"> method should run during
down time. In most L<Forks::Super|Forks::Super> programs, the default 
will be to check if running processes have completed and to manage tasks
in the job queue.

Can be called with an C<undef> argument to disable productive
code during L<"pause"> calls.

=head2 $signal_name = signal_name($signal_number)

Returns the canonical name of a signal (e.g., C<TERM>) that is associated
with the given signal number (say, C<15>). See also L<"signal_number">.
Returns C<undef> for a signal number that is out of the valid range
for your system.

=head2 $signal_number = signal_number($signal_name)

Returns the number of a signal (say, C<15>) that is associated with the 
given signal name (say, C<TERM>). Returns C<undef> for an unrecognized
signal name.


=head1 SEE ALSO

L<Forks::Super|Forks::Super>

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2018, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
