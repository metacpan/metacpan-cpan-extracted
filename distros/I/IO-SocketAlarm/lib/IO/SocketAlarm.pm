package IO::SocketAlarm;
$IO::SocketAlarm::VERSION = '0.001';
# VERSION
# ABSTRACT: Perform asynchronous actions when a socket changes status

use strict;
use warnings;
use Carp;
use Scalar::Util ();
require XSLoader;
XSLoader::load('IO::SocketAlarm', $IO::SocketAlarm::VERSION);

# All exports are part of the Util sub-package.
package IO::SocketAlarm::Util {
   our @EXPORT_OK= qw( socketalarm get_fd_table_str is_socket );
   use Exporter 'import';
   # Declared in XS
}
$IO::SocketAlarm::Util::VERSION = '0.001';

sub import {
   splice(@_, 0, 1, 'IO::SocketAlarm::Util');
   goto \&IO::SocketAlarm::Util::import;
}


sub new {
   my $class= shift;
   my %attrs= @_ == 1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_;
   my $self= bless \%attrs, $class;
   $self->_init_socketalarm(@attrs{'socket','events','actions'});
}


sub triggered { $_[0]->cur_action >= 0 }
sub finished { $_[0]->cur_action >= $_[0]->action_count }


# Before global destruction, de-activate the alarms and ask the watcher thread to terminate.
# This way bizarre things don't happen when global destruction starts calling destructors
# in the wrong order.
END { _terminate_all() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::SocketAlarm - Perform asynchronous actions when a socket changes status

=head1 SYNOPSIS

  use IO::SocketAlarm qw( socketalarm :events );
  use POSIX ':signal_h';
  
  local $SIG{ALRM}= sub { die "got alarm"; };
  # When the client goes away, send SIGALRM
  my $alarm= socketalarm($socket);
  ...
  $alarm->cancel;  # stop receiving signal
  
  # More extreme example: when client goes away, terminate
  # the current worker process and also kill the mysql query.
  my $mysql_conn_id= $dbh->selectcoll_arrayref("SELECT CONNECTION_ID()")->[0];
  my $alarm= socketalarm($socket, [ exec => 'mysql', -e => "kill $mysql_conn_id" ]);

=head1 DESCRIPTION

Sometimes you have a blocking system call, or blocking library, and it prevents you from
checking whether the initiator of this request (like a http client) is still waiting for the
answer.  The right way to solve the problem is an event loop, where you are waiting both for
the long-tunning task and also watching for events on the client connection and your program
can respond to either of them.  Perl has several great event loops, like L<Mojo::IOLoop>,
L<AnyEvent>, or L<IO::Async> with which you can build a properly engineered solution.
But... if you don't have the luxury of refactoring your whole project to be event-driven, and
you'd really just like a way to kill the current HTTP worker when the client is lost and you're
blocking in a long-running database call, this module is for you.

This module operates by creating a second C-level thread (regardless of whether your perl was
compiled with threading support) and having that thread monitor the status of your socket.

B<First caveat:> The background thread is limited in the types of actions it can take.
For example, you definitely can't run perl code in response to the status change, but it can
send a signal to the main thread, or other process-global actions like completely exiting and
executing C<< mysql -e "kill $conn_id" >>.

B<Second caveat:> This module's design isn't 100% portable beyond Linux and FreeBSD. On Windows,
MacOS, and OpenBSD there is no way (that I've found) to poll for TCP 'FIN' status.  This module
will probably still work for a HTTP worker behind a reverse proxy; see L</EVENT_EOF> below.

B<Third caveat:> While the module is thread-safe, per-se, it does introduce the sorts of
confusion caused by concurrency, like checking C<< $alarm->triggered >> and having that status
change before the very next line of code in your script.

B<Fourth caveat:> The signals you send to yourself won't take effect until control returns to
the perl interpreter.  If you are blocking in a C library or XS, it might be that the only
way to wake it up is to close the file handles it is using.  For DBD::mysql and libmysql, that
doesn't even work because of mysql_auto_reconnect, and besides which, mysql servers don't
notice that clients are gone until the current query ends.  Stopping a long-running mysql query
can (seemingly) only be accomplished by running SQL on the server.

=head1 EXPORTS

This module exports everything from L<IO::SocketAlarm::Util>.  Of particular note:

=head2 socketalarm

  $alarm= socketalarm($socket); # sends SIGALRM when EVENT_SHUT
  $alarm= socketalarm($socket, @actions);
  $alarm= socketalarm($socket, $event_mask, @actions);

This creates a new alarm on C<$socket>, waiting for C<$event_mask> to occur, and if it does,
a background thread will run C<@actions>.  It is a shortcut for L<new|/new> as follows:

  $alarm= IO::SocketAlarm->new(
    socket => $socket,
    events => $event_mask,
    actions => \@actions,
  );

=head1 ALARM OBJECT

An Alarm object represents the scope of the alarm.  You can undefine it or call
C<< $alarm->cancel >> to disable the alarm, but beware that you might have a race condition
between letting it go out of scope and letting your local signal handler go out of scope, so
use the same precautions that you would use when using C<alarm()>.

When triggered, the alarm only runs its actions once.

=head2 Constructor

=head3 new

=head2 Attributes

=head3 socket

The C<$socket> must be an operating system level socket (having a 'fileno', as opposed to a
Perl virtual handle of some sort), and still be open.

=head3 events

This is a bit-mask of which events to trigger on.  Combine them with the bitwise-or operator:

  # the default on Linux/FreeBSD:
  events => EVENT_SHUT,
  # the default on Windows/Mac/OpenBSD
  events => EVENT_SHUT|EVENT_EOF,

=over

=item EVENT_SHUT

Triggers when the TCP connection is being shutdown (the TCP "FIN" flag) or any detectable
condition that means communication on the socket is no longer possible and is the result of an
external event.

While this event is the whole point of this module, there actually isn't a good cross-platform
way to identify this condition!  Linux and FreeBSD provide a reliable POLLRDHUP flag to poll()
to get notified of the TCP 'FIN' flag, but on OpenBSD and Mac and Windows the best you can do
is check for a zero-length "peek" on the socket, which only works if the application has already
read all incoming data on the socket.  (but this works for typical HTTP worker pools where only
one request will be sent from the reverse proxy to the worker, before closing the connection)

The poll() POLLHUP flag also triggers this event, for socket types (or pipes) that emit this
flag in a useful manner.

=item EVENT_EOF

Triggers when the file handle indicates EOF by a successful zero-length read.  This is checked
by performing a C<< recv(sock, buf, len, MSG_PEEK|MSG_DONTWAIT) >> so that no actual data is
removed from the socket.  If your peer writes data to the socket before closing it, you won't
get this event until you read that data.  There is no efficient way to wait for this event when
the peer has sent additional data; this module falls back to checking at short intervals in that
case, which is inefficient and may fail to deliver the event when you need it delivered.

But again, this generally works in a HTTP worker pool where this module is intended to be used.

=item EVENT_IN

Triggers if there is any data available to be read from the socket.  This sets the POLLIN flag
on the call to poll().

=item EVENT_PRI

Triggers if there is any priority data available to be read from the socket.  This sets the
POLLPRI flag on the call to poll().

=item EVENT_CLOSE

Triggers when another thread on this application has called "close" on the socket file handle.
More specifically, it triggers when "stat()" fails or reports a different device or inode for
the file descriptor, indicating that descriptor number has been closed or recycled.

(it is a better idea to make sure you cancel the alarm before returning to any code which might
 close your end of the socket)

=back

=head3 actions

  # the default:
  actions => [ [ sig => SIGALRM ] ],

The C<@actions> are an array of one or more action specifications.  When the C<$events> are
detected, this list will be performed in sequence.  The actions are described as simple
lisp-like arrayrefs. (you can't just specify a coderef for an action because they run in a
separate C thread that isn't able to touch the perl interpreter.)

The available actions are:

=over

=item sig

  [ sig => $signal ],

Send yourself a signal. The signal constants come from C<< use POSIX ':signal_h'; >>.

=item kill

  [ kill => $signal, $pid ],

Send a signal to any process.  Note the order of arguments: this is the same as Perl and bash,
but the opposite of the C library, and a mixup can be bad!

=item close

  [ close => 5, ... ]
  [ close => $fh, ... ]
  [ close => pack_sockaddr_in($port, inet_aton("localhost")), ... ]

Close one or more file descriptors or socket names.  This could have uses like killing database
connections when you know the file handle number or host:port of the database server.

If the parameter is an integer, it is assumed to be a raw file descriptor number like you get
from C<fileno>.  If the parameter is an IO::Handle, it calls C<fileno> for you, and croaks if
that handle isn't backed by a real file descriptor.  The parameter can also be a byte string
as per the C<getpeername> or C<pack_sockaddr_in> functions; in this case B<all> sockets
connected to that peer name will be closed.

=item shut_r, shut_w, shut_rw

  [ shut_r => $fd_or_sockname, ... ],
  [ shut_w => $fd_or_sockname, ... ],
  [ shut_rw => $fd_or_sockname, ... ],

Like C<close>, but instead of calling C<close(fd)> it calls the socket function
C<< shutdown(fd, $how) >> where C<$how> is one of C<SHUT_RD>, C<SHUT_RW>, C<SHUT_RDWR>.
This leaves the socket open, but causes reads or writes to fail, which may give a more graceful
cancellation of whatever was happening over that socket.

=item run

  [ run => @argv ],

Fork (twice) and exec an external program.  The program shares your STDOUT and STDERR, but is
connected to /dev/null on STDIN.  The double-fork (and reap of first forked child) allows the
(grand)child process to run independently from the current process, and get reaped by C<init>,
and not tangle up whatever you might be doing with C<waitpid>.  If the C<exec> fails, it is
reported on C<STDERR>, but the current process has no way to inspect the outcome of the C<exec>
or the exit status of the program it runs.

=item exec

  [ exec => @argv ],

Replace the current running process with a different process, just like C<exec>.  This
completely aborts the main perl script and loses any work, without calling 'atexit' or any
other cleanup your perl script might have intended to do.  Sometimes, this is what you want,
though.  This can fail if C<< $argv[0] >> isn't found in the PATH, in which case your program
just immediately C<exit>s.

=item sleep

  [ sleep => $seconds ],

Wait before running the next action.

=back

=head3 cur_action

Returns -1 if the alarm is not yet triggered, else the number of the action being executed,
ending with the integer beyond the max element of L</actions>.  Note that by the time your
script reads this attribute, it may already have changed.

=head2 action_count

Shortcut for C<< scalar @{actions} >>, but avoids inflating the arrayref of actions.

=head3 triggered

Shortcut for C<< $cur_action == -1 >>

=head3 finished

Shortcut for C<< $cur_action > $#actions >>

=head2 Methods

=head3 start

Begin listening for the alarm events.  Returns a boolean of whether the alarm was inactive
prior to this call. (i.e. whether the call changed the state of the alarm)

=head3 cancel

Stop listening for the alarm events.  Returns a boolean of whether the alarm was active prior
to this call.  (i.e. whether the call changed the state of the alarm)

=head3 stringify

Render the alarm as user-readable text, for diagnosis and logging.

=head1 VERSION

version 0.001

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
