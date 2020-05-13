#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2019 -- leonerd@leonerd.org.uk

package IO::Async::Function;

use strict;
use warnings;

our $VERSION = '0.77';

use base qw( IO::Async::Notifier );
use IO::Async::Timer::Countdown;

use Carp;

use List::Util qw( first );

use Struct::Dumb qw( readonly_struct );

readonly_struct Pending => [qw( priority f )];

=head1 NAME

C<IO::Async::Function> - call a function asynchronously

=head1 SYNOPSIS

 use IO::Async::Function;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $function = IO::Async::Function->new(
    code => sub {
       my ( $number ) = @_;
       return is_prime( $number );
    },
 );

 $loop->add( $function );

 $function->call(
    args => [ 123454321 ],
 )->on_done( sub {
    my $isprime = shift;
    print "123454321 " . ( $isprime ? "is" : "is not" ) . " a prime number\n";
 })->on_fail( sub {
    print STDERR "Cannot determine if it's prime - $_[0]\n";
 })->get;

=head1 DESCRIPTION

This subclass of L<IO::Async::Notifier> wraps a function body in a collection
of worker processes, to allow it to execute independently of the main process.
The object acts as a proxy to the function, allowing invocations to be made by
passing in arguments, and invoking a continuation in the main process when the
function returns.

The object represents the function code itself, rather than one specific
invocation of it. It can be called multiple times, by the C<call> method.
Multiple outstanding invocations can be called; they will be dispatched in
the order they were queued. If only one worker process is used then results
will be returned in the order they were called. If multiple are used, then
each request will be sent in the order called, but timing differences between
each worker may mean results are returned in a different order.

Since the code block will be called multiple times within the same child
process, it must take care not to modify any of its state that might affect
subsequent calls. Since it executes in a child process, it cannot make any
modifications to the state of the parent program. Therefore, all the data
required to perform its task must be represented in the call arguments, and
all of the result must be represented in the return values.

The Function object is implemented using an L<IO::Async::Routine> with two
L<IO::Async::Channel> objects to pass calls into and results out from it.

The L<IO::Async> framework generally provides mechanisms for multiplexing IO
tasks between different handles, so there aren't many occasions when such an
asynchronous function is necessary. Two cases where this does become useful
are:

=over 4

=item 1.

When a large amount of computationally-intensive work needs to be performed
(for example, the C<is_prime> test in the example in the C<SYNOPSIS>).

=item 2.

When a blocking OS syscall or library-level function needs to be called, and
no nonblocking or asynchronous version is supplied. This is used by
L<IO::Async::Resolver>.

=back

This object is ideal for representing "pure" functions; that is, blocks of
code which have no stateful effect on the process, and whose result depends
only on the arguments passed in. For a more general co-routine ability, see
also L<IO::Async::Routine>.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 code => CODE

The body of the function to execute.

 @result = $code->( @args )

=head2 init_code => CODE

Optional. If defined, this is invoked exactly once in every child process or
thread, after it is created, but before the first invocation of the function
body itself.

 $init_code->()

=head2 model => "fork" | "thread"

Optional. Requests a specific L<IO::Async::Routine> model. If not supplied,
leaves the default choice up to Routine.

=head2 min_workers => INT

=head2 max_workers => INT

The lower and upper bounds of worker processes to try to keep running. The
actual number running at any time will be kept somewhere between these bounds
according to load.

=head2 max_worker_calls => INT

Optional. If provided, stop a worker process after it has processed this
number of calls. (New workers may be started to replace stopped ones, within
the bounds given above).

=head2 idle_timeout => NUM

Optional. If provided, idle worker processes will be shut down after this
amount of time, if there are more than C<min_workers> of them.

=head2 exit_on_die => BOOL

Optional boolean, controls what happens after the C<code> throws an
exception. If missing or false, the worker will continue running to process
more requests. If true, the worker will be shut down. A new worker might be
constructed by the C<call> method to replace it, if necessary.

=head2 setup => ARRAY

Optional array reference. Specifies the C<setup> key to pass to the underlying
L<IO::Async::Process> when setting up new worker processes.

=cut

sub _init
{
   my $self = shift;
   $self->SUPER::_init( @_ );

   $self->{min_workers} = 1;
   $self->{max_workers} = 8;

   $self->{workers} = {}; # {$id} => IaFunction:Worker

   $self->{pending_queue} = [];
}

sub configure
{
   my $self = shift;
   my %params = @_;

   my %worker_params;
   foreach (qw( model exit_on_die max_worker_calls )) {
      $self->{$_} = $worker_params{$_} = delete $params{$_} if exists $params{$_};
   }

   if( keys %worker_params ) {
      foreach my $worker ( $self->_worker_objects ) {
         $worker->configure( %worker_params );
      }
   }

   if( exists $params{idle_timeout} ) {
      my $timeout = delete $params{idle_timeout};
      if( !$timeout ) {
         $self->remove_child( delete $self->{idle_timer} ) if $self->{idle_timer};
      }
      elsif( my $idle_timer = $self->{idle_timer} ) {
         $idle_timer->configure( delay => $timeout );
      }
      else {
         $self->{idle_timer} = IO::Async::Timer::Countdown->new(
            delay => $timeout,
            on_expire => $self->_capture_weakself( sub {
               my $self = shift or return;
               my $workers = $self->{workers};

               # Shut down atmost one idle worker, starting from the highest
               # ID. Since we search from lowest to assign work, this tries
               # to ensure we'll shut down the least useful ones first,
               # keeping more useful ones in memory (page/cache warmth, etc..)
               foreach my $id ( reverse sort keys %$workers ) {
                  next if $workers->{$id}{busy};

                  $workers->{$id}->stop;
                  last;
               }

               # Still more?
               $self->{idle_timer}->start if $self->workers_idle > $self->{min_workers};
            } ),
         );
         $self->add_child( $self->{idle_timer} );
      }
   }

   foreach (qw( min_workers max_workers )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
      # TODO: something about retuning
   }

   my $need_restart;

   foreach (qw( init_code code setup )) {
      $need_restart++, $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   $self->SUPER::configure( %params );

   if( $need_restart and $self->loop ) {
      $self->stop;
      $self->start;
   }
}

sub _add_to_loop
{
   my $self = shift;
   $self->SUPER::_add_to_loop( @_ );

   $self->start;
}

sub _remove_from_loop
{
   my $self = shift;

   $self->stop;

   $self->SUPER::_remove_from_loop( @_ );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 start

   $function->start

Start the worker processes

=cut

sub start
{
   my $self = shift;

   $self->_new_worker for 1 .. $self->{min_workers};
}

=head2 stop

   $function->stop

Stop the worker processes

   $f = $function->stop

I<Since version 0.75.>

If called in non-void context, returns a L<IO::Async::Future> instance that
will complete once every worker process has stopped and exited. This may be
useful for waiting until all of the processes are waited on, or other
edge-cases, but is not otherwise particularly useful.

=cut

sub stop
{
   my $self = shift;

   $self->{stopping} = 1;

   my @f;

   foreach my $worker ( $self->_worker_objects ) {
      defined wantarray ? push @f, $worker->stop : $worker->stop;
   }

   return Future->needs_all( @f ) if defined wantarray;
}

=head2 restart

   $function->restart

Gracefully stop and restart all the worker processes. 

=cut

sub restart
{
   my $self = shift;

   $self->stop;
   $self->start;
}

=head2 call

   @result = $function->call( %params )->get

Schedules an invocation of the contained function to be executed on one of the
worker processes. If a non-busy worker is available now, it will be called
immediately. If not, it will be queued and sent to the next free worker that
becomes available.

The request will already have been serialised by the marshaller, so it will be
safe to modify any referenced data structures in the arguments after this call
returns.

The C<%params> hash takes the following keys:

=over 8

=item args => ARRAY

A reference to the array of arguments to pass to the code.

=item priority => NUM

Optional. Defines the sorting order when no workers are available and calls
must be queued for later. A default of zero will apply if not provided.

Higher values cause the call to be considered more important, and will be
placed earlier in the queue than calls with a smaller value. Calls of equal
priority are still handled in FIFO order.

=back

If the function body returns normally the list of results are provided as the
(successful) result of returned future. If the function throws an exception
this results in a failed future. In the special case that the exception is in
fact an unblessed C<ARRAY> reference, this array is unpacked and used as-is
for the C<fail> result. If the exception is not such a reference, it is used
as the first argument to C<fail>, in the category of C<error>.

   $f->done( @result )

   $f->fail( @{ $exception } )
   $f->fail( $exception, error => )

=head2 call (void)

   $function->call( %params )

When not returning a future, the C<on_result>, C<on_return> and C<on_error>
arguments give continuations to handle successful results or failure.

=over 8

=item on_result => CODE

A continuation that is invoked when the code has been executed. If the code
returned normally, it is called as:

 $on_result->( 'return', @values )

If the code threw an exception, or some other error occurred such as a closed
connection or the process died, it is called as:

 $on_result->( 'error', $exception_name )

=item on_return => CODE and on_error => CODE

An alternative to C<on_result>. Two continuations to use in either of the
circumstances given above. They will be called directly, without the leading
'return' or 'error' value.

=back

=cut

sub debug_printf_call
{
   my $self = shift;
   $self->debug_printf( "CALL" );
}

sub debug_printf_result
{
   my $self = shift;
   $self->debug_printf( "RESULT" );
}

sub debug_printf_failure
{
   my $self = shift;
   my ( $err ) = @_;
   $self->debug_printf( "FAIL $err" );
}

sub call
{
   my $self = shift;
   my %params = @_;

   # TODO: possibly just queue this?
   $self->loop or croak "Cannot ->call on a Function not yet in a Loop";

   my $args = delete $params{args};
   ref $args eq "ARRAY" or croak "Expected 'args' to be an array";

   my ( $on_done, $on_fail );
   if( defined $params{on_result} ) {
      my $on_result = delete $params{on_result};
      ref $on_result or croak "Expected 'on_result' to be a reference";

      $on_done = sub {
         $on_result->( return => @_ );
      };
      $on_fail = sub {
         my ( $err, @values ) = @_;
         $on_result->( error => @values );
      };
   }
   elsif( defined $params{on_return} and defined $params{on_error} ) {
      my $on_return = delete $params{on_return};
      ref $on_return or croak "Expected 'on_return' to be a reference";
      my $on_error  = delete $params{on_error};
      ref $on_error or croak "Expected 'on_error' to be a reference";

      $on_done = $on_return;
      $on_fail = $on_error;
   }
   elsif( !defined wantarray ) {
      croak "Expected either 'on_result' or 'on_return' and 'on_error' keys, or to return a Future";
   }

   $self->debug_printf_call( @$args );

   my $request = IO::Async::Channel->encode( $args );

   my $future;
   if( my $worker = $self->_get_worker ) {
      $future = $self->_call_worker( $worker, $request );
   }
   else {
      $self->debug_printf( "QUEUE" );
      my $queue = $self->{pending_queue};

      my $next = Pending(
         my $priority = $params{priority} || 0,
         my $wait_f = $self->loop->new_future,
      );

      if( $priority ) {
         my $idx = first { $queue->[$_]->priority < $priority } 0 .. $#$queue;
         splice @$queue, $idx // $#$queue+1, 0, ( $next );
      }
      else {
         push @$queue, $next;
      }

      $future = $wait_f->then( sub {
         my ( $self, $worker ) = @_;
         $self->_call_worker( $worker, $request );
      });
   }

   $future->on_done( $self->_capture_weakself( sub {
      my $self = shift or return;
      $self->debug_printf_result( @_ );
   }));
   $future->on_fail( $self->_capture_weakself( sub {
      my $self = shift or return;
      $self->debug_printf_failure( @_ );
   }));

   $future->on_done( $on_done ) if $on_done;
   $future->on_fail( $on_fail ) if $on_fail;

   return $future if defined wantarray;

   # Caller is not going to keep hold of the Future, so we have to ensure it
   # stays alive somehow
   $self->adopt_future( $future->else( sub { Future->done } ) );
}

sub _worker_objects
{
   my $self = shift;
   return values %{ $self->{workers} };
}

=head2 workers

   $count = $function->workers

Returns the total number of worker processes available

=cut

sub workers
{
   my $self = shift;
   return scalar keys %{ $self->{workers} };
}

=head2 workers_busy

   $count = $function->workers_busy

Returns the number of worker processes that are currently busy

=cut

sub workers_busy
{
   my $self = shift;
   return scalar grep { $_->{busy} } $self->_worker_objects;
}

=head2 workers_idle

   $count = $function->workers_idle

Returns the number of worker processes that are currently idle

=cut

sub workers_idle
{
   my $self = shift;
   return scalar grep { !$_->{busy} } $self->_worker_objects;
}

sub _new_worker
{
   my $self = shift;

   my $worker = IO::Async::Function::Worker->new(
      ( map { $_ => $self->{$_} } qw( model init_code code setup exit_on_die ) ),
      max_calls => $self->{max_worker_calls},

      on_finish => $self->_capture_weakself( sub {
         my $self = shift or return;
         my ( $worker ) = @_;

         return if $self->{stopping};

         $self->_new_worker if $self->workers < $self->{min_workers};

         $self->_dispatch_pending;
      } ),
   );

   $self->add_child( $worker );

   return $self->{workers}{$worker->id} = $worker;
}

sub _get_worker
{
   my $self = shift;

   foreach ( sort keys %{ $self->{workers} } ) {
      return $self->{workers}{$_} if !$self->{workers}{$_}{busy};
   }

   if( $self->workers < $self->{max_workers} ) {
      return $self->_new_worker;
   }

   return undef;
}

sub _call_worker
{
   my $self = shift;
   my ( $worker, $type, $args ) = @_;

   my $future = $worker->call( $type, $args );

   if( $self->workers_idle == 0 ) {
      $self->{idle_timer}->stop if $self->{idle_timer};
   }

   return $future;
}

sub _dispatch_pending
{
   my $self = shift;

   while( my $next = shift @{ $self->{pending_queue} } ) {
      my $worker = $self->_get_worker or return;

      my $f = $next->f;

      next if $f->is_cancelled;

      $self->debug_printf( "UNQUEUE" );
      $f->done( $self, $worker );
      return;
   }

   if( $self->workers_idle > $self->{min_workers} ) {
      $self->{idle_timer}->start if $self->{idle_timer} and !$self->{idle_timer}->is_running;
   }
}

package # hide from indexer
   IO::Async::Function::Worker;

use base qw( IO::Async::Routine );

use IO::Async::Channel;

sub new
{
   my $class = shift;
   my %params = @_;

   my $arg_channel = IO::Async::Channel->new;
   my $ret_channel = IO::Async::Channel->new;

   my $init = delete $params{init_code};
   my $code = delete $params{code};
   $params{code} = sub {
      $init->() if defined $init;

      while( my $args = $arg_channel->recv ) {
         my @ret;
         my $ok = eval { @ret = $code->( @$args ); 1 };

         if( $ok ) {
            $ret_channel->send( [ r => @ret ] );
         }
         elsif( ref $@ ) {
            # Presume that $@ is an ARRAYref of error results
            $ret_channel->send( [ e => @{ $@ } ] );
         }
         else {
            chomp( my $e = "$@" );
            $ret_channel->send( [ e => $e, error => ] );
         }
      }
   };

   my $worker = $class->SUPER::new(
      %params,
      channels_in  => [ $arg_channel ],
      channels_out => [ $ret_channel ],
   );

   $worker->{arg_channel} = $arg_channel;
   $worker->{ret_channel} = $ret_channel;

   return $worker;
}

sub configure
{
   my $self = shift;
   my %params = @_;

   exists $params{$_} and $self->{$_} = delete $params{$_} for qw( exit_on_die max_calls );

   $self->SUPER::configure( %params );
}

sub stop
{
   my $worker = shift;
   $worker->{arg_channel}->close;

   my $ret;
   $ret = $worker->result_future if defined wantarray;

   if( my $function = $worker->parent ) {
      delete $function->{workers}{$worker->id};

      if( $worker->{busy} ) {
         $worker->{remove_on_idle}++;
      }
      else {
         $function->remove_child( $worker );
      }
   }

   return $ret;
}

sub call
{
   my $worker = shift;
   my ( $args ) = @_;

   $worker->{arg_channel}->send_encoded( $args );

   $worker->{busy} = 1;
   $worker->{max_calls}--;

   return $worker->{ret_channel}->recv->then(
      # on recv
      $worker->_capture_weakself( sub {
         my ( $worker, $result ) = @_;
         my ( $type, @values ) = @$result;

         $worker->stop if !$worker->{max_calls} or
                          $worker->{exit_on_die} && $type eq "e";

         if( $type eq "r" ) {
            return Future->done( @values );
         }
         elsif( $type eq "e" ) {
            return Future->fail( @values );
         }
         else {
            die "Unrecognised type from worker - $type\n";
         }
      } ),
      # on EOF
      $worker->_capture_weakself( sub {
         my ( $worker ) = @_;

         $worker->stop;

         return Future->fail( "closed", "closed" );
      } )
   )->on_ready( $worker->_capture_weakself( sub {
      my ( $worker, $f ) = @_;
      $worker->{busy} = 0;

      my $function = $worker->parent;
      $function->_dispatch_pending if $function;

      $function->remove_child( $worker ) if $function and $worker->{remove_on_idle};
   }));
}

=head1 EXAMPLES

=head2 Extended Error Information on Failure

The array-unpacking form of exception indiciation allows the function body to
more precicely control the resulting failure from the C<call> future.

 my $divider = IO::Async::Function->new(
    code => sub {
       my ( $numerator, $divisor ) = @_;
       $divisor == 0 and
          die [ "Cannot divide by zero", div_zero => $numerator, $divisor ];

       return $numerator / $divisor;
    }
 );

=head1 NOTES

For the record, 123454321 is 11111 * 11111, a square number, and therefore not
prime.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
