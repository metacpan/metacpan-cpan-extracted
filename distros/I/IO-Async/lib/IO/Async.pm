#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2013 -- leonerd@leonerd.org.uk

package IO::Async;

use strict;
use warnings;

# This package contains no code other than a declaration of the version.
# It is provided simply to keep CPAN happy:
#   cpan -i IO::Async

our $VERSION = '0.77';

=head1 NAME

C<IO::Async> - Asynchronous event-driven programming

=head1 SYNOPSIS

 use IO::Async::Stream;
 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new;

 $loop->connect(
    host     => "some.other.host",
    service  => 12345,
    socktype => 'stream',

    on_stream => sub {
       my ( $stream ) = @_;

       $stream->configure(
          on_read => sub {
             my ( $self, $buffref, $eof ) = @_;

             while( $$buffref =~ s/^(.*\n)// ) {
                print "Received a line $1";
             }

             return 0;
          }
       );

       $stream->write( "An initial line here\n" );

       $loop->add( $stream );
    },

    on_resolve_error => sub { die "Cannot resolve - $_[-1]\n"; },
    on_connect_error => sub { die "Cannot connect - $_[0] failed $_[-1]\n"; },
 );

 $loop->run;

=head1 DESCRIPTION

This collection of modules allows programs to be written that perform
asynchronous filehandle IO operations. A typical program using them would
consist of a single subclass of L<IO::Async::Loop> to act as a container of
other objects, which perform the actual IO work required by the program. As
well as IO handles, the loop also supports timers and signal handlers, and
includes more higher-level functionality built on top of these basic parts.

Because there are a lot of classes in this collection, the following overview
gives a brief description of each.

=head2 Notifiers

The base class of all the event handling subclasses is L<IO::Async::Notifier>.
It does not perform any IO operations itself, but instead acts as a base class
to build the specific IO functionality upon. It can also coordinate a
collection of other Notifiers contained within it, forming a tree structure.

The following sections describe particular types of Notifier.

=head2 File Handle IO

An L<IO::Async::Handle> object is a Notifier that represents a single IO handle
being managed. While in most cases it will represent a single filehandle, such
as a socket (for example, an L<IO::Socket::INET> connection), it is possible
to have separate reading and writing handles (most likely for a program's
C<STDIN> and C<STDOUT> streams, or a pair of pipes connected to a child
process).

The L<IO::Async::Stream> class is a subclass of L<IO::Async::Handle> which
maintains internal incoming and outgoing data buffers. In this way, it
implements bidirectional buffering of a byte stream, such as a TCP socket. The
class automatically handles reading of incoming data into the incoming buffer,
and writing of the outgoing buffer. Methods or callbacks are used to inform
when new incoming data is available, or when the outgoing buffer is empty.

While stream-based sockets can be handled using using L<IO::Async::Stream>,
datagram or raw sockets do not provide a bytestream. For these, the
L<IO::Async::Socket> class is another subclass of L<IO::Async::Handle> which
maintains an outgoing packet queue, and informs of packet receipt using a
callback or method.

The L<IO::Async::Listener> class is another subclass of L<IO::Async::Handle>
which facilitates the use of C<listen(2)>-mode sockets. When a new connection
is available on the socket it will C<accept(2)> it and pass the new client
socket to its callback function.

=head2 Timers

An L<IO::Async::Timer::Absolute> object represents a timer that expires at a
given absolute time in the future.

An L<IO::Async::Timer::Countdown> object represents a count time timer, which
will invoke a callback after a given delay. It can be stopped and restarted.

An L<IO::Async::Timer::Periodic> object invokes a callback at regular intervals
from its initial start time. It is reliable and will not drift due to the time
taken to run the callback.

The L<IO::Async::Loop> also supports methods for managing timed events on a
lower level. Events may be absolute, or relative in time to the time they are
installed.

=head2 Signals

An L<IO::Async::Signal> object represents a POSIX signal, which will invoke a
callback when the given signal is received by the process. Multiple objects
watching the same signal can be used; they will all invoke in no particular
order.

=head2 Processes Management

An L<IO::Async::PID> object invokes its event when a given child process
exits. An L<IO::Async::Process> object can start a new child process running
either a given block of code, or executing a given command, set up pipes on
its filehandles, write to or read from these pipes, and invoke its event when
the child process exits.

=head2 Loops

The L<IO::Async::Loop> object class represents an abstract collection of
L<IO::Async::Notifier> objects, and manages the actual filehandle IO
watchers, timers, signal handlers, and other functionality. It performs all
of the abstract collection management tasks, and leaves the actual OS
interactions to a particular subclass for the purpose.

L<IO::Async::Loop::Poll> uses an L<IO::Poll> object for this test.

L<IO::Async::Loop::Select> uses the C<select(2)> syscall.

Other subclasses of loop may appear on CPAN under their own dists; see the
L</SEE ALSO> section below for more detail.

As well as these general-purpose classes, the L<IO::Async::Loop> constructor
also supports looking for OS-specific subclasses, in case a more efficient
implementation exists for the specific OS it runs on.

=head2 Child Processes

The L<IO::Async::Loop> object provides a number of methods to facilitate the
running of child processes. C<spawn_child> is primarily a wrapper around the
typical C<fork(2)>/C<exec(2)> style of starting child processes, and
C<run_child> provide a method similar to perl's C<readpipe> (which is used
to implement backticks C<``>).

=head2 File Change Watches

The L<IO::Async::File> object observes changes to C<stat(2)> properties of a
file, directory, or other filesystem object. It invokes callbacks when
properties change. This is used by L<IO::Async::FileStream> which presents
the same events as a L<IO::Async::Stream> but operates on a regular file on
the filesystem, observing it for updates.

=head2 Asynchronous Co-routines and Functions

The C<IO::Async> framework generally provides mechanisms for multiplexing IO
tasks between different handles, so there aren't many occasions when it is
necessary to run code in another thread or process. Two cases where this does
become useful are when:

=over 4

=item *

A large amount of computationally-intensive work needs to be performed.

=item * 

An OS or library-level function needs to be called, that will block, and
no asynchronous version is supplied.

=back

For these cases, an instance of L<IO::Async::Function> can be used around
a code block, to execute it in a worker child process or set of processes.
The code in the sub-process runs isolated from the main program, communicating
only by function call arguments and return values. This can be used to solve
problems involving state-less library functions.

An L<IO::Async::Routine> object wraps a code block running in a separate
process to form a kind of co-routine. Communication with it happens via
L<IO::Async::Channel> objects. It can be used to solve any sort of problem
involving keeping a possibly-stateful co-routine running alongside the rest of
an asynchronous program.

=head2 Futures

An L<IO::Async::Future> object represents a single outstanding action that is
yet to complete, such as a name resolution operation or a socket connection.
It stands in contrast to a L<IO::Async::Notifier>, which is an object that
represents an ongoing source of activity, such as a readable filehandle of
bytes or a POSIX signal.

Futures are a recent addition to the C<IO::Async> API and details are still
subject to change and experimentation.

In general, methods that support Futures return a new Future object to
represent the outstanding operation. If callback functions are supplied as
well, these will be fired in addition to the Future object becoming ready. Any
failures that are reported will, in general, use the same conventions for the
Future's C<fail> arguments to relate it to the legacy C<on_error>-style
callbacks.

 $on_NAME_error->( $message, @argmuents )

 $f->fail( $message, NAME, @arguments )

where C<$message> is a message intended for humans to read (so that this is
the message displayed by C<< $f->get >> if the failure is not otherwise
caught), C<NAME> is the name of the failing operation. If the failure is due
to a failed system call, the value of C<$!> will be the final argument. The
message should not end with a linefeed.

=head2 Networking

The L<IO::Async::Loop> provides several methods for performing network-based
tasks. Primarily, the C<connect> and C<listen> methods allow the creation of
client or server network sockets. Additionally, the C<resolve> method allows
the use of the system's name resolvers in an asynchronous way, to resolve
names into addresses, or vice versa. These methods are fully IPv6-capable if
the underlying operating system is.

=head2 Protocols

The L<IO::Async::Protocol> class provides storage for a L<IO::Async::Handle>
object, to act as a transport for some protocol. It allows a level of
independence from the actual transport being for that protocol, allowing it to
be easily reused. The L<IO::Async::Protocol::Stream> subclass provides further
support for protocols based on stream connections, such as TCP sockets.

=head1 TODO

This collection of modules is still very much in development. As a result,
some of the potentially-useful parts or features currently missing are:

=over 4

=item *

Consider further ideas on Solaris' I<ports>, BSD's I<Kevents> and anything that
might be useful on Win32.

=item *

Consider some form of persistent object wrapper in the form of an
C<IO::Async::Object>, based on L<IO::Async::Routine>.

=item *

C<IO::Async::Protocol::Datagram>

=item *

Support for watching filesystem entries for change. Extract logic from
L<IO::Async::File> and define a Loop watch/unwatch method pair.

=item *

Define more L<Future>-returning methods. Consider also one-shot Futures on
things like L<IO::Async::Process> exits, or L<IO::Async::Handle> close.

=back

=head1 SUPPORT

Bugs may be reported via RT at

 https://rt.cpan.org/Public/Dist/Display.html?Name=IO-Async

Support by IRC may also be found on F<irc.perl.org> in the F<#io-async>
channel.

=cut

=head1 SEE ALSO

As well as the two loops supplied in this distribution, many more exist on
CPAN. At the time of writing this includes:

=over 4

=item *

L<IO::Async::Loop::AnyEvent> - use IO::Async with AnyEvent

=item *

L<IO::Async::Loop::Epoll> - use IO::Async with epoll on Linux

=item *

L<IO::Async::Loop::Event> - use IO::Async with Event

=item *

L<IO::Async::Loop::EV> - use IO::Async with EV

=item *

L<IO::Async::Loop::Glib> - use IO::Async with Glib or GTK

=item *

L<IO::Async::Loop::KQueue> - use IO::Async with kqueue

=item *

L<IO::Async::Loop::Mojo> - use IO::Async with Mojolicious

=item *

L<IO::Async::Loop::POE> - use IO::Async with POE

=item *

L<IO::Async::Loop::Ppoll> - use IO::Async with ppoll(2)

=back

Additionally, some other event loops or modules also support being run on top
of C<IO::Async>:

=over 4

=item *

L<AnyEvent::Impl::IOAsync> - AnyEvent adapter for IO::Async

=item * 

L<Gungho::Engine::IO::Async> - IO::Async Engine

=item *

L<POE::Loop::IO_Async> - IO::Async event loop support for POE

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
