#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2020 -- leonerd@leonerd.org.uk

package IO::Async::Loop;

use strict;
use warnings;

our $VERSION = '0.77';

# When editing this value don't forget to update the docs below
use constant NEED_API_VERSION => '0.33';

# Base value but some classes might override
use constant _CAN_ON_HANGUP => 0;

# Most Loop implementations do not accurately handle sub-second timers.
# This only matters for unit tests
use constant _CAN_SUBSECOND_ACCURATELY => 0;

# Does the loop implementation support IO_ASYNC_WATCHDOG?
use constant _CAN_WATCHDOG => 0;

# Watchdog configuration constants
use constant WATCHDOG_ENABLE   => $ENV{IO_ASYNC_WATCHDOG};
use constant WATCHDOG_INTERVAL => $ENV{IO_ASYNC_WATCHDOG_INTERVAL} || 10;
use constant WATCHDOG_SIGABRT  => $ENV{IO_ASYNC_WATCHDOG_SIGABRT};

use Carp;

use Time::HiRes qw(); # empty import
use POSIX qw( WNOHANG );
use Scalar::Util qw( refaddr weaken );
use Socket qw( SO_REUSEADDR AF_INET6 IPPROTO_IPV6 IPV6_V6ONLY );

use IO::Async::OS;
use IO::Async::Metrics '$METRICS';

use constant HAVE_SIGNALS => IO::Async::OS->HAVE_SIGNALS;
use constant HAVE_POSIX_FORK => IO::Async::OS->HAVE_POSIX_FORK;
use constant HAVE_THREADS => IO::Async::OS->HAVE_THREADS;

# Never sleep for more than 1 second if a signal proxy is registered, to avoid
# a borderline race condition.
# There is a race condition in perl involving signals interacting with XS code
# that implements blocking syscalls. There is a slight chance a signal will
# arrive in the XS function, before the blocking itself. Perl will not run our
# (safe) deferred signal handler in this case. To mitigate this, if we have a
# signal proxy, we'll adjust the maximal timeout. The signal handler will be 
# run when the XS function returns. 
our $MAX_SIGWAIT_TIME = 1;

# Also, never sleep for more than 1 second if the OS does not support signals
# and we have child watches registered (so we must use waitpid() polling)
our $MAX_CHILDWAIT_TIME = 1;

# Maybe our calling program will have a suggested hint of a specific Loop
# class or list of classes to use
our $LOOP;

# Undocumented; used only by the test scripts.
# Setting this value true will avoid the IO::Async::Loop::$^O candidate in the
# magic constructor
our $LOOP_NO_OS;

# SIGALRM handler for watchdog
$SIG{ALRM} = sub {
   # There are two extra frames here; this one and the signal handler itself
   local $Carp::CarpLevel = $Carp::CarpLevel + 2;
   if( WATCHDOG_SIGABRT ) {
      print STDERR Carp::longmess( "Watchdog timeout" );
      kill ABRT => $$;
   }
   else {
      Carp::confess( "Watchdog timeout" );
   }
} if WATCHDOG_ENABLE;

# There are two default values that might apply; undef or "DEFAULT"
$SIG{PIPE} = "IGNORE" if ( $SIG{PIPE} || "DEFAULT" ) eq "DEFAULT";

=head1 NAME

C<IO::Async::Loop> - core loop of the C<IO::Async> framework

=head1 SYNOPSIS

 use IO::Async::Stream;
 use IO::Async::Timer::Countdown;

 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new;

 $loop->add( IO::Async::Timer::Countdown->new(
    delay => 10,
    on_expire => sub { print "10 seconds have passed\n" },
 )->start );

 $loop->add( IO::Async::Stream->new_for_stdin(
    on_read => sub {
       my ( $self, $buffref, $eof ) = @_;

       while( $$buffref =~ s/^(.*)\n// ) {
          print "You typed a line $1\n";
       }

       return 0;
    },
 ) );

 $loop->run;

=head1 DESCRIPTION

This module provides an abstract class which implements the core loop of the
L<IO::Async> framework. Its primary purpose is to store a set of
L<IO::Async::Notifier> objects or subclasses of them. It handles all of the
lower-level set manipulation actions, and leaves the actual IO readiness 
testing/notification to the concrete class that implements it. It also
provides other functionality such as signal handling, child process managing,
and timers.

See also the two bundled Loop subclasses:

=over 4

=item L<IO::Async::Loop::Select>

=item L<IO::Async::Loop::Poll>

=back

Or other subclasses that may appear on CPAN which are not part of the core
L<IO::Async> distribution.

=head2 Ignoring SIGPIPE

Since version I<0.66> loading this module automatically ignores C<SIGPIPE>, as
it is highly unlikely that the default-terminate action is the best course of
action for an L<IO::Async>-based program to take. If at load time the handler
disposition is still set as C<DEFAULT>, it is set to ignore. If already
another handler has been placed there by the program code, it will be left
undisturbed.

=cut

# Internal constructor used by subclasses
sub __new
{
   my $class = shift;

   # Detect if the API version provided by the subclass is sufficient
   $class->can( "API_VERSION" ) or
      die "$class is too old for IO::Async $VERSION; it does not provide \->API_VERSION\n";

   $class->API_VERSION >= NEED_API_VERSION or
      die "$class is too old for IO::Async $VERSION; we need API version >= ".NEED_API_VERSION.", it provides ".$class->API_VERSION."\n";

   WATCHDOG_ENABLE and !$class->_CAN_WATCHDOG and
      warn "$class cannot implement IO_ASYNC_WATCHDOG\n";

   my $self = bless {
      notifiers     => {}, # {nkey} = notifier
      iowatches     => {}, # {fd} = [ $on_read_ready, $on_write_ready, $on_hangup ]
      sigattaches   => {}, # {sig} => \@callbacks
      childmanager  => undef,
      childwatches  => {}, # {pid} => $code
      threadwatches => {}, # {tid} => $code
      timequeue     => undef,
      deferrals     => [],
      os            => {}, # A generic scratchpad for IO::Async::OS to store whatever it wants
   }, $class;

   $METRICS and $METRICS->inc_gauge( loops => [ class => ref $self ] );

   # It's possible this is a specific subclass constructor. We still want the
   # magic IO::Async::Loop->new constructor to yield this if it's the first
   # one
   our $ONE_TRUE_LOOP ||= $self;

   # Legacy support - temporary until all CPAN classes are updated; bump NEEDAPI version at that point
   my $old_timer = $self->can( "enqueue_timer" ) != \&enqueue_timer;
   if( $old_timer != ( $self->can( "cancel_timer" ) != \&cancel_timer ) ) {
      die "$class should overload both ->enqueue_timer and ->cancel_timer, or neither";
   }

   if( $old_timer ) {
      warnings::warnif( deprecated => "Enabling old_timer workaround for old loop class " . $class );
   }

   $self->{old_timer} = $old_timer;

   return $self;
}

sub DESTROY
{
   my $self = shift;

   $METRICS and $METRICS->dec_gauge( loops => [ class => ref $self ] );
}

=head1 MAGIC CONSTRUCTOR

=head2 new

   $loop = IO::Async::Loop->new

This function attempts to find a good subclass to use, then calls its
constructor. It works by making a list of likely candidate classes, then
trying each one in turn, C<require>ing the module then calling its C<new>
method. If either of these operations fails, the next subclass is tried. If
no class was successful, then an exception is thrown.

The constructed object is cached, and will be returned again by a subsequent
call. The cache will also be set by a constructor on a specific subclass. This
behaviour makes it possible to simply use the normal constructor in a module
that wishes to interact with the main program's Loop, such as an integration
module for another event system.

For example, the following two C<$loop> variables will refer to the same
object:

 use IO::Async::Loop;
 use IO::Async::Loop::Poll;

 my $loop_poll = IO::Async::Loop::Poll->new;

 my $loop = IO::Async::Loop->new;

While it is not advised to do so under normal circumstances, if the program
really wishes to construct more than one Loop object, it can call the
constructor C<really_new>, or invoke one of the subclass-specific constructors
directly.

The list of candidates is formed from the following choices, in this order:

=over 4

=item * $ENV{IO_ASYNC_LOOP}

If this environment variable is set, it should contain a comma-separated list
of subclass names. These names may or may not be fully-qualified; if a name
does not contain C<::> then it will have C<IO::Async::Loop::> prepended to it.
This allows the end-user to specify a particular choice to fit the needs of
his use of a program using L<IO::Async>.

=item * $IO::Async::Loop::LOOP

If this scalar is set, it should contain a comma-separated list of subclass
names. These may or may not be fully-qualified, as with the above case. This
allows a program author to suggest a loop module to use.

In cases where the module subclass is a hard requirement, such as GTK programs
using C<Glib>, it would be better to use the module specifically and invoke
its constructor directly.

=item * IO::Async::OS->LOOP_PREFER_CLASSES

The L<IO::Async::OS> hints module for the given OS is then consulted to see if
it suggests any other module classes specific to the given operating system.

=item * $^O

The module called C<IO::Async::Loop::$^O> is tried next. This allows specific
OSes, such as the ever-tricky C<MSWin32>, to provide an implementation that
might be more efficient than the generic ones, or even work at all.

This option is now discouraged in favour of the L<IO::Async::OS> hint instead.
At some future point it may be removed entirely, given as currently only
C<linux> uses it.

=item * Poll and Select

Finally, if no other choice has been made by now, the built-in C<Poll> module
is chosen. This should always work, but in case it doesn't, the C<Select>
module will be chosen afterwards as a last-case attempt. If this also fails,
then the magic constructor itself will throw an exception.

=back

If any of the explicitly-requested loop types (C<$ENV{IO_ASYNC_LOOP}> or
C<$IO::Async::Loop::LOOP>) fails to load then a warning is printed detailing
the error.

Implementors of new C<IO::Async::Loop> subclasses should see the notes about
C<API_VERSION> below.

=cut

sub __try_new
{
   my ( $class ) = @_;

   ( my $file = "$class.pm" ) =~ s{::}{/}g;

   eval {
      local $SIG{__WARN__} = sub {};
      require $file;
   } or return;

   my $self;
   $self = eval { $class->new } and return $self;

   # Oh dear. We've loaded the code OK but for some reason the constructor
   # wasn't happy. Being polite we ought really to unload the file again,
   # but perl doesn't actually provide us a way to do this.

   return undef;
}

sub new
{
   return our $ONE_TRUE_LOOP ||= shift->really_new;
}

# Ensure that the loop is DESTROYed recursively at exit time, before GD happens
END {
   undef our $ONE_TRUE_LOOP;
}

sub really_new
{
   shift;  # We're going to ignore the class name actually given
   my $self;

   my @candidates;

   push @candidates, split( m/,/, $ENV{IO_ASYNC_LOOP} ) if defined $ENV{IO_ASYNC_LOOP};

   push @candidates, split( m/,/, $LOOP ) if defined $LOOP;

   foreach my $class ( @candidates ) {
      $class =~ m/::/ or $class = "IO::Async::Loop::$class";
      $self = __try_new( $class ) and return $self;

      my ( $topline ) = split m/\n/, $@; # Ignore all the other lines; they'll be require's verbose output
      warn "Unable to use $class - $topline\n";
   }

   unless( $LOOP_NO_OS ) {
      foreach my $class ( IO::Async::OS->LOOP_PREFER_CLASSES, "IO::Async::Loop::$^O" ) {
         $class =~ m/::/ or $class = "IO::Async::Loop::$class";
         $self = __try_new( $class ) and return $self;

         # Don't complain about these ones
      }
   }

   return IO::Async::Loop->new_builtin;
}

sub new_builtin
{
   shift;
   my $self;

   foreach my $class ( IO::Async::OS->LOOP_BUILTIN_CLASSES ) {
      $self = __try_new( "IO::Async::Loop::$class" ) and return $self;
   }

   croak "Cannot find a suitable candidate class";
}

#######################
# Notifier management #
#######################

=head1 NOTIFIER MANAGEMENT

The following methods manage the collection of L<IO::Async::Notifier> objects.

=cut

=head2 add

   $loop->add( $notifier )

This method adds another notifier object to the stored collection. The object
may be a L<IO::Async::Notifier>, or any subclass of it.

When a notifier is added, any children it has are also added, recursively. In
this way, entire sections of a program may be written within a tree of
notifier objects, and added or removed on one piece.

=cut

sub add
{
   my $self = shift;
   my ( $notifier ) = @_;

   if( defined $notifier->parent ) {
      croak "Cannot add a child notifier directly - add its parent";
   }

   if( defined $notifier->loop ) {
      croak "Cannot add a notifier that is already a member of a loop";
   }

   $self->_add_noparentcheck( $notifier );
}

sub _add_noparentcheck
{
   my $self = shift;
   my ( $notifier ) = @_;

   my $nkey = refaddr $notifier;

   $self->{notifiers}->{$nkey} = $notifier;
   $METRICS and $METRICS->inc_gauge( notifiers => );

   $notifier->__set_loop( $self );

   $self->_add_noparentcheck( $_ ) for $notifier->children;

   return;
}

=head2 remove

   $loop->remove( $notifier )

This method removes a notifier object from the stored collection, and
recursively and children notifiers it contains.

=cut

sub remove
{
   my $self = shift;
   my ( $notifier ) = @_;

   if( defined $notifier->parent ) {
      croak "Cannot remove a child notifier directly - remove its parent";
   }

   $self->_remove_noparentcheck( $notifier );
}

sub _remove_noparentcheck
{
   my $self = shift;
   my ( $notifier ) = @_;

   my $nkey = refaddr $notifier;

   exists $self->{notifiers}->{$nkey} or croak "Notifier does not exist in collection";

   delete $self->{notifiers}->{$nkey};
   $METRICS and $METRICS->dec_gauge( notifiers => );

   $notifier->__set_loop( undef );

   $self->_remove_noparentcheck( $_ ) for $notifier->children;

   return;
}

=head2 notifiers

   @notifiers = $loop->notifiers

Returns a list of all the notifier objects currently stored in the Loop.

=cut

sub notifiers
{
   my $self = shift;
   # Sort so the order remains stable under additions/removals
   return map { $self->{notifiers}->{$_} } sort keys %{ $self->{notifiers} };
}

###################
# Looping support #
###################

=head1 LOOPING CONTROL

The following methods control the actual run cycle of the loop, and hence the
program.

=cut

=head2 loop_once

   $count = $loop->loop_once( $timeout )

This method performs a single wait loop using the specific subclass's
underlying mechanism. If C<$timeout> is undef, then no timeout is applied, and
it will wait until an event occurs. The intention of the return value is to
indicate the number of callbacks that this loop executed, though different
subclasses vary in how accurately they can report this. See the documentation
for this method in the specific subclass for more information.

=cut

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   croak "Expected that $self overrides ->loop_once";
}

=head2 run

   @result = $loop->run

   $result = $loop->run

Runs the actual IO event loop. This method blocks until the C<stop> method is
called, and returns the result that was passed to C<stop>. In scalar context
only the first result is returned; the others will be discarded if more than
one value was provided. This method may be called recursively.

This method is a recent addition and may not be supported by all the
C<IO::Async::Loop> subclasses currently available on CPAN.

=cut

sub run
{
   my $self = shift;

   local $self->{running} = 1;
   local $self->{result} = [];

   while( $self->{running} ) {
      $self->loop_once( undef );
   }

   return wantarray ? @{ $self->{result} } : $self->{result}[0];
}

=head2 stop

   $loop->stop( @result )

Stops the inner-most C<run> method currently in progress, causing it to return
the given C<@result>.

This method is a recent addition and may not be supported by all the
C<IO::Async::Loop> subclasses currently available on CPAN.

=cut

sub stop
{
   my $self = shift;

   @{ $self->{result} } = @_;
   undef $self->{running};
}

=head2 loop_forever

   $loop->loop_forever

A synonym for C<run>, though this method does not return a result.

=cut

sub loop_forever
{
   my $self = shift;
   $self->run;
   return;
}

=head2 loop_stop

   $loop->loop_stop

A synonym for C<stop>, though this method does not pass any results.

=cut

sub loop_stop
{
   my $self = shift;
   $self->stop;
}

=head2 post_fork

   $loop->post_fork

The base implementation of this method does nothing. It is provided in case
some Loop subclasses should take special measures after a C<fork()> system
call if the main body of the program should survive in both running processes.

This may be required, for example, in a long-running server daemon that forks
multiple copies on startup after opening initial listening sockets. A loop
implementation that uses some in-kernel resource that becomes shared after
forking (for example, a Linux C<epoll> or a BSD C<kqueue> filehandle) would
need recreating in the new child process before the program can continue.

=cut

sub post_fork
{
   my $self = shift;

   IO::Async::OS->post_fork( $self );
}

###########
# Futures #
###########

=head1 FUTURE SUPPORT

The following methods relate to L<IO::Async::Future> objects.

=cut

=head2 new_future

   $future = $loop->new_future

Returns a new L<IO::Async::Future> instance with a reference to the Loop.

=cut

sub new_future
{
   my $self = shift;
   require IO::Async::Future;
   return IO::Async::Future->new( $self );
}

=head2 await

   $loop->await( $future )

Blocks until the given future is ready, as indicated by its C<is_ready> method.
As a convenience it returns the future, to simplify code:

 my @result = $loop->await( $future )->get;

=cut

sub await
{
   my $self = shift;
   my ( $future ) = @_;

   $self->loop_once until $future->is_ready;

   return $future;
}

=head2 await_all

   $loop->await_all( @futures )

Blocks until all the given futures are ready, as indicated by the C<is_ready>
method. Equivalent to calling C<await> on a C<< Future->wait_all >> except
that it doesn't create the surrounding future object.

=cut

sub _all_ready { $_->is_ready or return 0 for @_; return 1  }

sub await_all
{
   my $self = shift;
   my @futures = @_;

   $self->loop_once until _all_ready @futures;
}

=head2 delay_future

   $loop->delay_future( %args )->get

Returns a new L<IO::Async::Future> instance which will become done at a given
point in time. The C<%args> should contain an C<at> or C<after> key as per the
C<watch_time> method. The returned future may be cancelled to cancel the
timer. At the alloted time the future will succeed with an empty result list.

=cut

sub delay_future
{
   my $self = shift;
   my %args = @_;

   my $future = $self->new_future;
   my $id = $self->watch_time( %args,
      code => sub { $future->done },
   );

   $future->on_cancel( sub { shift->loop->unwatch_time( $id ) } );

   return $future;
}

=head2 timeout_future

   $loop->timeout_future( %args )->get

Returns a new L<IO::Async::Future> instance which will fail at a given point
in time. The C<%args> should contain an C<at> or C<after> key as per the
C<watch_time> method. The returned future may be cancelled to cancel the
timer. At the alloted time, the future will fail with the string C<"Timeout">.

=cut

sub timeout_future
{
   my $self = shift;
   my %args = @_;

   my $future = $self->new_future;
   my $id = $self->watch_time( %args,
      code => sub { $future->fail( "Timeout" ) },
   );

   $future->on_cancel( sub { shift->loop->unwatch_time( $id ) } );

   return $future;
}

############
# Features #
############

=head1 FEATURES

Most of the following methods are higher-level wrappers around base
functionality provided by the low-level API documented below. They may be
used by L<IO::Async::Notifier> subclasses or called directly by the program.

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

sub __new_feature
{
   my $self = shift;
   my ( $classname ) = @_;

   ( my $filename = "$classname.pm" ) =~ s{::}{/}g;
   require $filename;

   # These features aren't supposed to be "user visible", so if methods called
   # on it carp or croak, the shortmess line ought to skip IO::Async::Loop and
   # go on report its caller. To make this work, add the feature class to our
   # @CARP_NOT list.
   push our(@CARP_NOT), $classname;

   return $classname->new( loop => $self );
}

=head2 attach_signal

   $id = $loop->attach_signal( $signal, $code )

This method adds a new signal handler to watch the given signal. The same
signal can be attached to multiple times; its callback functions will all be
invoked, in no particular order.

The returned C<$id> value can be used to identify the signal handler in case
it needs to be removed by the C<detach_signal> method. Note that this value
may be an object reference, so if it is stored, it should be released after it
is cancelled, so the object itself can be freed.

=over 8

=item $signal

The name of the signal to attach to. This should be a bare name like C<TERM>.

=item $code

A CODE reference to the handling callback.

=back

Attaching to C<SIGCHLD> is not recommended because of the way all child
processes use it to report their termination. Instead, the C<watch_process>
method should be used to watch for termination of a given child process. A
warning will be printed if C<SIGCHLD> is passed here, but in future versions
of L<IO::Async> this behaviour may be disallowed altogether.

See also L<POSIX> for the C<SIGI<name>> constants.

For a more flexible way to use signals from within Notifiers, see instead the
L<IO::Async::Signal> object.

=cut

sub attach_signal
{
   my $self = shift;
   my ( $signal, $code ) = @_;

   HAVE_SIGNALS or croak "This OS cannot ->attach_signal";

   if( $signal eq "CHLD" ) {
      # We make special exception to allow $self->watch_process to do this
      caller eq "IO::Async::Loop" or
         carp "Attaching to SIGCHLD is not advised - use ->watch_process instead";
   }

   if( not $self->{sigattaches}->{$signal} ) {
      my @attaches;
      $self->watch_signal( $signal, sub {
         foreach my $attachment ( @attaches ) {
            $attachment->();
         }
      } );
      $self->{sigattaches}->{$signal} = \@attaches;
   }

   push @{ $self->{sigattaches}->{$signal} }, $code;

   return \$self->{sigattaches}->{$signal}->[-1];
}

=head2 detach_signal

   $loop->detach_signal( $signal, $id )

Removes a previously-attached signal handler.

=over 8

=item $signal

The name of the signal to remove from. This should be a bare name like
C<TERM>.

=item $id

The value returned by the C<attach_signal> method.

=back

=cut

sub detach_signal
{
   my $self = shift;
   my ( $signal, $id ) = @_;

   HAVE_SIGNALS or croak "This OS cannot ->detach_signal";

   # Can't use grep because we have to preserve the addresses
   my $attaches = $self->{sigattaches}->{$signal} or return;

   for (my $i = 0; $i < @$attaches; ) {
      $i++, next unless \$attaches->[$i] == $id;

      splice @$attaches, $i, 1, ();
   }

   if( !@$attaches ) {
      $self->unwatch_signal( $signal );
      delete $self->{sigattaches}->{$signal};
   }
}

=head2 later

   $loop->later( $code )

Schedules a code reference to be invoked as soon as the current round of IO
operations is complete.

The code reference is never invoked immediately, though the loop will not
perform any blocking operations between when it is installed and when it is
invoked. It may call C<select>, C<poll> or equivalent with a zero-second
timeout, and process any currently-pending IO conditions before the code is
invoked, but it will not block for a non-zero amount of time.

This method is implemented using the C<watch_idle> method, with the C<when>
parameter set to C<later>. It will return an ID value that can be passed to
C<unwatch_idle> if required.

=cut

sub later
{
   my $self = shift;
   my ( $code ) = @_;

   return $self->watch_idle( when => 'later', code => $code );
}

=head2 spawn_child

   $loop->spawn_child( %params )

This method creates a new child process to run a given code block or command.
The C<%params> hash takes the following keys:

=over 8

=item command => ARRAY or STRING

Either a reference to an array containing the command and its arguments, or a
plain string containing the command. This value is passed into perl's
C<exec> function.

=item code => CODE

A block of code to execute in the child process. It will be called in scalar
context inside an C<eval> block.

=item setup => ARRAY

A reference to an array which gives file descriptors to set up in the child
process before running the code or command. See below.

=item on_exit => CODE

A continuation to be called when the child processes exits. It will be invoked
in the following way:

 $on_exit->( $pid, $exitcode, $dollarbang, $dollarat )

The second argument is passed the plain perl C<$?> value.

=back

Exactly one of the C<command> or C<code> keys must be specified.

If the C<command> key is used, the given array or string is executed using the
C<exec> function. 

If the C<code> key is used, the return value will be used as the C<exit(2)>
code from the child if it returns (or 255 if it returned C<undef> or thows an
exception).

 Case          | ($exitcode >> 8)       | $dollarbang | $dollarat
 --------------+------------------------+-------------+----------
 exec succeeds | exit code from program |     0       |    ""
 exec fails    |         255            |     $!      |    ""
 $code returns |     return value       |     $!      |    ""
 $code dies    |         255            |     $!      |    $@

It is usually more convenient to use the C<open_process> method in simple
cases where an external program is being started in order to interact with it
via file IO, or even C<run_child> when only the final result is required,
rather than interaction while it is running.

=head3 C<setup> array

This array gives a list of file descriptor operations to perform in the child
process after it has been C<fork(2)>ed from the parent, before running the code
or command. It consists of name/value pairs which are ordered; the operations
are performed in the order given.

=over 8

=item fdI<n> => ARRAY

Gives an operation on file descriptor I<n>. The first element of the array
defines the operation to be performed:

=over 4

=item [ 'close' ]

The file descriptor will be closed.

=item [ 'dup', $io ]

The file descriptor will be C<dup2(2)>ed from the given IO handle.

=item [ 'open', $mode, $file ]

The file descriptor will be opened from the named file in the given mode. The
C<$mode> string should be in the form usually given to the C<open> function;
such as '<' or '>>'.

=item [ 'keep' ]

The file descriptor will not be closed; it will be left as-is.

=back

A non-reference value may be passed as a shortcut, where it would contain the
name of the operation with no arguments (i.e. for the C<close> and C<keep>
operations).

=item IO => ARRAY

Shortcut for passing C<fdI<n>>, where I<n> is the fileno of the IO
reference. In this case, the key must be a reference that implements the
C<fileno> method. This is mostly useful for

 $handle => 'keep'

=item fdI<n> => IO

A shortcut for the C<dup> case given above.

=item stdin => ...

=item stdout => ...

=item stderr => ...

Shortcuts for C<fd0>, C<fd1> and C<fd2> respectively.

=item env => HASH

A reference to a hash to set as the child process's environment.

Note that this will entirely set a new environment, completely replacing the
existing one. If you want to simply add new keys or change the values of some
keys without removing the other existing ones, you can simply copy C<%ENV>
into the hash before setting new keys:

 env => {
    %ENV,
    ANOTHER => "key here",
 }

=item nice => INT

Change the child process's scheduling priority using C<POSIX::nice>.

=item chdir => STRING

Change the child process's working directory using C<chdir>.

=item setuid => INT

=item setgid => INT

Change the child process's effective UID or GID.

=item setgroups => ARRAY

Change the child process's groups list, to those groups whose numbers are
given in the ARRAY reference.

On most systems, only the privileged superuser change user or group IDs.
L<IO::Async> will B<NOT> check before detaching the child process whether
this is the case.

If setting both the primary GID and the supplementary groups list, it is
suggested to set the primary GID first. Moreover, some operating systems may
require that the supplementary groups list contains the primary GID.

=back

If no directions for what to do with C<stdin>, C<stdout> and C<stderr> are
given, a default of C<keep> is implied. All other file descriptors will be
closed, unless a C<keep> operation is given for them.

If C<setuid> is used, be sure to place it after any other operations that
might require superuser privileges, such as C<setgid> or opening special
files.

Z<>

   my ( $pipeRd, $pipeWr ) = IO::Async::OS->pipepair;
   $loop->spawn_child(
      command => "/usr/bin/my-command",

      setup => [
         stdin  => [ "open", "<", "/dev/null" ],
         stdout => $pipeWr,
         stderr => [ "open", ">>", "/var/log/mycmd.log" ],
         chdir  => "/",
      ]

      on_exit => sub {
         my ( $pid, $exitcode ) = @_;
         my $status = ( $exitcode >> 8 );
         print "Command exited with status $status\n";
      },
   );

   $loop->spawn_child(
      code => sub {
         do_something; # executes in a child process
         return 1;
      },

      on_exit => sub {
         my ( $pid, $exitcode, $dollarbang, $dollarat ) = @_;
         my $status = ( $exitcode >> 8 );
         print "Child process exited with status $status\n";
         print " OS error was $dollarbang, exception was $dollarat\n";
      },
   );

=cut

sub spawn_child
{
   my $self = shift;
   my %params = @_;

   my $childmanager = $self->{childmanager} ||=
      $self->__new_feature( "IO::Async::Internals::ChildManager" );

   $childmanager->spawn_child( %params );
}

=head2 open_process

   $process = $loop->open_process( %params )

I<Since version 0.72.>

This creates a new child process to run the given code block or command, and
attaches filehandles to it that the parent will watch. This method is a light
wrapper around constructing a new L<IO::Async::Process> object, adding it to
the loop, and returning it.

The C<%params> hash is passed directly to the L<IO::Async::Process>
constructor.

=cut

sub open_process
{
   my $self = shift;
   my %params = @_;

   $params{on_exit} and croak "Cannot pass 'on_exit' parameter through ->open_process";

   require IO::Async::Process;
   my $process = IO::Async::Process->new( %params );

   $self->add( $process );

   return $process;
}

=head2 open_child

   $pid = $loop->open_child( %params )

A back-compatibility wrapper to calling L</open_process> and returning the PID
of the newly-constructed L<IO::Async::Process> instance. The C<on_finish>
continuation likewise will be invoked with the PID rather than the process
instance.

   $on_finish->( $pid, $exitcode )

Similarly, a C<on_error> continuation is accepted, though note its arguments
come in a different order to those of the Process's C<on_exception>:

   $on_error->( $pid, $exitcode, $errno, $exception )

This method should not be used in new code; instead use L</open_process>
directly.

=cut

sub open_child
{
   my $self = shift;
   my %params = @_;

   my $on_finish = delete $params{on_finish};
   ref $on_finish or croak "Expected 'on_finish' to be a reference";
   $params{on_finish} = sub {
      my ( $process, $exitcode ) = @_;
      $on_finish->( $process->pid, $exitcode );
   };

   if( my $on_error = delete $params{on_error} ) {
      ref $on_error or croak "Expected 'on_error' to be a reference";

      $params{on_exception} = sub {
         my ( $process, $exception, $errno, $exitcode ) = @_;
         # Swap order
         $on_error->( $process->pid, $exitcode, $errno, $exception );
      };
   }

   return $self->open_process( %params )->pid;
}

=head2 run_process

   @results = $loop->run_process( %params )->get

   ( $exitcode, $stdout ) = $loop->run_process( ... )->get  # by default

I<Since version 0.73.>

Creates a new child process to run the given code block or command, optionally
capturing its STDOUT and STDERR streams. By default the returned future will
yield the exit code and content of the STDOUT stream, but the C<capture>
argument can be used to alter what is requested and returned.

=over 8

=item command => ARRAY or STRING

=item code => CODE

The command or code to run in the child process (as per the C<spawn_child>
method)

=item stdin => STRING

Optional. String to pass in to the child process's STDIN stream.

=item setup => ARRAY

Optional reference to an array to pass to the underlying C<spawn> method.

=item capture => ARRAY

Optional reference to an array giving a list of names of values which should
be returned by resolving future. Values will be returned in the same order as
in the list. Valid choices are: C<exitcode>, C<stdout>, C<stderr>.

=item cancel_signal => STRING

Optional. Name (or number) of the signal to send to the process if the
returned future is cancelled. Defaults to C<TERM>. Use empty string or zero
disable sending a signal on cancellation.

=item fail_on_nonzero => BOOL

Optional. If true, the returned future will fail if the process exits with a
nonzero status. The failure will contain a message, the C<process> category
name, and the capture values that were requested.

   Future->fail( $message, process => @captures )

=back

This method is intended mainly as an IO::Async-compatible replacement for the
perl C<readpipe> function (`backticks`), allowing it to replace

   my $output = `command here`;

with

   my ( $exitcode, $output ) = $loop->run_process(
      command => "command here", 
   )->get;

Z<>

   my ( $exitcode, $stdout ) = $loop->run_process(
      command => "/bin/ps",
   )->get;

   my $status = ( $exitcode >> 8 );
   print "ps exited with status $status\n";

=cut

sub _run_process
{
   my $self = shift;
   my %params = @_;

   $params{on_finish} and croak "Unrecognised parameter on_finish";

   my $capture = delete $params{capture} // [qw(exitcode stdout)];
   ref $capture eq "ARRAY" or croak "Expected 'capture' to be an array reference";

   my %subparams;
   my %results;

   if( my $child_stdin = delete $params{stdin} ) {
      ref $child_stdin and croak "Expected 'stdin' not to be a reference";
      $subparams{stdin} = { from => $child_stdin };
   }

   foreach (qw( code command setup notifier_name )) {
      $subparams{$_} = delete $params{$_};
   }

   foreach my $name ( @$capture ) {
      grep { $_ eq $name } qw( exitcode stdout stderr ) or croak "Unexpected capture $name";

      $subparams{stdout} = { into => \$results{stdout} } if $name eq "stdout";
      $subparams{stderr} = { into => \$results{stderr} } if $name eq "stderr";
   }

   my $cancel_signal = delete $params{cancel_signal} // "TERM";

   my $fail_on_nonzero = delete $params{fail_on_nonzero};

   croak "Unrecognised parameters " . join( ", ", keys %params ) if keys %params;

   my $future = $self->new_future;

   require IO::Async::Process;
   my $process = IO::Async::Process->new(
      %subparams,
      on_finish => sub {
         ( undef, $results{exitcode} ) = @_;

         if( $fail_on_nonzero and $results{exitcode} > 0 ) {
            $future->fail( "Process failed with exit code $results{exitcode}\n",
               process => @results{ @$capture }
            );
         }
         else {
            $future->done( @results{ @$capture } );
         }
      },
   );

   $future->on_cancel(sub {
      $process->kill( $cancel_signal );
   }) if $cancel_signal;

   $self->add( $process );

   return ( $future, $process );
}

sub run_process
{
   my $self = shift;
   return ( $self->_run_process( @_ ) )[0];
}

=head2 run_child

   $pid = $loop->run_child( %params )

A back-compatibility wrapper for L</run_process>, returning the PID and taking
an C<on_finish> continuation instead of returning a Future.

This creates a new child process to run the given code block or command,
capturing its STDOUT and STDERR streams. When the process exits, a
continuation is invoked being passed the exitcode, and content of the streams.

Takes the following named arguments in addition to those taken by
C<run_process>:

=over 8

=item on_finish => CODE

A continuation to be called when the child process exits and closed its STDOUT
and STDERR streams. It will be invoked in the following way:

 $on_finish->( $pid, $exitcode, $stdout, $stderr )

The second argument is passed the plain perl C<$?> value.

=back

This method should not be used in new code; instead use L</run_process>
directly.

=cut

sub run_child
{
   my $self = shift;
   my %params = @_;

   my $on_finish = delete $params{on_finish};
   ref $on_finish or croak "Expected 'on_finish' to be a reference";

   my ( $f, $process ) = $self->_run_process(
      %params,
      capture => [qw( exitcode stdout stderr )],
   );
   my $pid = $process->pid;

   $f->on_done( sub {
      undef $f; # capture cycle
      $on_finish->( $pid, @_ );
   });

   return $pid;
}

=head2 resolver

   $loop->resolver

Returns the internally-stored L<IO::Async::Resolver> object, used for name
resolution operations by the C<resolve>, C<connect> and C<listen> methods.

=cut

sub resolver
{
   my $self = shift;

   return $self->{resolver} ||= do {
      require IO::Async::Resolver;
      my $resolver = IO::Async::Resolver->new;
      $self->add( $resolver );
      $resolver;
   }
}

=head2 set_resolver

   $loop->set_resolver( $resolver )

Sets the internally-stored L<IO::Async::Resolver> object. In most cases this
method should not be required, but it may be used to provide an alternative
resolver for special use-cases.

=cut

sub set_resolver
{
   my $self = shift;
   my ( $resolver ) = @_;

   $resolver->can( $_ ) or croak "Resolver is unsuitable as it does not implement $_"
      for qw( resolve getaddrinfo getnameinfo );

   $self->{resolver} = $resolver;

   $self->add( $resolver );
}

=head2 resolve

   @result = $loop->resolve( %params )->get

This method performs a single name resolution operation. It uses an
internally-stored L<IO::Async::Resolver> object. For more detail, see the
C<resolve> method on the L<IO::Async::Resolver> class.

=cut

sub resolve
{
   my $self = shift;
   my ( %params ) = @_;

   $self->resolver->resolve( %params );
}

=head2 connect

   $handle|$socket = $loop->connect( %params )->get

This method performs a non-blocking connection to a given address or set of
addresses, returning a L<IO::Async::Future> which represents the operation. On
completion, the future will yield the connected socket handle, or the given
L<IO::Async::Handle> object.

There are two modes of operation. Firstly, a list of addresses can be provided
which will be tried in turn. Alternatively as a convenience, if a host and
service name are provided instead of a list of addresses, these will be
resolved using the underlying loop's C<resolve> method into the list of
addresses.

When attempting to connect to any among a list of addresses, there may be
failures among the first attempts, before a valid connection is made. For
example, the resolver may have returned some IPv6 addresses, but only IPv4
routes are valid on the system. In this case, the first C<connect(2)> syscall
will fail. This isn't yet a fatal error, if there are more addresses to try,
perhaps some IPv4 ones.

For this reason, it is possible that the operation eventually succeeds even
though some system calls initially fail. To be aware of individual failures,
the optional C<on_fail> callback can be used. This will be invoked on each
individual C<socket(2)> or C<connect(2)> failure, which may be useful for
debugging or logging.

Because this module simply uses the C<getaddrinfo> resolver, it will be fully
IPv6-aware if the underlying platform's resolver is. This allows programs to
be fully IPv6-capable.

In plain address mode, the C<%params> hash takes the following keys:

=over 8

=item addrs => ARRAY

Reference to an array of (possibly-multiple) address structures to attempt to
connect to. Each should be in the layout described for C<addr>. Such a layout
is returned by the C<getaddrinfo> named resolver.

=item addr => HASH or ARRAY

Shortcut for passing a single address to connect to; it may be passed directly
with this key, instead of in another array on its own. This should be in a
format recognised by L<IO::Async::OS>'s C<extract_addrinfo> method.

This example shows how to use the C<Socket> functions to construct one for TCP
port 8001 on address 10.0.0.1:

 $loop->connect(
    addr => {
       family   => "inet",
       socktype => "stream",
       port     => 8001,
       ip       => "10.0.0.1",
    },
    ...
 );

This example shows another way to connect to a UNIX socket at F<echo.sock>.

 $loop->connect(
    addr => {
       family   => "unix",
       socktype => "stream",
       path     => "echo.sock",
    },
    ...
 );

=item local_addrs => ARRAY

=item local_addr => HASH or ARRAY

Optional. Similar to the C<addrs> or C<addr> parameters, these specify a local
address or set of addresses to C<bind(2)> the socket to before
C<connect(2)>ing it.

=back

When performing the resolution step too, the C<addrs> or C<addr> keys are
ignored, and instead the following keys are taken:

=over 8

=item host => STRING

=item service => STRING

The hostname and service name to connect to.

=item local_host => STRING

=item local_service => STRING

Optional. The hostname and/or service name to C<bind(2)> the socket to locally
before connecting to the peer.

=item family => INT

=item socktype => INT

=item protocol => INT

=item flags => INT

Optional. Other arguments to pass along with C<host> and C<service> to the
C<getaddrinfo> call.

=item socktype => STRING

Optionally may instead be one of the values C<'stream'>, C<'dgram'> or
C<'raw'> to stand for C<SOCK_STREAM>, C<SOCK_DGRAM> or C<SOCK_RAW>. This
utility is provided to allow the caller to avoid a separate C<use Socket> only
for importing these constants.

=back

It is necessary to pass the C<socktype> hint to the resolver when resolving
the host/service names into an address, as some OS's C<getaddrinfo> functions
require this hint. A warning is emitted if neither C<socktype> nor C<protocol>
hint is defined when performing a C<getaddrinfo> lookup. To avoid this warning
while still specifying no particular C<socktype> hint (perhaps to invoke some
OS-specific behaviour), pass C<0> as the C<socktype> value.

In either case, it also accepts the following arguments:

=over 8

=item handle => IO::Async::Handle

Optional. If given a L<IO::Async::Handle> object or a subclass (such as
L<IO::Async::Stream> or L<IO::Async::Socket> its handle will be set to the
newly-connected socket on success, and that handle used as the result of the
future instead.

=item on_fail => CODE

Optional. After an individual C<socket(2)> or C<connect(2)> syscall has failed,
this callback is invoked to inform of the error. It is passed the name of the
syscall that failed, the arguments that were passed to it, and the error it
generated. I.e.

 $on_fail->( "socket", $family, $socktype, $protocol, $! );

 $on_fail->( "bind", $sock, $address, $! );

 $on_fail->( "connect", $sock, $address, $! );

Because of the "try all" nature when given a list of multiple addresses, this
callback may be invoked multiple times, even before an eventual success.

=back

This method accepts an C<extensions> parameter; see the C<EXTENSIONS> section
below.

=head2 connect (void)

   $loop->connect( %params )

When not returning a future, additional parameters can be given containing the
continuations to invoke on success or failure.

=over 8

=item on_connected => CODE

A continuation that is invoked on a successful C<connect(2)> call to a valid
socket. It will be passed the connected socket handle, as an C<IO::Socket>
object.

 $on_connected->( $handle )

=item on_stream => CODE

An alternative to C<on_connected>, a continuation that is passed an instance
of L<IO::Async::Stream> when the socket is connected. This is provided as a
convenience for the common case that a Stream object is required as the
transport for a Protocol object.

 $on_stream->( $stream )

=item on_socket => CODE

Similar to C<on_stream>, but constructs an instance of L<IO::Async::Socket>.
This is most useful for C<SOCK_DGRAM> or C<SOCK_RAW> sockets.

 $on_socket->( $socket )

=item on_connect_error => CODE

A continuation that is invoked after all of the addresses have been tried, and
none of them succeeded. It will be passed the most significant error that
occurred, and the name of the operation it occurred in. Errors from the
C<connect(2)> syscall are considered most significant, then C<bind(2)>, then
finally C<socket(2)>.

 $on_connect_error->( $syscall, $! )

=item on_resolve_error => CODE

A continuation that is invoked when the name resolution attempt fails. This is
invoked in the same way as the C<on_error> continuation for the C<resolve>
method.

=back

=cut

sub connect
{
   my $self = shift;
   my ( %params ) = @_;

   my $extensions;
   if( $extensions = delete $params{extensions} and @$extensions ) {
      my ( $ext, @others ) = @$extensions;

      my $method = "${ext}_connect";
      # TODO: Try to 'require IO::Async::$ext'

      $self->can( $method ) or croak "Extension method '$method' is not available";

      return $self->$method(
         %params,
         ( @others ? ( extensions => \@others ) : () ),
      );
   }

   my $handle = $params{handle};

   my $on_done;
   # Legacy callbacks
   if( my $on_connected = delete $params{on_connected} ) {
      $on_done = $on_connected;
   }
   elsif( my $on_stream = delete $params{on_stream} ) {
      defined $handle and croak "Cannot pass 'on_stream' with a handle object as well";

      require IO::Async::Stream;
      # TODO: It doesn't make sense to put a SOCK_DGRAM in an
      # IO::Async::Stream but currently we don't detect this
      $handle = IO::Async::Stream->new;
      $on_done = $on_stream;
   }
   elsif( my $on_socket = delete $params{on_socket} ) {
      defined $handle and croak "Cannot pass 'on_socket' with a handle object as well";

      require IO::Async::Socket;
      $handle = IO::Async::Socket->new;
      $on_done = $on_socket;
   }
   elsif( !defined wantarray ) {
      croak "Expected 'on_connected' or 'on_stream' callback or to return a Future";
   }

   my $on_connect_error;
   if( $on_connect_error = $params{on_connect_error} ) {
      # OK
   }
   elsif( !defined wantarray ) {
      croak "Expected 'on_connect_error' callback";
   }

   my $on_resolve_error;
   if( $on_resolve_error = $params{on_resolve_error} ) {
      # OK
   }
   elsif( !defined wantarray and exists $params{host} || exists $params{local_host} ) {
      croak "Expected 'on_resolve_error' callback or to return a Future";
   }

   my $connector = $self->{connector} ||= $self->__new_feature( "IO::Async::Internals::Connector" );

   my $future = $connector->connect( %params );

   $future = $future->then( sub {
      $handle->set_handle( shift );
      return Future->done( $handle )
   }) if $handle;

   $future->on_done( $on_done ) if $on_done;
   $future->on_fail( sub {
      $on_connect_error->( @_[2,3] ) if $on_connect_error and $_[1] eq "connect";
      $on_resolve_error->( $_[2] )   if $on_resolve_error and $_[1] eq "resolve";
   } );

   return $future if defined wantarray;

   # Caller is not going to keep hold of the Future, so we have to ensure it
   # stays alive somehow
   $future->on_ready( sub { undef $future } ); # intentional cycle
}

=head2 listen

   $listener = $loop->listen( %params )->get

This method sets up a listening socket and arranges for an acceptor callback
to be invoked each time a new connection is accepted on the socket. Internally
it creates an instance of L<IO::Async::Listener> and adds it to the Loop if
not given one in the arguments.

Addresses may be given directly, or they may be looked up using the system's
name resolver, or a socket handle may be given directly.

If multiple addresses are given, or resolved from the service and hostname,
then each will be attempted in turn until one succeeds.

In named resolver mode, the C<%params> hash takes the following keys:

=over 8

=item service => STRING

The service name to listen on.

=item host => STRING

The hostname to listen on. Optional. Will listen on all addresses if not
supplied.

=item family => INT

=item socktype => INT

=item protocol => INT

=item flags => INT

Optional. Other arguments to pass along with C<host> and C<service> to the
C<getaddrinfo> call.

=item socktype => STRING

Optionally may instead be one of the values C<'stream'>, C<'dgram'> or
C<'raw'> to stand for C<SOCK_STREAM>, C<SOCK_DGRAM> or C<SOCK_RAW>. This
utility is provided to allow the caller to avoid a separate C<use Socket> only
for importing these constants.

=back

It is necessary to pass the C<socktype> hint to the resolver when resolving
the host/service names into an address, as some OS's C<getaddrinfo> functions
require this hint. A warning is emitted if neither C<socktype> nor C<protocol>
hint is defined when performing a C<getaddrinfo> lookup. To avoid this warning
while still specifying no particular C<socktype> hint (perhaps to invoke some
OS-specific behaviour), pass C<0> as the C<socktype> value.

In plain address mode, the C<%params> hash takes the following keys:

=over 8

=item addrs => ARRAY

Reference to an array of (possibly-multiple) address structures to attempt to
listen on. Each should be in the layout described for C<addr>. Such a layout
is returned by the C<getaddrinfo> named resolver.

=item addr => ARRAY

Shortcut for passing a single address to listen on; it may be passed directly
with this key, instead of in another array of its own. This should be in a
format recognised by L<IO::Async::OS>'s C<extract_addrinfo> method. See also
the C<EXAMPLES> section.

=back

In direct socket handle mode, the following keys are taken:

=over 8

=item handle => IO

The listening socket handle.

=back

In either case, the following keys are also taken:

=over 8

=item on_fail => CODE

Optional. A callback that is invoked if a syscall fails while attempting to
create a listening sockets. It is passed the name of the syscall that failed,
the arguments that were passed to it, and the error generated. I.e.

 $on_fail->( "socket", $family, $socktype, $protocol, $! );

 $on_fail->( "sockopt", $sock, $optname, $optval, $! );

 $on_fail->( "bind", $sock, $address, $! );

 $on_fail->( "listen", $sock, $queuesize, $! );

=item queuesize => INT

Optional. The queue size to pass to the C<listen(2)> calls. If not supplied,
then 3 will be given instead.

=item reuseaddr => BOOL

Optional. If true or not supplied then the C<SO_REUSEADDR> socket option will
be set. To prevent this, pass a false value such as 0.

=item v6only => BOOL

Optional. If defined, sets or clears the C<IPV6_V6ONLY> socket option on
C<PF_INET6> sockets. This option disables the ability of C<PF_INET6> socket to
accept connections from C<AF_INET> addresses. Not all operating systems allow
this option to be disabled.

=back

An alternative which gives more control over the listener, is to create the
L<IO::Async::Listener> object directly and add it explicitly to the Loop.

This method accepts an C<extensions> parameter; see the C<EXTENSIONS> section
below.

=head2 listen (void)

   $loop->listen( %params )

When not returning a future, additional parameters can be given containing the
continuations to invoke on success or failure.

=over 8

=item on_notifier => CODE

Optional. A callback that is invoked when the Listener object is ready to
receive connections. The callback is passed the Listener object itself.

 $on_notifier->( $listener )

If this callback is required, it may instead be better to construct the
Listener object directly.

=item on_listen => CODE

Optional. A callback that is invoked when the listening socket is ready.
Typically this would be used in the name resolver case, in order to inspect
the socket's sockname address, or otherwise inspect the filehandle.

 $on_listen->( $socket )

=item on_listen_error => CODE

A continuation this is invoked after all of the addresses have been tried, and
none of them succeeded. It will be passed the most significant error that
occurred, and the name of the operation it occurred in. Errors from the
C<listen(2)> syscall are considered most significant, then C<bind(2)>, then
C<sockopt(2)>, then finally C<socket(2)>.

=item on_resolve_error => CODE

A continuation that is invoked when the name resolution attempt fails. This is
invoked in the same way as the C<on_error> continuation for the C<resolve>
method.

=back

=cut

sub listen
{
   my $self = shift;
   my ( %params ) = @_;

   my $remove_on_error;
   my $listener = $params{listener} ||= do {
      $remove_on_error++;

      require IO::Async::Listener;

      # Our wrappings of these don't want $listener
      my %listenerparams;
      for (qw( on_accept on_stream on_socket )) {
         next unless exists $params{$_};
         croak "Cannot ->listen with '$_' and 'listener'" if $params{listener};

         my $code = delete $params{$_};
         $listenerparams{$_} = sub {
            shift;
            goto &$code;
         };
      }

      my $listener = IO::Async::Listener->new( %listenerparams );
      $self->add( $listener );
      $listener
   };

   my $extensions;
   if( $extensions = delete $params{extensions} and @$extensions ) {
      my ( $ext, @others ) = @$extensions;

      # We happen to know we break older IO::Async::SSL
      if( $ext eq "SSL" and $IO::Async::SSL::VERSION < '0.12001' ) {
         croak "IO::Async::SSL version too old; need at least 0.12_001; found $IO::Async::SSL::VERSION";
      }

      my $method = "${ext}_listen";
      # TODO: Try to 'require IO::Async::$ext'

      $self->can( $method ) or croak "Extension method '$method' is not available";

      my $f = $self->$method(
         %params,
         ( @others ? ( extensions => \@others ) : () ),
      );
      $f->on_fail( sub { $self->remove( $listener ) } ) if $remove_on_error;

      return $f;
   }

   my $on_notifier = delete $params{on_notifier}; # optional

   my $on_listen_error  = delete $params{on_listen_error};
   my $on_resolve_error = delete $params{on_resolve_error};

   # Shortcut
   if( $params{addr} and not $params{addrs} ) {
      $params{addrs} = [ delete $params{addr} ];
   }

   my $f;
   if( my $handle = delete $params{handle} ) {
      $f = $self->_listen_handle( $listener, $handle, %params );
   }
   elsif( my $addrs = delete $params{addrs} ) {
      $on_listen_error or defined wantarray or
         croak "Expected 'on_listen_error' or to return a Future";
      $f = $self->_listen_addrs( $listener, $addrs, %params );
   }
   elsif( defined $params{service} ) {
      $on_listen_error or defined wantarray or
         croak "Expected 'on_listen_error' or to return a Future";
      $on_resolve_error or defined wantarray or
         croak "Expected 'on_resolve_error' or to return a Future";
      $f = $self->_listen_hostservice( $listener, delete $params{host}, delete $params{service}, %params );
   }
   else {
      croak "Expected either 'service' or 'addrs' or 'addr' arguments";
   }

   $f->on_done( $on_notifier ) if $on_notifier;
   if( my $on_listen = $params{on_listen} ) {
      $f->on_done( sub { $on_listen->( shift->read_handle ) } );
   }
   $f->on_fail( sub {
      my ( $message, $how, @rest ) = @_;
      $on_listen_error->( @rest )  if $on_listen_error  and $how eq "listen";
      $on_resolve_error->( @rest ) if $on_resolve_error and $how eq "resolve";
   });
   $f->on_fail( sub { $self->remove( $listener ) } ) if $remove_on_error;

   return $f if defined wantarray;

   # Caller is not going to keep hold of the Future, so we have to ensure it
   # stays alive somehow
   $f->on_ready( sub { undef $f } ); # intentional cycle
}

sub _listen_handle
{
   my $self = shift;
   my ( $listener, $handle, %params ) = @_;

   $listener->configure( handle => $handle );
   return $self->new_future->done( $listener );
}

sub _listen_addrs
{
   my $self = shift;
   my ( $listener, $addrs, %params ) = @_;

   my $queuesize = $params{queuesize} || 3;

   my $on_fail = $params{on_fail};
   !defined $on_fail or ref $on_fail or croak "Expected 'on_fail' to be a reference";

   my $reuseaddr = 1;
   $reuseaddr = 0 if defined $params{reuseaddr} and not $params{reuseaddr};

   my $v6only = $params{v6only};

   my ( $listenerr, $binderr, $sockopterr, $socketerr );

   foreach my $addr ( @$addrs ) {
      my ( $family, $socktype, $proto, $address ) = IO::Async::OS->extract_addrinfo( $addr );

      my $sock;

      unless( $sock = IO::Async::OS->socket( $family, $socktype, $proto ) ) {
         $socketerr = $!;
         $on_fail->( socket => $family, $socktype, $proto, $! ) if $on_fail;
         next;
      }

      $sock->blocking( 0 );

      if( $reuseaddr ) {
         unless( $sock->sockopt( SO_REUSEADDR, 1 ) ) {
            $sockopterr = $!;
            $on_fail->( sockopt => $sock, SO_REUSEADDR, 1, $! ) if $on_fail;
            next;
         }
      }

      if( defined $v6only and $family == AF_INET6 ) {
         unless( $sock->setsockopt( IPPROTO_IPV6, IPV6_V6ONLY, $v6only ) ) {
            $sockopterr = $!;
            $on_fail->( sockopt => $sock, IPV6_V6ONLY, $v6only, $! ) if $on_fail;
            next;
         }
      }

      unless( $sock->bind( $address ) ) {
         $binderr = $!;
         $on_fail->( bind => $sock, $address, $! ) if $on_fail;
         next;
      }

      unless( $sock->listen( $queuesize ) ) {
         $listenerr = $!;
         $on_fail->( listen => $sock, $queuesize, $! ) if $on_fail;
         next;
      }

      return $self->_listen_handle( $listener, $sock, %params );
   }

   my $f = $self->new_future;
   return $f->fail( "Cannot listen() - $listenerr",      listen => listen  => $listenerr  ) if $listenerr;
   return $f->fail( "Cannot bind() - $binderr",          listen => bind    => $binderr    ) if $binderr;
   return $f->fail( "Cannot setsockopt() - $sockopterr", listen => sockopt => $sockopterr ) if $sockopterr;
   return $f->fail( "Cannot socket() - $socketerr",      listen => socket  => $socketerr  ) if $socketerr;
   die 'Oops; $loop->listen failed but no error cause was found';
}

sub _listen_hostservice
{
   my $self = shift;
   my ( $listener, $host, $service, %params ) = @_;

   $host ||= "";
   defined $service or $service = ""; # might be 0

   my %gai_hints;
   exists $params{$_} and $gai_hints{$_} = $params{$_} for qw( family socktype protocol flags );

   defined $gai_hints{socktype} or defined $gai_hints{protocol} or
      carp "Attempting to ->listen without either 'socktype' or 'protocol' hint is not portable";

   $self->resolver->getaddrinfo(
      host    => $host,
      service => $service,
      passive => 1,
      %gai_hints,
   )->then( sub {
      my @addrs = @_;
      $self->_listen_addrs( $listener, \@addrs, %params );
   });
}

=head1 OS ABSTRACTIONS

Because the Magic Constructor searches for OS-specific subclasses of the Loop,
several abstractions of OS services are provided, in case specific OSes need
to give different implementations on that OS.

=cut

=head2 signame2num

   $signum = $loop->signame2num( $signame )

Legacy wrappers around L<IO::Async::OS> functions.

=cut

sub signame2num { shift; IO::Async::OS->signame2num( @_ ) }

=head2 time

   $time = $loop->time

Returns the current UNIX time in fractional seconds. This is currently
equivalent to C<Time::HiRes::time> but provided here as a utility for
programs to obtain the time current used by L<IO::Async> for its own timing
purposes.

=cut

sub time
{
   my $self = shift;
   return Time::HiRes::time;
}

=head2 fork

   $pid = $loop->fork( %params )

This method creates a new child process to run a given code block, returning
its process ID.

=over 8

=item code => CODE

A block of code to execute in the child process. It will be called in scalar
context inside an C<eval> block. The return value will be used as the
C<exit(2)> code from the child if it returns (or 255 if it returned C<undef> or
thows an exception).

=item on_exit => CODE

A optional continuation to be called when the child processes exits. It will
be invoked in the following way:

 $on_exit->( $pid, $exitcode )

The second argument is passed the plain perl C<$?> value.

This key is optional; if not supplied, the calling code should install a
handler using the C<watch_process> method.

=item keep_signals => BOOL

Optional boolean. If missing or false, any CODE references in the C<%SIG> hash
will be removed and restored back to C<DEFAULT> in the child process. If true,
no adjustment of the C<%SIG> hash will be performed.

=back

=cut

sub fork
{
   my $self = shift;
   my %params = @_;

   HAVE_POSIX_FORK or croak "POSIX fork() is not available";

   my $code = $params{code} or croak "Expected 'code' as a CODE reference";

   my $kid = fork;
   defined $kid or croak "Cannot fork() - $!";

   if( $kid == 0 ) {
      unless( $params{keep_signals} ) {
         foreach( keys %SIG ) {
            next if m/^__(WARN|DIE)__$/;
            $SIG{$_} = "DEFAULT" if ref $SIG{$_} eq "CODE";
         }
      }

      # If the child process wants to use an IO::Async::Loop it needs to make
      # a new one, so this value is never useful
      undef our $ONE_TRUE_LOOP;

      my $exitvalue = eval { $code->() };

      defined $exitvalue or $exitvalue = -1;

      POSIX::_exit( $exitvalue );
   }

   if( defined $params{on_exit} ) {
      $self->watch_process( $kid => $params{on_exit} );
   }

   $METRICS and $METRICS->inc_counter( forks => );

   return $kid;
}

=head2 create_thread

   $tid = $loop->create_thread( %params )

This method creates a new (non-detached) thread to run the given code block,
returning its thread ID.

=over 8

=item code => CODE

A block of code to execute in the thread. It is called in the context given by
the C<context> argument, and its return value will be available to the
C<on_joined> callback. It is called inside an C<eval> block; if it fails the
exception will be caught.

=item context => "scalar" | "list" | "void"

Optional. Gives the calling context that C<code> is invoked in. Defaults to
C<scalar> if not supplied.

=item on_joined => CODE

Callback to invoke when the thread function returns or throws an exception.
If it returned, this callback will be invoked with its result

 $on_joined->( return => @result )

If it threw an exception the callback is invoked with the value of C<$@>

 $on_joined->( died => $! )

=back

=cut

# It is basically impossible to have any semblance of order on global
# destruction, and even harder again to rely on when threads are going to be
# terminated and joined. Instead of ensuring we join them all, just detach any
# we no longer care about at END time
my %threads_to_detach; # {$tid} = $thread_weakly
END {
   $_ and $_->detach for values %threads_to_detach;
}

sub create_thread
{
   my $self = shift;
   my %params = @_;

   HAVE_THREADS or croak "Threads are not available";

   eval { require threads } or croak "This Perl does not support threads";

   my $code = $params{code} or croak "Expected 'code' as a CODE reference";
   my $on_joined = $params{on_joined} or croak "Expected 'on_joined' as a CODE reference";

   my $threadwatches = $self->{threadwatches};

   unless( $self->{thread_join_pipe} ) {
      ( my $rd, $self->{thread_join_pipe} ) = IO::Async::OS->pipepair or
         croak "Cannot pipepair - $!";
      $rd->blocking( 0 );
      $self->{thread_join_pipe}->autoflush(1);

      $self->watch_io(
         handle => $rd,
         on_read_ready => sub {
            sysread $rd, my $buffer, 8192 or return;

            # There's a race condition here in that we might have read from
            # the pipe after the returning thread has written to it but before
            # it has returned. We'll grab the actual $thread object and
            # forcibly ->join it here to ensure we wait for its result.

            foreach my $tid ( unpack "N*", $buffer ) {
               my ( $thread, $on_joined ) = @{ delete $threadwatches->{$tid} }
                  or die "ARGH: Can't find threadwatch for tid $tid\n";
               $on_joined->( $thread->join );
               delete $threads_to_detach{$tid};
            }
         }
      );
   }

   my $wr = $self->{thread_join_pipe};

   my $context = $params{context} || "scalar";

   my ( $thread ) = threads->create(
      sub {
         my ( @ret, $died );
         eval {
            $context eq "list"   ? ( @ret    = $code->() ) :
            $context eq "scalar" ? ( $ret[0] = $code->() ) :
                                               $code->();
            1;
         } or $died = $@;

         $wr->syswrite( pack "N", threads->tid );

         return died => $died if $died;
         return return => @ret;
      }
   );

   $threadwatches->{$thread->tid} = [ $thread, $on_joined ];
   weaken( $threads_to_detach{$thread->tid} = $thread );

   return $thread->tid;
}

=head1 LOW-LEVEL METHODS

As C<IO::Async::Loop> is an abstract base class, specific subclasses of it are
required to implement certain methods that form the base level of
functionality. They are not recommended for applications to use; see instead
the various event objects or higher level methods listed above.

These methods should be considered as part of the interface contract required
to implement a C<IO::Async::Loop> subclass.

=cut

=head2 API_VERSION

   IO::Async::Loop->API_VERSION

This method will be called by the magic constructor on the class before it is
constructed, to ensure that the specific implementation will support the
required API. This method should return the API version that the loop
implementation supports. The magic constructor will use that class, provided
it declares a version at least as new as the version documented here.

The current API version is C<0.49>.

This method may be implemented using C<constant>; e.g

 use constant API_VERSION => '0.49';

=cut

sub pre_wait
{
   my $self = shift;
   $METRICS and $self->{processing_start} and
      $METRICS->report_timer( processing_time => Time::HiRes::tv_interval $self->{processing_start} );
}

sub post_wait
{
   my $self = shift;
   $METRICS and $self->{processing_start} = [ Time::HiRes::gettimeofday ];
}

=head2 watch_io

   $loop->watch_io( %params )

This method installs callback functions which will be invoked when the given
IO handle becomes read- or write-ready.

The C<%params> hash takes the following keys:

=over 8

=item handle => IO

The IO handle to watch.

=item on_read_ready => CODE

Optional. A CODE reference to call when the handle becomes read-ready.

=item on_write_ready => CODE

Optional. A CODE reference to call when the handle becomes write-ready.

=back

There can only be one filehandle of any given fileno registered at any one
time. For any one filehandle, there can only be one read-readiness and/or one
write-readiness callback at any one time. Registering a new one will remove an
existing one of that type. It is not required that both are provided.

Applications should use a L<IO::Async::Handle> or L<IO::Async::Stream> instead
of using this method.

If the filehandle does not yet have the C<O_NONBLOCK> flag set, it will be
enabled by this method. This will ensure that any subsequent C<sysread>,
C<syswrite>, or similar will not block on the filehandle.

=cut

# This class specifically does NOT implement this method, so that subclasses
# are forced to. The constructor will be checking....
sub __watch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = delete $params{handle} or croak "Expected 'handle'";
   defined eval { $handle->fileno } or croak "Expected that 'handle' has defined ->fileno";

   # Silent "upgrade" to O_NONBLOCK
   $handle->blocking and $handle->blocking(0);

   my $watch = ( $self->{iowatches}->{$handle->fileno} ||= [] );

   $watch->[0] = $handle;

   if( exists $params{on_read_ready} ) {
      $watch->[1] = delete $params{on_read_ready};
   }

   if( exists $params{on_write_ready} ) {
      $watch->[2] = delete $params{on_write_ready};
   }

   if( exists $params{on_hangup} ) {
      $self->_CAN_ON_HANGUP or croak "Cannot watch_io for 'on_hangup' in ".ref($self);
      $watch->[3] = delete $params{on_hangup};
   }

   keys %params and croak "Unrecognised keys for ->watch_io - " . join( ", ", keys %params );
}

=head2 unwatch_io

   $loop->unwatch_io( %params )

This method removes a watch on an IO handle which was previously installed by
C<watch_io>.

The C<%params> hash takes the following keys:

=over 8

=item handle => IO

The IO handle to remove the watch for.

=item on_read_ready => BOOL

If true, remove the watch for read-readiness.

=item on_write_ready => BOOL

If true, remove the watch for write-readiness.

=back

Either or both callbacks may be removed at once. It is not an error to attempt
to remove a callback that is not present. If both callbacks were provided to
the C<watch_io> method and only one is removed by this method, the other shall
remain.

=cut

sub __unwatch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = delete $params{handle} or croak "Expected 'handle'";

   my $watch = $self->{iowatches}->{$handle->fileno} or return;

   if( delete $params{on_read_ready} ) {
      undef $watch->[1];
   }

   if( delete $params{on_write_ready} ) {
      undef $watch->[2];
   }

   if( delete $params{on_hangup} ) {
      $self->_CAN_ON_HANGUP or croak "Cannot watch_io for 'on_hangup' in ".ref($self);
      undef $watch->[3];
   }

   if( not $watch->[1] and not $watch->[2] and not $watch->[3] ) {
      delete $self->{iowatches}->{$handle->fileno};
   }

   keys %params and croak "Unrecognised keys for ->unwatch_io - " . join( ", ", keys %params );
}

=head2 watch_signal

   $loop->watch_signal( $signal, $code )

This method adds a new signal handler to watch the given signal.

=over 8

=item $signal

The name of the signal to watch to. This should be a bare name like C<TERM>.

=item $code

A CODE reference to the handling callback.

=back

There can only be one callback per signal name. Registering a new one will
remove an existing one.

Applications should use a L<IO::Async::Signal> object, or call
C<attach_signal> instead of using this method.

This and C<unwatch_signal> are optional; a subclass may implement neither, or
both. If it implements neither then signal handling will be performed by the
base class using a self-connected pipe to interrupt the main IO blocking.

=cut

sub watch_signal
{
   my $self = shift;
   my ( $signal, $code ) = @_;

   HAVE_SIGNALS or croak "This OS cannot ->watch_signal";

   IO::Async::OS->loop_watch_signal( $self, $signal, $code );
}

=head2 unwatch_signal

   $loop->unwatch_signal( $signal )

This method removes the signal callback for the given signal.

=over 8

=item $signal

The name of the signal to watch to. This should be a bare name like C<TERM>.

=back

=cut

sub unwatch_signal
{
   my $self = shift;
   my ( $signal ) = @_;

   HAVE_SIGNALS or croak "This OS cannot ->unwatch_signal";

   IO::Async::OS->loop_unwatch_signal( $self, $signal );
}

=head2 watch_time

   $id = $loop->watch_time( %args )

This method installs a callback which will be called at the specified time.
The time may either be specified as an absolute value (the C<at> key), or
as a delay from the time it is installed (the C<after> key).

The returned C<$id> value can be used to identify the timer in case it needs
to be cancelled by the C<unwatch_time> method. Note that this value may be
an object reference, so if it is stored, it should be released after it has
been fired or cancelled, so the object itself can be freed.

The C<%params> hash takes the following keys:

=over 8

=item at => NUM

The absolute system timestamp to run the event.

=item after => NUM

The delay after now at which to run the event, if C<at> is not supplied. A
zero or negative delayed timer should be executed as soon as possible; the
next time the C<loop_once> method is invoked.

=item now => NUM

The time to consider as now if calculating an absolute time based on C<after>;
defaults to C<time()> if not specified.

=item code => CODE

CODE reference to the continuation to run at the allotted time.

=back

Either one of C<at> or C<after> is required.

For more powerful timer functionality as a L<IO::Async::Notifier> (so it can
be used as a child within another Notifier), see instead the
L<IO::Async::Timer> object and its subclasses.

These C<*_time> methods are optional; a subclass may implement neither or both
of them. If it implements neither, then the base class will manage a queue of
timer events. This queue should be handled by the C<loop_once> method
implemented by the subclass, using the C<_adjust_timeout> and
C<_manage_queues> methods.

This is the newer version of the API, replacing C<enqueue_timer>. It is
unspecified how this method pair interacts with the older
C<enqueue/requeue/cancel_timer> triplet.

=cut

sub watch_time
{
   my $self = shift;
   my %args = @_;

   # Renamed args
   if( exists $args{after} ) {
      $args{delay} = delete $args{after};
   }
   elsif( exists $args{at} ) {
      $args{time}  = delete $args{at};
   }
   else {
      croak "Expected one of 'at' or 'after'";
   }

   if( $self->{old_timer} ) {
      $self->enqueue_timer( %args );
   }
   else {
      my $timequeue = $self->{timequeue} ||= $self->__new_feature( "IO::Async::Internals::TimeQueue" );

      my $time = $self->_build_time( %args );
      my $code = $args{code};

      $timequeue->enqueue( time => $time, code => $code );
   }
}

=head2 unwatch_time

   $loop->unwatch_time( $id )

Removes a timer callback previously created by C<watch_time>.

This is the newer version of the API, replacing C<cancel_timer>. It is
unspecified how this method pair interacts with the older
C<enqueue/requeue/cancel_timer> triplet.

=cut

sub unwatch_time
{
   my $self = shift;
   my ( $id ) = @_;

   if( $self->{old_timer} ) {
      $self->cancel_timer( $id );
   }
   else {
      my $timequeue = $self->{timequeue} ||= $self->__new_feature( "IO::Async::Internals::TimeQueue" );

      $timequeue->cancel( $id );
   }
}

sub _build_time
{
   my $self = shift;
   my %params = @_;

   my $time;
   if( exists $params{time} ) {
      $time = $params{time};
   }
   elsif( exists $params{delay} ) {
      my $now = exists $params{now} ? $params{now} : $self->time;

      $time = $now + $params{delay};
   }
   else {
      croak "Expected either 'time' or 'delay' keys";
   }

   return $time;
}

=head2 enqueue_timer

   $id = $loop->enqueue_timer( %params )

An older version of C<watch_time>. This method should not be used in new code
but is retained for legacy purposes. For simple watch/unwatch behaviour use
instead the new C<watch_time> method; though note it has differently-named
arguments. For requeueable timers, consider using an
L<IO::Async::Timer::Countdown> or L<IO::Async::Timer::Absolute> instead.

=cut

sub enqueue_timer
{
   my $self = shift;
   my ( %params ) = @_;

   # Renamed args
   $params{after} = delete $params{delay} if exists $params{delay};
   $params{at}    = delete $params{time}  if exists $params{time};

   my $code = $params{code};
   return [ $self->watch_time( %params ), $code ];
}

=head2 cancel_timer

   $loop->cancel_timer( $id )

An older version of C<unwatch_time>. This method should not be used in new
code but is retained for legacy purposes.

=cut

sub cancel_timer
{
   my $self = shift;
   my ( $id ) = @_;
   $self->unwatch_time( $id->[0] );
}

=head2 requeue_timer

   $newid = $loop->requeue_timer( $id, %params )

Reschedule an existing timer, moving it to a new time. The old timer is
removed and will not be invoked.

The C<%params> hash takes the same keys as C<enqueue_timer>, except for the
C<code> argument.

The requeue operation may be implemented as a cancel + enqueue, which may
mean the ID changes. Be sure to store the returned C<$newid> value if it is
required.

This method should not be used in new code but is retained for legacy
purposes. For requeueable, consider using an L<IO::Async::Timer::Countdown> or
L<IO::Async::Timer::Absolute> instead.

=cut

sub requeue_timer
{
   my $self = shift;
   my ( $id, %params ) = @_;

   $self->unwatch_time( $id->[0] );
   return $self->enqueue_timer( %params, code => $id->[1] );
}

=head2 watch_idle

   $id = $loop->watch_idle( %params )

This method installs a callback which will be called at some point in the near
future.

The C<%params> hash takes the following keys:

=over 8

=item when => STRING

Specifies the time at which the callback will be invoked. See below.

=item code => CODE

CODE reference to the continuation to run at the allotted time.

=back

The C<when> parameter defines the time at which the callback will later be
invoked. Must be one of the following values:

=over 8

=item later

Callback is invoked after the current round of IO events have been processed
by the loop's underlying C<loop_once> method.

If a new idle watch is installed from within a C<later> callback, the
installed one will not be invoked during this round. It will be deferred for
the next time C<loop_once> is called, after any IO events have been handled.

=back

If there are pending idle handlers, then the C<loop_once> method will use a
zero timeout; it will return immediately, having processed any IO events and
idle handlers.

The returned C<$id> value can be used to identify the idle handler in case it
needs to be removed, by calling the C<unwatch_idle> method. Note this value
may be a reference, so if it is stored it should be released after the
callback has been invoked or cancled, so the referrant itself can be freed.

This and C<unwatch_idle> are optional; a subclass may implement neither, or
both. If it implements neither then idle handling will be performed by the
base class, using the C<_adjust_timeout> and C<_manage_queues> methods.

=cut

sub watch_idle
{
   my $self = shift;
   my %params = @_;

   my $code = delete $params{code};
   ref $code or croak "Expected 'code' to be a reference";

   my $when = delete $params{when} or croak "Expected 'when'";

   # Future-proofing for other idle modes
   $when eq "later" or croak "Expected 'when' to be 'later'";

   my $deferrals = $self->{deferrals};

   push @$deferrals, $code;
   return \$deferrals->[-1];
}

=head2 unwatch_idle

   $loop->unwatch_idle( $id )

Cancels a previously-installed idle handler.

=cut

sub unwatch_idle
{
   my $self = shift;
   my ( $id ) = @_;

   my $deferrals = $self->{deferrals};

   my $idx;
   \$deferrals->[$_] == $id and ( $idx = $_ ), last for 0 .. $#$deferrals;

   splice @$deferrals, $idx, 1, () if defined $idx;
}

sub _reap_children
{
   my ( $childwatches ) = @_;

   while( 1 ) {
      my $zid = waitpid( -1, WNOHANG );

      # PIDs on MSWin32 can be negative
      last if !defined $zid or $zid == 0 or $zid == -1;
      my $status = $?;

      if( defined $childwatches->{$zid} ) {
         $childwatches->{$zid}->( $zid, $status );
         delete $childwatches->{$zid};
      }

      if( defined $childwatches->{0} ) {
         $childwatches->{0}->( $zid, $status );
         # Don't delete it
      }
   }
}

=head2 watch_process

   $loop->watch_process( $pid, $code )

This method adds a new handler for the termination of the given child process
PID, or all child processes.

=over 8

=item $pid

The PID to watch. Will report on all child processes if this is 0.

=item $code

A CODE reference to the exit handler. It will be invoked as

 $code->( $pid, $? )

The second argument is passed the plain perl C<$?> value.

=back

After invocation, the handler for a PID-specific watch is automatically
removed. The all-child watch will remain until it is removed by
C<unwatch_process>.

This and C<unwatch_process> are optional; a subclass may implement neither, or
both. If it implements neither then child watching will be performed by using
C<watch_signal> to install a C<SIGCHLD> handler, which will use C<waitpid> to
look for exited child processes.

If both a PID-specific and an all-process watch are installed, there is no
ordering guarantee as to which will be called first.

=cut

sub watch_process
{
   my $self = shift;
   my ( $pid, $code ) = @_;

   if( $self->API_VERSION < 0.76 and
      ( $self->can( "watch_child" ) // 0 ) != \&watch_child ) {
      # Invoke legacy loop API
      return $self->watch_child( @_ );
   }

   my $childwatches = $self->{childwatches};

   croak "Already have a handler for $pid" if exists $childwatches->{$pid};

   if( HAVE_SIGNALS and !$self->{childwatch_sigid} ) {
      $self->{childwatch_sigid} = $self->attach_signal(
         CHLD => sub { _reap_children( $childwatches ) }
      );

      # There's a chance the child has already exited
      my $zid = waitpid( $pid, WNOHANG );
      if( defined $zid and $zid > 0 ) {
         my $exitstatus = $?;
         $self->later( sub { $code->( $pid, $exitstatus ) } );
         return;
      }
   }

   $childwatches->{$pid} = $code;
}

# Old name
sub watch_child { shift->watch_process( @_ ) }

=head2 unwatch_process

   $loop->unwatch_process( $pid )

This method removes a watch on an existing child process PID.

=cut

sub unwatch_process
{
   my $self = shift;
   my ( $pid ) = @_;

   if( $self->API_VERSION < 0.76 and
      ( $self->can( "unwatch_child" ) // 0 ) != \&unwatch_child ) {
      # Invoke legacy loop API
      return $self->unwatch_child( @_ );
   }

   my $childwatches = $self->{childwatches};

   delete $childwatches->{$pid};

   if( HAVE_SIGNALS and !keys %$childwatches ) {
      $self->detach_signal( CHLD => delete $self->{childwatch_sigid} );
   }
}

# Old name
sub unwatch_child { shift->unwatch_process( @_ ) }

=head1 METHODS FOR SUBCLASSES

The following methods are provided to access internal features which are
required by specific subclasses to implement the loop functionality. The use
cases of each will be documented in the above section.

=cut

=head2 _adjust_timeout

   $loop->_adjust_timeout( \$timeout )

Shortens the timeout value passed in the scalar reference if it is longer in
seconds than the time until the next queued event on the timer queue. If there
are pending idle handlers, the timeout is reduced to zero.

=cut

sub _adjust_timeout
{
   my $self = shift;
   my ( $timeref, %params ) = @_;

   $$timeref = 0, return if @{ $self->{deferrals} };

   if( defined $self->{sigproxy} and !$params{no_sigwait} ) {
      $$timeref = $MAX_SIGWAIT_TIME if !defined $$timeref or $$timeref > $MAX_SIGWAIT_TIME;
   }
   if( !HAVE_SIGNALS and keys %{ $self->{childwatches} } ) {
      $$timeref = $MAX_CHILDWAIT_TIME if !defined $$timeref or $$timeref > $MAX_CHILDWAIT_TIME;
   }

   my $timequeue = $self->{timequeue};
   return unless defined $timequeue;

   my $nexttime = $timequeue->next_time;
   return unless defined $nexttime;

   my $now = exists $params{now} ? $params{now} : $self->time;
   my $timer_delay = $nexttime - $now;

   if( $timer_delay < 0 ) {
      $$timeref = 0;
   }
   elsif( !defined $$timeref or $timer_delay < $$timeref ) {
      $$timeref = $timer_delay;
   }
}

=head2 _manage_queues

   $loop->_manage_queues

Checks the timer queue for callbacks that should have been invoked by now, and
runs them all, removing them from the queue. It also invokes all of the
pending idle handlers. Any new idle handlers installed by these are not
invoked yet; they will wait for the next time this method is called.

=cut

sub _manage_queues
{
   my $self = shift;

   my $count = 0;

   my $timequeue = $self->{timequeue};
   $count += $timequeue->fire if $timequeue;

   my $deferrals = $self->{deferrals};
   $self->{deferrals} = [];

   foreach my $code ( @$deferrals ) {
      $code->();
      $count++;
   }

   my $childwatches = $self->{childwatches};
   if( !HAVE_SIGNALS and keys %$childwatches ) {
      _reap_children( $childwatches );
   }

   return $count;
}

=head1 EXTENSIONS

An Extension is a Perl module that provides extra methods in the
C<IO::Async::Loop> or other packages. They are intended to provide extra
functionality that easily integrates with the rest of the code.

Certain base methods take an C<extensions> parameter; an ARRAY reference
containing a list of extension names. If such a list is passed to a method, it
will immediately call a method whose name is that of the base method, prefixed
by the first extension name in the list, separated by C<_>. If the
C<extensions> list contains more extension names, it will be passed the
remaining ones in another C<extensions> parameter.

For example,

 $loop->connect(
    extensions => [qw( FOO BAR )],
    %args
 )

will become

 $loop->FOO_connect(
    extensions => [qw( BAR )],
    %args
 )

This is provided so that extension modules, such as L<IO::Async::SSL> can
easily be invoked indirectly, by passing extra arguments to C<connect> methods
or similar, without needing every module to be aware of the C<SSL> extension.
This functionality is generic and not limited to C<SSL>; other extensions may
also use it.

The following methods take an C<extensions> parameter:

 $loop->connect
 $loop->listen

If an extension C<listen> method is invoked, it will be passed a C<listener>
parameter even if one was not provided to the original C<< $loop->listen >>
call, and it will not receive any of the C<on_*> event callbacks. It should
use the C<acceptor> parameter on the C<listener> object.

=cut

=head1 STALL WATCHDOG

A well-behaved L<IO::Async> program should spend almost all of its time
blocked on input using the underlying C<IO::Async::Loop> instance. The stall
watchdog is an optional debugging feature to help detect CPU spinlocks and
other bugs, where control is not returned to the loop every so often.

If the watchdog is enabled and an event handler consumes more than a given
amount of real time before returning to the event loop, it will be interrupted
by printing a stack trace and terminating the program. The watchdog is only in
effect while the loop itself is not blocking; it won't fail simply because the
loop instance is waiting for input or timers.

It is implemented using C<SIGALRM>, so if enabled, this signal will no longer
be available to user code. (Though in any case, most uses of C<alarm()> and
C<SIGALRM> are better served by one of the L<IO::Async::Timer> subclasses).

The following environment variables control its behaviour.

=over 4

=item IO_ASYNC_WATCHDOG => BOOL

Enables the stall watchdog if set to a non-zero value.

=item IO_ASYNC_WATCHDOG_INTERVAL => INT

Watchdog interval, in seconds, to pass to the C<alarm(2)> call. Defaults to 10
seconds.

=item IO_ASYNC_WATCHDOG_SIGABRT => BOOL

If enabled, the watchdog signal handler will raise a C<SIGABRT>, which usually
has the effect of breaking out of a running program in debuggers such as
F<gdb>. If not set then the process is terminated by throwing an exception with
C<die>.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
