# $Id: Fork.pm,v 1.12 2010/02/09 08:40:41 dk Exp $

package IO::Lambda::Fork;

use base qw(IO::Lambda);

our $DEBUG = $IO::Lambda::DEBUG{fork} || 0;
	
use strict;
use warnings;
use Exporter;
use Socket;
use POSIX;
use Storable qw(thaw freeze);
use IO::Handle;
use IO::Lambda qw(:all :dev);
use IO::Lambda::Signal qw(pid);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(new_process process new_forked forked);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub _d { "forked(" . _o($_[0]) . ")" }

# return pid and socket
sub new_process(&)
{
	my $cb = shift;
	
	my $r = IO::Handle-> new;
	my $w = IO::Handle-> new;
	socketpair( $r, $w, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
	$w-> blocking(0);

	my $pid = fork;
	unless ( defined $pid) {
		warn "fork() failed:$!\n" if $DEBUG;
		close($w);
		close($r);
		return ( undef, $! );
	}

	if ( $pid == 0) {
		close($w);
		warn "process($$) started\n" if $DEBUG;
		eval { $cb-> ($r) if $cb; };
		warn "process($$) ended\n" if $DEBUG;
		warn $@ if $@;
		close($r);
		POSIX::exit($@ ? 1 : 0);
	}
		
	warn "forked pid=$pid\n" if $DEBUG;

	close($r);

	return ($pid, $w);
}

# simple fork, return only $? and $!
sub process(&)
{
	my $cb = shift;

	lambda { 
		my $pid = fork;
		return undef, $! unless defined $pid;
		unless ( $pid) {
			warn "process($$) started\n" if $DEBUG;
			eval { $cb->(); };
			warn "process($$) ended\n" if $DEBUG;
			warn $@ if $@;
			POSIX::exit($@ ? 1 : 0);
		}

		warn "forked pid=$pid\n" if $DEBUG;
		context $pid;
		&pid();
	}
	
}

# return output from a subprocess
sub new_forked(&)
{
	my $cb = shift;

	my ( $pid, $r) = new_process {
		my @ret;
		my $socket = shift;
		eval { @ret = $cb-> () if $cb };
		my $msg = $@ ? [ 0, $@ ] : [ 1, @ret ];
		warn "process($$) ended: [@$msg]\n" if $DEBUG > 1;
		print $socket freeze($msg);
	};

	lambda {
		return undef, undef, $r unless defined $pid;
	
		my $buf = '';
		context readbuf, $r, \ $buf, undef;
	tail {
		my ( $ok, $error) = @_;
		my @ret;

		($ok,$error) = (0,$!) unless close($r);

		unless ( $ok) {
			@ret = ( undef, $error);
		} else {
			my $msg;
			eval { $msg = thaw $buf };
			unless ( $msg and ref($msg) and ref($msg) eq 'ARRAY') {
				@ret = ( undef, $@);
			} elsif ( 0 == shift @$msg) {
				@ret = ( undef, @$msg);
			} else {
				@ret = ( 1, @$msg);
			}
		}

		context $pid;
	pid {
		warn "pid($pid): exitcode=$?, [@ret]\n" if $DEBUG > 1;
		return shift, @ret;
	}}}
}

# simpler version of new_forked
sub forked(&)
{
	my $cb = shift;
	lambda {
		context &new_forked($cb);
	tail {
		my ( $pid, $ok, @ret) = @_;
		return @ret;
	}}
}

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::Fork - wait for blocking code in children processes

=head1 DESCRIPTION

The module implements the lambda wrapper that allows to wait asynchronously for
blocking code in another process' context. C<IO::Lambda::Fork> provides a
twofold interface for that: the lambda interface, that can wait for the forked
child processes, and an easier way for simple communication between these.

Contrary to the classical stdin-stdout interaction between parent and child
processes, this module establishes a stream socket and uses it instead. The
socket can also be used by the caller for its own needs ( see
L<IO::Lambda::Message> ).

=head1 SYNOPSIS

    use IO::Lambda qw(:lambda);
    use IO::Lambda::Fork qw(forked);

Blocking wait

    lambda {
        context forked {
	    sleep(1);
	    return "hello!";
	};
	tail {
	    print shift, "\n"
	}
    }-> wait;

    # hello!

Non-blocking wait

    lambda {
        context 0.1, forked {
	      sleep(1);
	      return "hello!";
	};
        any_tail {
            if ( @_) {
                print "done: ", $_[0]-> peek, "\n";
            } else {
                print "not yet\n";
                again;
            }
        };
    }-> wait;

    # not yet
    # not yet
    # not yet
    # done: hello!

(of course, since IO::Lambda is inherently non-blocking, the first example is of much more
use, as many of such "blocking" lambdas can execute in parallel)

=head1 API

=over

=item new_process($code, $pass_socket, @param) -> ( $pid, $socket | undef, $error )

Forks a process, and sets up a read-write socket between the parent and the
child. On success, returns the child's pid and the socket, where the latter is
passed further to C<$code>. On failure, returns undef and C<$!>.

This function does not create a lambda, neither makes any preparations for
waiting for the child process, nor for reaping its status. It is therefore
important for the caller itself to wait for the child process, to avoid zombie
processes. That can be done either synchronously:

    my ( $pid, $reader) = new_process {
        my $writer = shift;
        print $writer, "Hello world!\n";
    };
    print while <$reader>;
    close($reader);
    waitpid($pid, 0);

or asynchronously, using C<waitpid> wrappers from C<IO::Lambda::Socket>:

    use IO::Lambda::Signal qw(pid new_pid);
    ...
    lambda { context $pid; &pid() }-> wait;
    # or
    new_pid($pid)-> wait;

=item process($code) :: () -> ($? | undef)

Creates a simple lambda that forks a process and executes C<$code> inside it.
The lambda returns the child exit code.

=item new_forked($code) :: () -> ( $?, ( 1, @results | undef, $error))

Creates a lambda that awaits for C<$code> in a sub-process to be executed, then
returns the code' result back to the parent. Returns also the process exitcode,
C<$code> eval success flag, and an array of code results or an error string, if
any.

=item forked($code) :: () -> (@results | $error)

A simple wrapper over C<new_forked>, that returns either C<$code> results
or an error string.

=back

=head1 BUGS

Doesn't work on Win32, because relies on C<$SIG{CHLD}> which is not getting
delivered (on 5.10.0 at least). However, since Win32 doesn't have forks anyway,
Perl emulates them with threads. Consider using L<IO::Lambda::Thread> instead
when running on windows.

Has issues with SIGCHLD on perls < 5.8.0.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
