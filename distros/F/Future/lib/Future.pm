#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2024 -- leonerd@leonerd.org.uk

package Future 0.51;

use v5.14;
use warnings;
no warnings 'recursion'; # Disable the "deep recursion" warning

# we are not overloaded, but we want to check if other objects are
require overload;

require Future::Exception;

our @CARP_NOT = qw( Future::Utils );

BEGIN {
   if( !$ENV{PERL_FUTURE_NO_XS} and eval { require Future::XS } ) {
      our @ISA = qw( Future::XS );
      *DEBUG = \&Future::XS::DEBUG;
   }
   else {
      require Future::PP;
      our @ISA = qw( Future::PP );
      *DEBUG = \&Future::PP::DEBUG;
   }
}

our $TIMES = DEBUG || $ENV{PERL_FUTURE_TIMES};

# All of the methods provided in this file actually live in Future::_base::
#   which is supplied as a base class for actual Future::PP and Future::XS to
#   use.
package
   Future::_base;

use Scalar::Util qw( blessed );
use B qw( svref_2object );
use Time::HiRes qw( tv_interval );

=head1 NAME

C<Future> - represent an operation awaiting completion

=head1 SYNOPSIS

=for highlighter language=perl

   my $future = Future->new;

   perform_some_operation(
      on_complete => sub {
         $future->done( @_ );
      }
   );

   $future->on_ready( sub {
      say "The operation is complete";
   } );

=head1 DESCRIPTION

A C<Future> object represents an operation that is currently in progress, or
has recently completed. It can be used in a variety of ways to manage the flow
of control, and data, through an asynchronous program.

Some futures represent a single operation and are explicitly marked as ready
by calling the C<done> or C<fail> methods. These are called "leaf" futures
here, and are returned by the C<new> constructor.

Other futures represent a collection of sub-tasks, and are implicitly marked
as ready depending on the readiness of their component futures as required.
These are called "convergent" futures here as they converge control and
data-flow back into one place. These are the ones returned by the various
C<wait_*> and C<need_*> constructors.

It is intended that library functions that perform asynchronous operations
would use future objects to represent outstanding operations, and allow their
calling programs to control or wait for these operations to complete. The
implementation and the user of such an interface would typically make use of
different methods on the class. The methods below are documented in two
sections; those of interest to each side of the interface.

It should be noted however, that this module does not in any way provide an
actual mechanism for performing this asynchronous activity; it merely provides
a way to create objects that can be used for control and data flow around
those operations. It allows such code to be written in a neater,
forward-reading manner, and simplifies many common patterns that are often
involved in such situations.

See also L<Future::Utils> which contains useful loop-constructing functions,
to run a future-returning function repeatedly in a loop.

Unless otherwise noted, the following methods require at least version
I<0.08>.

=head2 FAILURE CATEGORIES

While not directly required by C<Future> or its related modules, a growing
convention of C<Future>-using code is to encode extra semantics in the
arguments given to the C<fail> method, to represent different kinds of
failure.

The convention is that after the initial message string as the first required
argument (intended for display to humans), the second argument is a short
lowercase string that relates in some way to the kind of failure that
occurred. Following this is a list of details about that kind of failure,
whose exact arrangement or structure are determined by the failure category.
For example, L<IO::Async> and L<Net::Async::HTTP> use this convention to
indicate at what stage a given HTTP request has failed:

   ->fail( $message, http => ... )  # an HTTP-level error during protocol
   ->fail( $message, connect => ... )  # a TCP-level failure to connect a
                                       # socket
   ->fail( $message, resolve => ... )  # a resolver (likely DNS) failure
                                       # to resolve a hostname

By following this convention, a module remains consistent with other
C<Future>-based modules, and makes it easy for program logic to gracefully
handle and manage failures by use of the C<catch> method.

=head2 SUBCLASSING

This class easily supports being subclassed to provide extra behavior, such as
giving the C<get> method the ability to block and wait for completion. This
may be useful to provide C<Future> subclasses with event systems, or similar.

Each method that returns a new future object will use the invocant to
construct its return value. If the constructor needs to perform per-instance
setup it can override the C<new> method, and take context from the given
instance.

   sub new
   {
      my $proto = shift;
      my $self = $proto->SUPER::new;

      if( ref $proto ) {
         # Prototype was an instance
      }
      else {
         # Prototype was a class
      }

      return $self;
   }

If an instance overrides the L</await> method, this will be called by C<get>
and C<failure> if the instance is still pending.

In most cases this should allow future-returning modules to be used as if they
were blocking call/return-style modules, by simply appending a C<get> call to
the function or method calls.

   my ( $results, $here ) = future_returning_function( @args )->get;

=head2 DEBUGGING

By the time a C<Future> object is destroyed, it ought to have been completed
or cancelled. By enabling debug tracing of objects, this fact can be checked.
If a future object is destroyed without having been completed or cancelled, a
warning message is printed.

=for highlighter

   $ PERL_FUTURE_DEBUG=1 perl -MFuture -E 'my $f = Future->new'
   Future=HASH(0xaa61f8) was constructed at -e line 1 and was lost near -e line 0 before it was ready.

Note that due to a limitation of perl's C<caller> function within a C<DESTROY>
destructor method, the exact location of the leak cannot be accurately
determined. Often the leak will occur due to falling out of scope by returning
from a function; in this case the leak location may be reported as being the
line following the line calling that function.

   $ PERL_FUTURE_DEBUG=1 perl -MFuture
   sub foo {
      my $f = Future->new;
   }

   foo();
   print "Finished\n";

   Future=HASH(0x14a2220) was constructed at - line 2 and was lost near - line 6 before it was ready.
   Finished

A warning is also printed in debug mode if a C<Future> object is destroyed
that completed with a failure, but the object believes that failure has not
been reported anywhere.

   $ PERL_FUTURE_DEBUG=1 perl -Mblib -MFuture -E 'my $f = Future->fail("Oops")'
   Future=HASH(0xac98f8) was constructed at -e line 1 and was lost near -e line 0 with an unreported failure of: Oops

Such a failure is considered reported if the C<get> or C<failure> methods are
called on it, or it had at least one C<on_ready> or C<on_fail> callback, or
its failure is propagated to another C<Future> instance (by a sequencing or
converging method).

=head2 Future::AsyncAwait::Awaitable ROLE

Since version 0.43 this module provides the L<Future::AsyncAwait::Awaitable>
API. Subclass authors should note that several of the API methods are provided
by special optimised internal methods, which may require overriding in your
subclass if your internals are different from that of this module.

=cut

=head1 CONSTRUCTORS

=for highlighter language=perl

=cut

=head2 new

   $future = Future->new;

   $future = $orig->new;

Returns a new C<Future> instance to represent a leaf future. It will be marked
as ready by any of the C<done>, C<fail>, or C<cancel> methods. It can be
called either as a class method, or as an instance method. Called on an
instance it will construct another in the same class, and is useful for
subclassing.

This constructor would primarily be used by implementations of asynchronous
interfaces.

=cut

*AWAIT_CLONE = sub { shift->new };

# Useful for identifying CODE references
sub CvNAME_FILE_LINE
{
   my ( $code ) = @_;
   my $cv = svref_2object( $code );

   my $name = join "::", $cv->STASH->NAME, $cv->GV->NAME;
   return $name unless $cv->GV->NAME eq "__ANON__";

   # $cv->GV->LINE isn't reliable, as outside of perl -d mode all anon CODE
   # in the same file actually shares the same GV. :(
   # Walk the optree looking for the first COP
   my $cop = $cv->START;
   $cop = $cop->next while $cop and ref $cop ne "B::COP" and ref $cop ne "B::NULL";

   return $cv->GV->NAME if ref $cop eq "B::NULL";
   sprintf "%s(%s line %d)", $cv->GV->NAME, $cop->file, $cop->line;
}

=head2 done I<(class method)>

=head2 fail I<(class method)>

   $future = Future->done( @values );

   $future = Future->fail( $exception, $category, @details );

I<Since version 0.26.>

Shortcut wrappers around creating a new C<Future> then immediately marking it
as done or failed.

=head2 wrap

   $future = Future->wrap( @values );

I<Since version 0.14.>

If given a single argument which is already a C<Future> reference, this will
be returned unmodified. Otherwise, returns a new C<Future> instance that is
already complete, and will yield the given values.

This will ensure that an incoming argument is definitely a C<Future>, and may
be useful in such cases as adapting synchronous code to fit asynchronous
libraries driven by C<Future>.

=cut

sub wrap
{
   my $class = shift;
   my @values = @_;

   if( @values == 1 and blessed $values[0] and $values[0]->isa( __PACKAGE__ ) ) {
      return $values[0];
   }
   else {
      return $class->done( @values );
   }
}

=head2 call

   $future = Future->call( \&code, @args );

I<Since version 0.15.>

A convenient wrapper for calling a C<CODE> reference that is expected to
return a future. In normal circumstances is equivalent to

   $future = $code->( @args );

except that if the code throws an exception, it is wrapped in a new immediate
fail future. If the return value from the code is not a blessed C<Future>
reference, an immediate fail future is returned instead to complain about this
fact.

=cut

sub call
{
   my $class = shift;
   my ( $code, @args ) = @_;

   my $f;
   eval { $f = $code->( @args ); 1 } or $f = $class->fail( $@ );
   blessed $f and $f->isa( "Future" ) or $f = $class->fail( "Expected " . CvNAME_FILE_LINE($code) . " to return a Future" );

   return $f;
}

=head1 METHODS

As there are a lare number of methods on this class, they are documented here
in several sections.

=cut

=head1 INSPECTION METHODS

The following methods query the internal state of a Future instance without
modifying it or otherwise causing side-effects.

=cut

=head2 is_ready

   $ready = $future->is_ready;

Returns true on a leaf future if a result has been provided to the C<done>
method, failed using the C<fail> method, or cancelled using the C<cancel>
method.

Returns true on a convergent future if it is ready to yield a result,
depending on its component futures.

=cut

*AWAIT_IS_READY = sub { shift->is_ready };

=head2 is_done

   $done = $future->is_done;

Returns true on a future if it is ready and completed successfully. Returns
false if it is still pending, failed, or was cancelled.

=cut

=head2 is_failed

   $failed = $future->is_failed;

I<Since version 0.26.>

Returns true on a future if it is ready and it failed. Returns false if it is
still pending, completed successfully, or was cancelled.

=cut

=head2 is_cancelled

   $cancelled = $future->is_cancelled;

Returns true if the future has been cancelled by C<cancel>.

=cut

*AWAIT_IS_CANCELLED = sub { shift->is_cancelled };

=head2 state

   $str = $future->state;

I<Since version 0.36.>

Returns a string describing the state of the future, as one of the three
states named above; namely C<done>, C<failed> or C<cancelled>, or C<pending>
if it is none of these.

=cut

=head1 IMPLEMENTATION METHODS

These methods would primarily be used by implementations of asynchronous
interfaces.

=cut

=head2 done

   $future->done( @result );

Marks that the leaf future is now ready, and provides a list of values as a
result. (The empty list is allowed, and still indicates the future as ready).
Cannot be called on a convergent future.

If the future is already cancelled, this request is ignored. If the future is
already complete with a result or a failure, an exception is thrown.

I<Since version 0.45:> this method is also available under the name
C<resolve>.

=cut

*resolve = sub { shift->done( @_ ) };

# TODO: For efficiency we can implement better versions of these as individual
#  methods know which case is being invoked
*AWAIT_NEW_DONE = *AWAIT_DONE = sub { shift->done( @_ ) };

=head2 fail

   $future->fail( $exception, $category, @details );

Marks that the leaf future has failed, and provides an exception value. This
exception will be thrown by the C<get> method if called. 

The exception must evaluate as a true value; false exceptions are not allowed.
A failure category name and other further details may be provided that will be
returned by the C<failure> method in list context.

If the future is already cancelled, this request is ignored. If the future is
already complete with a result or a failure, an exception is thrown.

If passed a L<Future::Exception> instance (i.e. an object previously thrown by
the C<get>), the additional details will be preserved. This allows the
additional details to be transparently preserved by such code as

   ...
   catch {
      return Future->fail($@);
   }

I<Since version 0.45:> this method is also available under the name C<reject>.

=cut

*reject = sub { shift->fail( @_ ) };

# TODO: For efficiency we can implement better versions of these as individual
#  methods know which case is being invoked
*AWAIT_NEW_FAIL = *AWAIT_FAIL = sub { shift->fail( @_ ) };

=head2 die

   $future->die( $message, $category, @details );

I<Since version 0.09.>

A convenient wrapper around C<fail>. If the exception is a non-reference that
does not end in a linefeed, its value will be extended by the file and line
number of the caller, similar to the logic that C<die> uses.

Returns the C<$future>.

=cut

sub die :method
{
   my $self = shift;
   my ( $exception, @more ) = @_;

   if( !ref $exception and $exception !~ m/\n$/ ) {
      $exception .= sprintf " at %s line %d\n", (caller)[1,2];
   }

   $self->fail( $exception, @more );
}

=head2 on_cancel

   $future->on_cancel( $code );

If the future is not yet ready, adds a callback to be invoked if the future is
cancelled by the C<cancel> method. If the future is already ready the method
is ignored.

If the future is later cancelled, the callbacks will be invoked in the reverse
order to that in which they were registered.

   $on_cancel->( $future );

If passed another C<Future> instance, the passed instance will be cancelled
when the original future is cancelled. In this case, the reference is only
strongly held while the target future remains pending. If it becomes ready,
then there is no point trying to cancel it, and so it is removed from the
originating future's cancellation list.

=cut

*AWAIT_ON_CANCEL = *AWAIT_CHAIN_CANCEL = sub { shift->on_cancel( @_ ) };

=head1 USER METHODS

These methods would primarily be used by users of asynchronous interfaces, on
objects returned by such an interface.

=cut

=head2 on_ready

   $future->on_ready( $code );

If the future is not yet ready, adds a callback to be invoked when the future
is ready. If the future is already ready, invokes it immediately.

In either case, the callback will be passed the future object itself. The
invoked code can then obtain the list of results by calling the C<get> method.

   $on_ready->( $future );

If passed another C<Future> instance, the passed instance will have its
C<done>, C<fail> or C<cancel> methods invoked when the original future
completes successfully, fails, or is cancelled respectively.

Returns the C<$future>.

=cut

*AWAIT_ON_READY = sub { shift->on_ready( @_ ) };

=head2 result

   @result = $future->result;

   $result = $future->result;

I<Since version 0.44.>

If the future is ready and completed successfully, returns the list of
results that had earlier been given to the C<done> method on a leaf future,
or the list of component futures it was waiting for on a convergent future. In
scalar context it returns just the first result value.

If the future is ready but failed, this method raises as an exception the
failure that was given to the C<fail> method. If additional details were given
to the C<fail> method, an exception object is constructed to wrap them of type
L<Future::Exception>.

If the future was cancelled or is not yet ready an exception is thrown.

=cut

*AWAIT_RESULT = *AWAIT_GET = sub { shift->result };

=head2 get

   @result = $future->get;

   $result = $future->get;

If the future is ready, returns the result or throws the failure exception as
per L</result>.

If it is not yet ready then L</await> is invoked to wait for a ready state, and
the result returned as above.

=cut

*AWAIT_WAIT = sub { shift->get };

=head2 await

   $f = $f->await;

I<Since version 0.44.>

Blocks until the future instance is no longer pending.

Returns the invocant future itself, so it is useful for chaining.

Usually, calling code would either force the future using L</get>, or use
either C<then> chaining or C<async/await> syntax to wait for results. This
method is useful in cases where the exception-throwing part of C<get> is not
required, perhaps because other code will be testing the result using
L</is_done> or similar.

   if( $f->await->is_done ) {
      ...
   }

This method is intended for subclasses to override. The default implementation
will throw an exception if called on a still-pending instance.

=cut

=head2 block_until_ready

   $f = $f->block_until_ready;

I<Since version 0.40.>

Now a synonym for L</await>. New code should invoke C<await> directly.

=cut

sub block_until_ready
{
   my $self = shift;
   return $self->await;
}

=head2 unwrap

   @values = Future->unwrap( @values );

I<Since version 0.26.>

If given a single argument which is a C<Future> reference, this method will
call C<get> on it and return the result. Otherwise, it returns the list of
values directly in list context, or the first value in scalar. Since it
involves an implicit blocking wait, this method can only be used on immediate
futures or subclasses that implement L</await>.

This will ensure that an outgoing argument is definitely not a C<Future>, and
may be useful in such cases as adapting synchronous code to fit asynchronous
libraries that return C<Future> instances.

=cut

sub unwrap
{
   shift; # $class
   my @values = @_;

   if( @values == 1 and blessed $values[0] and $values[0]->isa( __PACKAGE__ ) ) {
      return $values[0]->get;
   }
   else {
      return $values[0] if !wantarray;
      return @values;
   }
}

=head2 on_done

   $future->on_done( $code );

If the future is not yet ready, adds a callback to be invoked when the future
is ready, if it completes successfully. If the future completed successfully,
invokes it immediately. If it failed or was cancelled, it is not invoked at
all.

The callback will be passed the result passed to the C<done> method.

   $on_done->( @result );

If passed another C<Future> instance, the passed instance will have its
C<done> method invoked when the original future completes successfully.

Returns the C<$future>.

=cut

=head2 failure

   $exception = $future->failure;

   $exception, $category, @details = $future->failure;

If the future is ready, returns the exception passed to the C<fail> method or
C<undef> if the future completed successfully via the C<done> method.

If it is not yet ready then L</await> is invoked to wait for a ready state.

If called in list context, will additionally yield the category name and list
of the details provided to the C<fail> method.

Because the exception value must be true, this can be used in a simple C<if>
statement:

   if( my $exception = $future->failure ) {
      ...
   }
   else {
      my @result = $future->result;
      ...
   }

=cut

=head2 on_fail

   $future->on_fail( $code );

If the future is not yet ready, adds a callback to be invoked when the future
is ready, if it fails. If the future has already failed, invokes it
immediately. If it completed successfully or was cancelled, it is not invoked
at all.

The callback will be passed the exception and other details passed to the
C<fail> method.

   $on_fail->( $exception, $category, @details );

If passed another C<Future> instance, the passed instance will have its
C<fail> method invoked when the original future fails.

To invoke a C<done> method on a future when another one fails, use a CODE
reference:

   $future->on_fail( sub { $f->done( @_ ) } );

Returns the C<$future>.

=cut

=head2 cancel

   $future->cancel;

Requests that the future be cancelled, immediately marking it as ready. This
will invoke all of the code blocks registered by C<on_cancel>, in the reverse
order. When called on a convergent future, all its component futures are also
cancelled. It is not an error to attempt to cancel a future that is already
complete or cancelled; it simply has no effect.

Returns the C<$future>.

=cut

=head1 SEQUENCING METHODS

The following methods all return a new future to represent the combination of
its invocant followed by another action given by a code reference. The
combined activity waits for the first future to be ready, then may invoke the
code depending on the success or failure of the first, or may run it
regardless. The returned sequence future represents the entire combination of
activity.

The invoked code could return a future, or a result directly.

I<Since version 0.45:> if a non-future result is returned it will be wrapped
in a new immediate Future instance. This behaviour can be disabled by setting
the C<PERL_FUTURE_STRICT> environment variable to a true value at compiletime:

=for highlighter

   $ PERL_FUTURE_STRICT=1 perl ...

The combined future will then wait for the result of this second one. If the
combinined future is cancelled, it will cancel either the first future or the
second, depending whether the first had completed. If the code block throws an
exception instead of returning a value, the sequence future will fail with
that exception as its message and no further values.

Note that since the code is invoked in scalar context, you cannot directly
return a list of values this way. Any list-valued results must be done by
returning a C<Future> instance.

=for highlighter language=perl

   sub {
      ...
      return Future->done( @results );
   }

As it is always a mistake to call these sequencing methods in void context and lose the
reference to the returned future (because exception/error handling would be
silently dropped), this method warns in void context.

=cut

=head2 then

   $future = $f1->then( \&done_code );

I<Since version 0.13.>

Returns a new sequencing C<Future> that runs the code if the first succeeds.
Once C<$f1> succeeds the code reference will be invoked and is passed the list
of results. It should return a future, C<$f2>. Once C<$f2> completes the
sequence future will then be marked as complete with whatever result C<$f2>
gave. If C<$f1> fails then the sequence future will immediately fail with the
same failure and the code will not be invoked.

   $f2 = $done_code->( @result );

=head2 else

   $future = $f1->else( \&fail_code );

I<Since version 0.13.>

Returns a new sequencing C<Future> that runs the code if the first fails. Once
C<$f1> fails the code reference will be invoked and is passed the failure and
other details. It should return a future, C<$f2>. Once C<$f2> completes the
sequence future will then be marked as complete with whatever result C<$f2>
gave. If C<$f1> succeeds then the sequence future will immediately succeed
with the same result and the code will not be invoked.

   $f2 = $fail_code->( $exception, $category, @details );

=head2 then I<(2 arguments)>

   $future = $f1->then( \&done_code, \&fail_code );

The C<then> method can also be passed the C<$fail_code> block as well, giving
a combination of C<then> and C<else> behaviour.

This operation is similar to those provided by other future systems, such as
Javascript's Q or Promises/A libraries.

=cut

=head2 catch

   $future = $f1->catch(
      name => \&code,
      name => \&code, ...
   );

I<Since version 0.33.>

Returns a new sequencing C<Future> that behaves like an C<else> call which
dispatches to a choice of several alternative handling functions depending on
the kind of failure that occurred. If C<$f1> fails with a category name (i.e.
the second argument to the C<fail> call) which exactly matches one of the
string names given, then the corresponding code is invoked, being passed the
same arguments as a plain C<else> call would take, and is expected to return a
C<Future> in the same way.

   $f2 = $code->( $exception, $category, @details );

If C<$f1> does not fail, fails without a category name at all, or fails with a
category name that does not match any given to the C<catch> method, then the
returned sequence future immediately completes with the same result, and no
block of code is invoked.

If passed an odd-sized list, the final argument gives a function to invoke on
failure if no other handler matches.

   $future = $f1->catch(
      name => \&code, ...
      \&fail_code,
   );

This feature is currently still a work-in-progress. It currently can only cope
with category names that are literal strings, which are all distinct. A later
version may define other kinds of match (e.g. regexp), may specify some sort
of ordering on the arguments, or any of several other semantic extensions. For
more detail on the ongoing design, see
L<https://rt.cpan.org/Ticket/Display.html?id=103545>.

=head2 then I<(multiple arguments)>

   $future = $f1->then( \&done_code, @catch_list, \&fail_code );

I<Since version 0.33.>

The C<then> method can be passed an even-sized list inbetween the
C<$done_code> and the C<$fail_code>, with the same meaning as the C<catch>
method.

=cut

=head2 transform

   $future = $f1->transform( %args );

Returns a new sequencing C<Future> that wraps the one given as C<$f1>. With no
arguments this will be a trivial wrapper; C<$future> will complete or fail
when C<$f1> does, and C<$f1> will be cancelled when C<$future> is.

By passing the following named arguments, the returned C<$future> can be made
to behave differently to C<$f1>:

=over 8

=item done => CODE

Provides a function to use to modify the result of a successful completion.
When C<$f1> completes successfully, the result of its C<get> method is passed
into this function, and whatever it returns is passed to the C<done> method of
C<$future>

=item fail => CODE

Provides a function to use to modify the result of a failure. When C<$f1>
fails, the result of its C<failure> method is passed into this function, and
whatever it returns is passed to the C<fail> method of C<$future>.

=back

=cut

sub transform
{
   my $self = shift;
   my %args = @_;

   my $xfrm_done = $args{done};
   my $xfrm_fail = $args{fail};

   return $self->then_with_f(
      sub {
         my ( $f, @result ) = @_;
         return $f unless $xfrm_done;
         return $f->new->done( $xfrm_done->( @result ) );
      },
      sub {
         my ( $f, @failure ) = @_;
         return $f unless $xfrm_fail;
         return $f->new->fail( $xfrm_fail->( @failure ) );
      }
   );
}

=head2 then_with_f

   $future = $f1->then_with_f( ... );

I<Since version 0.21.>

Returns a new sequencing C<Future> that behaves like C<then>, but also passes
the original future, C<$f1>, to any functions it invokes.

   $f2 = $done_code->( $f1, @result );
   $f2 = $catch_code->( $f1, $category, @details );
   $f2 = $fail_code->( $f1, $category, @details );

This is useful for conditional execution cases where the code block may just
return the same result of the original future. In this case it is more
efficient to return the original future itself.

=cut

=head2 then_done

=head2 then_fail

   $future = $f->then_done( @result );

   $future = $f->then_fail( $exception, $category, @details );

I<Since version 0.22.>

Convenient shortcuts to returning an immediate future from a C<then> block,
when the result is already known.

=cut

sub then_done
{
   my $self = shift;
   my ( @result ) = @_;
   return $self->then_with_f( sub { return $_[0]->new->done( @result ) } );
}

sub then_fail
{
   my $self = shift;
   my ( @failure ) = @_;
   return $self->then_with_f( sub { return $_[0]->new->fail( @failure ) } );
}

=head2 else_with_f

   $future = $f1->else_with_f( \&code );

I<Since version 0.21.>

Returns a new sequencing C<Future> that runs the code if the first fails.
Identical to C<else>, except that the code reference will be passed both the
original future, C<$f1>, and its exception and other details.

   $f2 = $code->( $f1, $exception, $category, @details );

This is useful for conditional execution cases where the code block may just
return the same result of the original future. In this case it is more
efficient to return the original future itself.

=cut

=head2 else_done

=head2 else_fail

   $future = $f->else_done( @result );

   $future = $f->else_fail( $exception, $category, @details );

I<Since version 0.22.>

Convenient shortcuts to returning an immediate future from a C<else> block,
when the result is already known.

=cut

sub else_done
{
   my $self = shift;
   my ( @result ) = @_;
   return $self->else_with_f( sub { return $_[0]->new->done( @result ) } );
}

sub else_fail
{
   my $self = shift;
   my ( @failure ) = @_;
   return $self->else_with_f( sub { return $_[0]->new->fail( @failure ) } );
}

=head2 catch_with_f

   $future = $f1->catch_with_f( ... );

I<Since version 0.33.>

Returns a new sequencing C<Future> that behaves like C<catch>, but also passes
the original future, C<$f1>, to any functions it invokes.

=cut

=head2 followed_by

   $future = $f1->followed_by( \&code );

Returns a new sequencing C<Future> that runs the code regardless of success or
failure. Once C<$f1> is ready the code reference will be invoked and is passed
one argument, C<$f1>. It should return a future, C<$f2>. Once C<$f2> completes
the sequence future will then be marked as complete with whatever result
C<$f2> gave.

   $f2 = $code->( $f1 );

=cut

=head2 without_cancel

   $future = $f1->without_cancel;

I<Since version 0.30.>

Returns a new sequencing C<Future> that will complete with the success or
failure of the original future, but if cancelled, will not cancel the
original. This may be useful if the original future represents an operation
that is being shared among multiple sequences; cancelling one should not
prevent the others from running too.

Note that this only prevents cancel propagating from C<$future> to C<$f1>; if
the original C<$f1> instance is cancelled then the returned C<$future> will
have to be cancelled too.

Also note that for the common case of using these with convergent futures such
as L</needs_any>, the C<"also"> ability of version 0.51 may be a better
solution.

=cut

=head2 retain

   $f = $f->retain;

I<Since version 0.36.>

Creates a reference cycle which causes the future to remain in memory until
it completes. Returns the invocant future.

In normal situations, a C<Future> instance does not strongly hold a reference
to other futures that it is feeding a result into, instead relying on that to
be handled by application logic. This is normally fine because some part of
the application will retain the top-level Future, which then strongly refers
to each of its components down in a tree. However, certain design patterns,
such as mixed Future-based and legacy callback-based API styles might end up
creating Futures simply to attach callback functions to them. In that
situation, without further attention, the Future may get lost due to having no
strong references to it. Calling C<< ->retain >> on it creates such a
reference which ensures it persists until it completes. For example:

   Future->needs_all( $fA, $fB )
      ->on_done( $on_done )
      ->on_fail( $on_fail )
      ->retain;

=cut

sub retain
{
   my $self = shift;
   return $self->on_ready( sub { undef $self } );
}

=head1 CONVERGENT FUTURES

The following constructors all take a list of component futures, and return a
new future whose readiness somehow depends on the readiness of those
components. The first derived class component future will be used as the
prototype for constructing the return value, so it respects subclassing
correctly, or failing that a plain C<Future>.

Except for C<wait_all>, it is possible that the result of the convergent
future is already determined by the completion of at least one component
future while others remain pending. In this situation, any other components
that are still pending will normally be cancelled. Also, if the convergent
future itself is cancelled then all of its components will be cancelled.

I<Since version 0.51> it is possible to request that individual components
not be cancelled in this manner. Any component future prefixed with the string
C<"also"> is not cancelled when the convergent is. This is somewhat equivalent
to using L</without_cancel>, but more performant as it does not have to create
the intermediate future inbetween just for the purpose of ignoring a C<cancel>
method.

For example here, the futures C<$f3> and C<$f4> will not be cancelled, but the
other three might be:

   Future->needs_all(
      $f1,
      $f2,
      also => $f3,
      also => $f4,
      $f5,
   );

This makes it possible to observe futures in shared caches, or other
situations where there may be multiple futures waiting for the result of a
given initial component, but that component should not be cancelled just
because any particular observer is stopped.

   my $f = Future->wait_any(
      timeout_future( delay => 10 ),

      also => ( $cache{$key} //= get_key_async($key) ),
   );

   # if $f is cancelled now, its timeout is cancelled but the
   # (possibly-shared) future in the %cache hash is not.

=cut

=head2 wait_all

   $future = Future->wait_all( @subfutures );

Returns a new C<Future> instance that will indicate it is ready once all of
the sub future objects given to it indicate that they are ready, either by
success, failure or cancellation. Its result will be a list of its component
futures.

When given an empty list this constructor returns a new immediately-done
future.

This constructor would primarily be used by users of asynchronous interfaces.

=cut

=head2 wait_any

   $future = Future->wait_any( @subfutures );

Returns a new C<Future> instance that will indicate it is ready once any of
the sub future objects given to it indicate that they are ready, either by
success or failure. Any remaining component futures that are not yet ready
will be cancelled. Its result will be the result of the first component future
that was ready; either success or failure. Any component futures that are
cancelled are ignored, apart from the final component left; at which point the
result will be a failure.

When given an empty list this constructor returns an immediately-failed
future.

This constructor would primarily be used by users of asynchronous interfaces.

=cut

=head2 needs_all

   $future = Future->needs_all( @subfutures );

Returns a new C<Future> instance that will indicate it is ready once all of the
sub future objects given to it indicate that they have completed successfully,
or when any of them indicates that they have failed. If any sub future fails,
then this will fail immediately, and the remaining subs not yet ready will be
cancelled. Any component futures that are cancelled will cause an immediate
failure of the result.

If successful, its result will be a concatenated list of the results of all
its component futures, in corresponding order. If it fails, its failure will
be that of the first component future that failed. To access each component
future's results individually, use C<done_futures>.

When given an empty list this constructor returns a new immediately-done
future.

This constructor would primarily be used by users of asynchronous interfaces.

=cut

=head2 needs_any

   $future = Future->needs_any( @subfutures );

Returns a new C<Future> instance that will indicate it is ready once any of
the sub future objects given to it indicate that they have completed
successfully, or when all of them indicate that they have failed. If any sub
future succeeds, then this will succeed immediately, and the remaining subs
not yet ready will be cancelled. Any component futures that are cancelled are
ignored, apart from the final component left; at which point the result will
be a failure.

If successful, its result will be that of the first component future that
succeeded. If it fails, its failure will be that of the last component future
to fail. To access the other failures, use C<failed_futures>.

Normally when this future completes successfully, only one of its component
futures will be done. If it is constructed with multiple that are already done
however, then all of these will be returned from C<done_futures>. Users should
be careful to still check all the results from C<done_futures> in that case.

When given an empty list this constructor returns an immediately-failed
future.

This constructor would primarily be used by users of asynchronous interfaces.

=cut

=head1 METHODS ON CONVERGENT FUTURES

The following methods apply to convergent (i.e. non-leaf) futures, to access
the component futures stored by it.

=cut

=head2 pending_futures

   @f = $future->pending_futures;

=head2 ready_futures

   @f = $future->ready_futures;

=head2 done_futures

   @f = $future->done_futures;

=head2 failed_futures

   @f = $future->failed_futures;

=head2 cancelled_futures

   @f = $future->cancelled_futures;

Return a list of all the pending, ready, done, failed, or cancelled
component futures. In scalar context, each will yield the number of such
component futures.

=cut

=head1 SUBCLASSING METHODS

These methods are not intended for end-users of C<Future> instances, but
instead provided for authors of classes that subclass from C<Future> itself.

=cut

=head2 set_udata

   $future = $future->set_udata( $name, $value );

I<Since version 0.49>

Stores a Perl value within the instance, under the given name. Subclasses can
use this to store extra data that the implementation may require.

This is a safer version of attempting to use the C<$future> instance itself as
a hash reference.

=cut

=head2 udata

   $value = $future->udata( $name );

I<Since version 0.49>

Returns a Perl value from the instance that was previously set with
L</set_udata>.

=cut

=head1 TRACING METHODS

=head2 set_label

=head2 label

   $future = $future->set_label( $label );

   $label = $future->label;

I<Since version 0.28.>

Chaining mutator and accessor for the label of the C<Future>. This should be a
plain string value, whose value will be stored by the future instance for use
in debugging messages or other tooling, or similar purposes.

=cut

=head2 btime

=head2 rtime

   [ $sec, $usec ] = $future->btime;

   [ $sec, $usec ] = $future->rtime;

I<Since version 0.28.>

Accessors that return the tracing timestamps from the instance. These give the
time the instance was constructed ("birth" time, C<btime>) and the time the
result was determined (the "ready" time, C<rtime>). Each result is returned as
a two-element ARRAY ref, containing the epoch time in seconds and
microseconds, as given by C<Time::HiRes::gettimeofday>.

In order for these times to be captured, they have to be enabled by setting
C<$Future::TIMES> to a true value. This is initialised true at the time the
module is loaded if either C<PERL_FUTURE_DEBUG> or C<PERL_FUTURE_TIMES> are
set in the environment.

=cut

=head2 elapsed

   $sec = $future->elapsed;

I<Since version 0.28.>

If both tracing timestamps are defined, returns the number of seconds of
elapsed time between them as a floating-point number. If not, returns
C<undef>.

=cut

sub elapsed
{
   my $self = shift;
   return undef unless defined( my $btime = $self->btime ) and
                       defined( my $rtime = $self->rtime );
   return tv_interval( $self->btime, $self->rtime );
}

=head2 wrap_cb

   $cb = $future->wrap_cb( $operation_name, $cb );

I<Since version 0.31.>

I<Note: This method is experimental and may be changed or removed in a later
version.>

This method is invoked internally by various methods that are about to save a
callback CODE reference supplied by the user, to be invoked later. The default
implementation simply returns the callback argument as-is; the method is
provided to allow users to provide extra behaviour. This can be done by
applying a method modifier of the C<around> kind, so in effect add a chain of
wrappers. Each wrapper can then perform its own wrapping logic of the
callback. C<$operation_name> is a string giving the reason for which the
callback is being saved; currently one of C<on_ready>, C<on_done>, C<on_fail>
or C<sequence>; the latter being used for all the sequence-returning methods.

This method is intentionally invoked only for CODE references that are being
saved on a pending C<Future> instance to be invoked at some later point. It
does not run for callbacks to be invoked on an already-complete instance. This
is for performance reasons, where the intended behaviour is that the wrapper
can provide some amount of context save and restore, to return the operating
environment for the callback back to what it was at the time it was saved.

For example, the following wrapper saves the value of a package variable at
the time the callback was saved, and restores that value at invocation time
later on. This could be useful for preserving context during logging in a
Future-based program.

   our $LOGGING_CTX;

   no warnings 'redefine';

   my $orig = Future->can( "wrap_cb" );
   *Future::wrap_cb = sub {
      my $cb = $orig->( @_ );

      my $saved_logging_ctx = $LOGGING_CTX;

      return sub {
         local $LOGGING_CTX = $saved_logging_ctx;
         $cb->( @_ );
      };
   };

At this point, any code deferred into a C<Future> by any of its callbacks will
observe the C<$LOGGING_CTX> variable as having the value it held at the time
the callback was saved, even if it is invoked later on when that value is
different.

Remember when writing such a wrapper, that it still needs to invoke the
previous version of the method, so that it plays nicely in combination with
others (see the C<< $orig->( @_ ) >> part).

=cut

# Callers expect to find this in the real Future:: package
sub Future::wrap_cb
{
   my $self = shift;
   my ( $op, $cb ) = @_;
   return $cb;
}

=head1 EXAMPLES

The following examples all demonstrate possible uses of a C<Future>
object to provide a fictional asynchronous API.

For more examples, comparing the use of C<Future> with regular call/return
style Perl code, see also L<Future::Phrasebook>.

=head2 Providing Results

By returning a new C<Future> object each time the asynchronous function is
called, it provides a placeholder for its eventual result, and a way to
indicate when it is complete.

   sub foperation
   {
      my %args = @_;

      my $future = Future->new;

      do_something_async(
         foo => $args{foo},
         on_done => sub { $future->done( @_ ); },
      );

      return $future;
   }

In most cases, the C<done> method will simply be invoked with the entire
result list as its arguments. In that case, it is convenient to use the
L<curry> module to form a C<CODE> reference that would invoke the C<done>
method.

    my $future = Future->new;

    do_something_async(
       foo => $args{foo},
       on_done => $future->curry::done,
    );

The caller may then use this future to wait for a result using the C<on_ready>
method, and obtain the result using C<get>.

   my $f = foperation( foo => "something" );

   $f->on_ready( sub {
      my $f = shift;
      say "The operation returned: ", $f->result;
   } );

=head2 Indicating Success or Failure

Because the stored exception value of a failed future may not be false, the
C<failure> method can be used in a conditional statement to detect success or
failure.

   my $f = foperation( foo => "something" );

   $f->on_ready( sub {
      my $f = shift;
      if( not my $e = $f->failure ) {
         say "The operation succeeded with: ", $f->result;
      }
      else {
         say "The operation failed with: ", $e;
      }
   } );

By using C<not> in the condition, the order of the C<if> blocks can be
arranged to put the successful case first, similar to a C<try>/C<catch> block.

Because the C<get> method re-raises the passed exception if the future failed,
it can be used to control a C<try>/C<catch> block directly. (This is sometimes
called I<Exception Hoisting>).

   use Syntax::Keyword::Try;

   $f->on_ready( sub {
      my $f = shift;
      try {
         say "The operation succeeded with: ", $f->result;
      }
      catch {
         say "The operation failed with: ", $_;
      }
   } );

Even neater still may be the separate use of the C<on_done> and C<on_fail>
methods.

   $f->on_done( sub {
      my @result = @_;
      say "The operation succeeded with: ", @result;
   } );
   $f->on_fail( sub {
      my ( $failure ) = @_;
      say "The operation failed with: $failure";
   } );

=head2 Immediate Futures

Because the C<done> method returns the future object itself, it can be used to
generate a C<Future> that is immediately ready with a result. This can also be
used as a class method.

   my $f = Future->done( $value );

Similarly, the C<fail> and C<die> methods can be used to generate a C<Future>
that is immediately failed.

   my $f = Future->die( "This is never going to work" );

This could be considered similarly to a C<die> call.

An C<eval{}> block can be used to turn a C<Future>-returning function that
might throw an exception, into a C<Future> that would indicate this failure.

   my $f = eval { function() } || Future->fail( $@ );

This is neater handled by the C<call> class method, which wraps the call in
an C<eval{}> block and tests the result:

   my $f = Future->call( \&function );

=head2 Sequencing

The C<then> method can be used to create simple chains of dependent tasks,
each one executing and returning a C<Future> when the previous operation
succeeds.

   my $f = do_first()
              ->then( sub {
                 return do_second();
              })
              ->then( sub {
                 return do_third();
              });

The result of the C<$f> future itself will be the result of the future
returned by the final function, if none of them failed. If any of them fails
it will fail with the same failure. This can be considered similar to normal
exception handling in synchronous code; the first time a function call throws
an exception, the subsequent calls are not made.

=head2 Merging Control Flow

A C<wait_all> future may be used to resynchronise control flow, while waiting
for multiple concurrent operations to finish.

   my $f1 = foperation( foo => "something" );
   my $f2 = foperation( bar => "something else" );

   my $f = Future->wait_all( $f1, $f2 );

   $f->on_ready( sub {
      say "Operations are ready:";
      say "  foo: ", $f1->result;
      say "  bar: ", $f2->result;
   } );

This provides an ability somewhat similar to C<CPS::kpar()> or
L<Async::MergePoint>.

=cut

=head1 KNOWN ISSUES

=head2 Cancellation of Non-Final Sequence Futures

The behaviour of future cancellation still has some unanswered questions
regarding how to handle the situation where a future is cancelled that has a
sequence future constructed from it.

In particular, it is unclear in each of the following examples what the
behaviour of C<$f2> should be, were C<$f1> to be cancelled:

   $f2 = $f1->then( sub { ... } ); # plus related ->then_with_f, ...

   $f2 = $f1->else( sub { ... } ); # plus related ->else_with_f, ...

   $f2 = $f1->followed_by( sub { ... } );

In the C<then>-style case it is likely that this situation should be treated
as if C<$f1> had failed, perhaps with some special message. The C<else>-style
case is more complex, because it may be that the entire operation should still
fail, or it may be that the cancellation of C<$f1> should again be treated
simply as a special kind of failure, and the C<else> logic run as normal.

To be specific; in each case it is unclear what happens if the first future is
cancelled, while the second one is still waiting on it. The semantics for
"normal" top-down cancellation of C<$f2> and how it affects C<$f1> are already
clear and defined.

=head2 Cancellation of Divergent Flow

A further complication of cancellation comes from the case where a given
future is reused multiple times for multiple sequences or convergent trees.

In particular, it is in clear in each of the following examples what the
behaviour of C<$f2> should be, were C<$f1> to be cancelled:

   my $f_initial = Future->new; ...
   my $f1 = $f_initial->then( ... );
   my $f2 = $f_initial->then( ... );

   my $f1 = Future->needs_all( $f_initial );
   my $f2 = Future->needs_all( $f_initial );

The point of cancellation propagation is to trace backwards through stages of
some larger sequence of operations that now no longer need to happen, because
the final result is no longer required. But in each of these cases, just
because C<$f1> has been cancelled, the initial future C<$f_initial> is still
required because there is another future (C<$f2>) that will still require its
result.

Initially it would appear that some kind of reference-counting mechanism could
solve this question, though that itself is further complicated by the
C<on_ready> handler and its variants.

It may simply be that a comprehensive useful set of cancellation semantics
can't be universally provided to cover all cases; and that some use-cases at
least would require the application logic to give extra information to its
C<Future> objects on how they should wire up the cancel propagation logic.

Both of these cancellation issues are still under active design consideration;
see the discussion on RT96685 for more information
(L<https://rt.cpan.org/Ticket/Display.html?id=96685>).

=cut

=head1 SEE ALSO

=over 4

=item *

L<Future::AsyncAwait> - deferred subroutine syntax for futures

Provides a neat syntax extension for writing future-based code.

=item *

L<Future::IO> - Future-returning IO methods

Provides methods similar to core IO functions, which yield results by Futures.

=item *

L<Promises> - an implementation of the "Promise/A+" pattern for asynchronous
programming

A different alternative implementation of a similar idea.

=item *

L<curry> - Create automatic curried method call closures for any class or
object

=item *

"The Past, The Present and The Future" - slides from a talk given at the
London Perl Workshop, 2012.

L<https://docs.google.com/presentation/d/1UkV5oLcTOOXBXPh8foyxko4PR28_zU_aVx6gBms7uoo/edit>

=item *

"Futures advent calendar 2013"

L<http://leonerds-code.blogspot.co.uk/2013/12/futures-advent-day-1.html>

=item *

"Asynchronous Programming with Futures" - YAPC::EU 2014

L<https://www.youtube.com/watch?v=u9dZgFM6FtE>

=back

=cut

=head1 TODO

=over 4

=item *

Consider the ability to pass the constructor a C<block> CODEref, instead of
needing to use a subclass. This might simplify async/etc.. implementations,
and allows the reuse of the idea of subclassing to extend the abilities of
C<Future> itself - for example to allow a kind of Future that can report
incremental progress.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
