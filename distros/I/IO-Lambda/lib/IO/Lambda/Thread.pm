# $Id: Thread.pm,v 1.25 2010/03/27 19:51:24 dk Exp $
package IO::Lambda::Thread;
use base qw(IO::Lambda);
use strict;
use warnings;
use Exporter;
use Socket;
use IO::Handle;
use IO::Lambda qw(:all :dev swap_frame);

our $DISABLED;
eval { require threads; };
$DISABLED = $@ if $@;

our $DEBUG = $IO::Lambda::DEBUG{thread};

our @EXPORT_OK = qw(threaded new_thread);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub _d { "threaded(" . _o($_[0]) . ")" }

sub thread_init
{
	my ( $r, $cb, $pass_handle, @param) = @_;

	$SIG{KILL} = sub { threads-> exit(0) };
	$SIG{PIPE} = 'IGNORE';
	eval "END { IO::Lambda::__end(); };";
	warn "thread(", threads->tid, ") started\n" if $DEBUG;

	my @ret;
	eval { @ret = $cb-> (( $pass_handle ? $r : ()), @param) if $cb };

	warn "thread(", threads->tid, ") ended: [@ret]\n" if $DEBUG;
	close($r);
	undef $r;
	die $@ if $@;

	return @ret;
}

sub new_thread
{
	return undef, $DISABLED if $DISABLED;

	my ( @args, $cb, $pass_handle, @param);
	@args = shift if $_[0] and ref($_[0]) and ref($_[0]) eq 'HASH';
	( $cb, $pass_handle, @param) = @_;
	
	my $r = IO::Handle-> new;
	my $w = IO::Handle-> new;
	socketpair( $r, $w, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
	$w-> blocking(0);

	my ($t) = threads-> create(
		@args,
		\&thread_init, 
		$r, $cb, $pass_handle, @param
	);

	close($r);

	warn "new thread(", $t->tid, ")\n" if $DEBUG;
	return ($t, $w);
}

# overridden IO::Lambda methods

sub DESTROY
{
	my $self = shift;

	return if defined($self->{tid}) and $self->{tid} != threads-> tid;

	close($self->{socket}) if $self-> {socket};
	delete @{$self}{qw(socket thread)};

	$self-> SUPER::DESTROY;
}

sub thread { $_[0]-> {thread} }
sub socket { $_[0]-> {socket} }

sub threaded(&)
{
	my $cb = shift;

	# use overridden IO::Lambda, because we need 
	# give the caller a chance to join
	# for it, if the lambda gets terminated
	__PACKAGE__-> new( sub { 
		# Save context. This is needed because the caller
		# may have his own this. lambda(&) does the same
		# protection
		my $this  = shift;
		my @frame = swap_frame($this);

		warn _d($this), " started\n" if $DEBUG;

		# can start a thread?
		my ( $t, $r) = new_thread( $cb, 1 );
		return $r unless $t;

		# save this
		$this-> {tid}    = threads-> tid;
		$this-> {thread} = $t;
		$this-> {socket} = $r;

		# now wait
		context $this-> {socket};
		readable {
			my $this = this;
			delete $this-> {thread};
			close($this-> {socket});
			delete @{$this}{qw(socket thread)};
			$this-> clear;
			warn _d($this), " joining\n" if $DEBUG;
			$t-> join;
		};

		# restore context
		swap_frame(@frame);
	});
}

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::Thread - wait for blocking code using threads

=head1 DESCRIPTION

The module implements a lambda wrapper that allows to asynchronously wait for
a blocking code. The wrapping is done so that the code is executed in another
thread's context. C<IO::Lambda::Thread> provides bidirectional communication
between threads, that is based on a shared socket between parent and child
threads. The socket can be also used by the caller for its own needs, if necessary
( see L<IO::Lambda::Message> ).

=head1 SYNOPSIS

    use IO::Lambda qw(:lambda);
    use IO::Lambda::Thread qw(threaded);

    lambda {
        context 0.1, threaded {
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

=head1 API

=over

=item new_thread ( $options = (), $code, $pass_socket, @param) -> ($thread, $socket)

A special replacement for C<< thread-> create >>, that not only creates a
thread, but also creates a socket between the parent and child threads. The
socket is important for getting an asynchronous notification when the child
thread has finished, because there is no portable way to get that signal
otherwise. That means that this socket must be closed and the thread must be
C<join>'ed to avoid problems. For example:
    
    my ( $thread, $reader) = new_thread( $sub {
        my $writer = shift;
        print $writer, "Hello world!\n";
    }, 1 );
    print while <$reader>;
    close($reader);
    $thread-> join;

Note that C<join> is a blocking call, so one needs to be sure that the thread
indeed is finished before joining it. By default, the child thread closes
its side of the socket, thus making the parent side readable. However, the
child code can also hijack the socket for its own needs, so if that
functionality is needed, one must create an extra layer of communication that
ensures that the child code is properly exited, so that the parent can
reliably call C<join> without blocking (see L<IO::Lambda::Message>, that 
is destined exactly for this use).

C<$code> is executed in another thread's context, and is passed the communication
socket ( if C<$pass_socket> is set to 1 ). C<$code> is also passed C<@param>.
Data returned from the code can be retrieved from C<join>.

=item threaded($code) :: () -> ( @results )

Creates a lambda, that executes C<$code> in a newly created thread.
The lambda finishes when the C<$code> and the thread are finished,
and returns results returned by C<$code>.

Note, that this lambda, if C<terminate>'d between after being started and
before being finished, has no chance to wait for completion of the
associated thread, and so Perl will complain. To deal with that, obtain the
thread object manually and wait for the thread:

    my $l = threaded { 42 };
    $l-> start;
    ....
    $l-> terminate;

    # synchronously
    $l-> thread-> join;

    # or asynchronously
    context $l-> socket;
    readable { $l-> thread-> join };

=item thread($lambda)

Returns the associated thread object. Valid only for lambdas created with
C<threaded>.

=item socket($lambda)

Returns the associated communication socket. Valid only for lambdas created
with C<threaded>. 

=back

=head1 BUGS

=over

=item Unbalanced string table refcount

Threading in Perl is fragile, so errors like the following:

   Unbalanced string table refcount: (1) for "GEN1" during global
   destruction

are due to some obscure Perl bugs. They are triggered, in my experience, when a
child thread tries to deallocate scalars that it thinks belongs to that thread.
This can be sometimes avoided with explicit cleaning up of scalars that may be
visible in threads.  For example, calls as

   IO::Lambda::clear

and

   undef $my_lambda; # or other scalars, whatever

inexplicably hush these errors.

=item Perl exited with active threads

Errors like this

  Perl exited with active threads:
        1 running and unjoined
        0 finished and unjoined
        0 running and detached

are triggered when child threads weren't properly joined. Make sure
your lambdas are finished properly. Use C<env IO_LAMBDA_DEBUG=thread>
to find out the details.

=item Scalars leaked: 1

This is a known bug, f.ex. L<http://rt.perl.org/rt3//Public/Bug/Display.html?id=70974>
suggests adding the C<@_ = ();> construct at random places as a workaround.

=item panic: del_backref during global destruction

This is a known bug, L<http://rt.perl.org/rt3/Ticket/Display.html?id=70748> .
I observed in on win32 only. No workaround is known however.

=item AnyEvent

AnyEvent doesn't work with threads, so this module most probably won't
work too when AnyEvent is selected for IO::Lambda::Loop.

=back

=head1 SEE ALSO

L<IO::Lambda>, L<threads>.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
