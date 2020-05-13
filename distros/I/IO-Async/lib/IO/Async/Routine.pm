#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2019 -- leonerd@leonerd.org.uk

package IO::Async::Routine;

use strict;
use warnings;

our $VERSION = '0.77';

use base qw( IO::Async::Notifier );

use Carp;

use IO::Async::OS;
use IO::Async::Process;

=head1 NAME

C<IO::Async::Routine> - execute code in an independent sub-process or thread

=head1 SYNOPSIS

 use IO::Async::Routine;
 use IO::Async::Channel;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $nums_ch = IO::Async::Channel->new;
 my $ret_ch  = IO::Async::Channel->new;

 my $routine = IO::Async::Routine->new(
    channels_in  => [ $nums_ch ],
    channels_out => [ $ret_ch ],

    code => sub {
       my @nums = @{ $nums_ch->recv };
       my $ret = 0; $ret += $_ for @nums;

       # Can only send references
       $ret_ch->send( \$ret );
    },

    on_finish => sub {
       say "The routine aborted early - $_[-1]";
       $loop->stop;
    },
 );

 $loop->add( $routine );

 $nums_ch->send( [ 10, 20, 30 ] );
 $ret_ch->recv(
    on_recv => sub {
       my ( $ch, $totalref ) = @_;
       say "The total of 10, 20, 30 is: $$totalref";
       $loop->stop;
    }
 );

 $loop->run;

=head1 DESCRIPTION

This L<IO::Async::Notifier> contains a body of code and executes it in a
sub-process or thread, allowing it to act independently of the main program.
Once set up, all communication with the code happens by values passed into or
out of the Routine via L<IO::Async::Channel> objects.

A choice of detachment model is available, with options being a C<fork()>ed
child process, or a thread. In both cases the code contained within the
Routine is free to make blocking calls without stalling the rest of the
program. This makes it useful for using existing code which has no option not
to block within an L<IO::Async>-based program.

Code running inside a C<fork()>-based Routine runs within its own process; it
is isolated from the rest of the program in terms of memory, CPU time, and
other resources. Code running in a thread-based Routine however, shares memory
and other resources such as open filehandles with the main thread.

To create asynchronous wrappers of functions that return a value based only on
their arguments, and do not generally maintain state within the process it may
be more convenient to use an L<IO::Async::Function> instead, which uses an
C<IO::Async::Routine> to contain the body of the function and manages the
Channels itself.

=cut

=head1 EVENTS

=head2 on_finish $exitcode

For C<fork()>-based Routines, this is invoked after the process has exited and
is passed the raw exitcode status.

=head2 on_finish $type, @result

For thread-based Routines, this is invoked after the thread has returned from
its code block and is passed the C<on_joined> result.

As the behaviour of these events differs per model, it may be more convenient
to use C<on_return> and C<on_die> instead.

=head2 on_return $result

Invoked if the code block returns normally. Note that C<fork()>-based Routines
can only transport an integer result between 0 and 255, as this is the actual
C<exit()> value.

=head2 on_die $exception

Invoked if the code block fails with an exception.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 model => "fork" | "thread"

Optional. Defines how the routine will detach itself from the main process.
C<fork> uses a child process detached using an L<IO::Async::Process>.
C<thread> uses a thread, and is only available on threaded Perls.

If the model is not specified, the environment variable
C<IO_ASYNC_ROUTINE_MODEL> is used to pick a default. If that isn't defined,
C<fork> is preferred if it is available, otherwise C<thread>.

=head2 channels_in => ARRAY of IO::Async::Channel

ARRAY reference of L<IO::Async::Channel> objects to set up for passing values
in to the Routine.

=head2 channels_out => ARRAY of IO::Async::Channel

ARRAY reference of L<IO::Async::Channel> objects to set up for passing values
out of the Routine.

=head2 code => CODE

CODE reference to the body of the Routine, to execute once the channels are
set up.

=head2 setup => ARRAY

Optional. For C<fork()>-based Routines, gives a reference to an array to pass
to the underlying C<Loop> C<fork_child> method. Ignored for thread-based
Routines.

=cut

use constant PREFERRED_MODEL =>
   IO::Async::OS->HAVE_POSIX_FORK ? "fork" :
   IO::Async::OS->HAVE_THREADS    ? "thread" :
      die "No viable Routine models";

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $params->{model} ||= $ENV{IO_ASYNC_ROUTINE_MODEL} || PREFERRED_MODEL;

   $self->SUPER::_init( @_ );
}

sub configure
{
   my $self = shift;
   my %params = @_;

   # TODO: Can only reconfigure when not running
   foreach (qw( channels_in channels_out code setup on_finish on_return on_die )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   if( defined( my $model = delete $params{model} ) ) {
      $model eq "fork" or $model eq "thread" or
         croak "Expected 'model' to be either 'fork' or 'thread'";

      $model eq "fork" and !IO::Async::OS->HAVE_POSIX_FORK and
         croak "Cannot use 'fork' model as fork() is not available";
      $model eq "thread" and !IO::Async::OS->HAVE_THREADS and
         croak "Cannot use 'thread' model as threads are not available";

      $self->{model} = $model;
   }

   $self->SUPER::configure( %params );
}

sub _add_to_loop
{
   my $self = shift;
   my ( $loop ) = @_;
   $self->SUPER::_add_to_loop( $loop );

   return $self->_setup_fork   if $self->{model} eq "fork";
   return $self->_setup_thread if $self->{model} eq "thread";

   die "TODO: unrecognised Routine model $self->{model}";
}

sub _setup_fork
{
   my $self = shift;

   my @setup;
   my @channels_in;
   my @channels_out;

   foreach my $ch ( @{ $self->{channels_in} || [] } ) {
      my ( $rd, $wr );
      unless( $rd = $ch->_extract_read_handle ) {
         ( $rd, $wr ) = IO::Async::OS->pipepair;
      }
      push @setup, $rd => "keep";
      push @channels_in, [ $ch, $wr, $rd ];
   }

   foreach my $ch ( @{ $self->{channels_out} || [] } ) {
      my ( $rd, $wr );
      unless( $wr = $ch->_extract_write_handle ) {
         ( $rd, $wr ) = IO::Async::OS->pipepair;
      }
      push @setup, $wr => "keep";
      push @channels_out, [ $ch, $rd, $wr ];
   }

   my $code  = $self->{code};

   my $setup = $self->{setup};
   push @setup, @$setup if $setup;

   my $process = IO::Async::Process->new(
      setup => \@setup,
      code => sub {
         foreach ( @channels_in ) {
            my ( $ch, undef, $rd ) = @$_;
            $ch->setup_sync_mode( $rd );
         }
         foreach ( @channels_out ) {
            my ( $ch, undef, $wr ) = @$_;
            $ch->setup_sync_mode( $wr );
         }

         my $ret = $code->();

         foreach ( @channels_in, @channels_out ) {
            my ( $ch ) = @$_;
            $ch->close;
         }

         return $ret;
      },
      on_finish => $self->_replace_weakself( sub {
         my $self = shift or return;
         my ( $exitcode ) = @_;
         $self->maybe_invoke_event( on_finish => $exitcode );

         unless( $exitcode & 0x7f ) {
            $self->maybe_invoke_event( on_return => ($exitcode >> 8) );
            $self->result_future->done( $exitcode >> 8 );
         }
      }),
      on_exception => $self->_replace_weakself( sub {
         my $self = shift or return;
         my ( $exception, $errno, $exitcode ) = @_;

         $self->maybe_invoke_event( on_die => $exception );
         $self->result_future->fail( $exception, routine => );
      }),
   );

   foreach ( @channels_in ) {
      my ( $ch, $wr ) = @$_;

      $ch->setup_async_mode( write_handle => $wr );

      $self->add_child( $ch ) unless $ch->parent;
   }

   foreach ( @channels_out ) {
      my ( $ch, $rd ) = @$_;

      $ch->setup_async_mode( read_handle => $rd );

      $self->add_child( $ch ) unless $ch->parent;
   }

   $self->add_child( $self->{process} = $process );
   $self->{id} = "P" . $process->pid;

   foreach ( @channels_in, @channels_out ) {
      my ( undef, undef, $other ) = @$_;
      $other->close;
   }
}

sub _setup_thread
{
   my $self = shift;

   my @channels_in;
   my @channels_out;

   foreach my $ch ( @{ $self->{channels_in} || [] } ) {
      my ( $rd, $wr );
      unless( $rd = $ch->_extract_read_handle ) {
         ( $rd, $wr ) = IO::Async::OS->pipepair;
      }
      push @channels_in, [ $ch, $wr, $rd ];
   }

   foreach my $ch ( @{ $self->{channels_out} || [] } ) {
      my ( $rd, $wr );
      unless( $wr = $ch->_extract_write_handle ) {
         ( $rd, $wr ) = IO::Async::OS->pipepair;
      }
      push @channels_out, [ $ch, $rd, $wr ];
   }

   my $code = $self->{code};

   my $tid = $self->loop->create_thread(
      code => sub {
         foreach ( @channels_in ) {
            my ( $ch, $wr, $rd ) = @$_;
            $ch->setup_sync_mode( $rd );
            $wr->close if $wr;
         }
         foreach ( @channels_out ) {
            my ( $ch, $rd, $wr ) = @$_;
            $ch->setup_sync_mode( $wr );
            $rd->close if $rd;
         }

         my $ret = $code->();

         foreach ( @channels_in, @channels_out ) {
            my ( $ch ) = @$_;
            $ch->close;
         }

         return $ret;
      },
      on_joined => $self->_capture_weakself( sub {
         my $self = shift or return;
         my ( $ev, @result ) = @_;
         $self->maybe_invoke_event( on_finish => @_ );

         if( $ev eq "return" ) {
            $self->maybe_invoke_event( on_return => @result );
            $self->result_future->done( @result );
         }
         if( $ev eq "died" ) {
            $self->maybe_invoke_event( on_die => $result[0] );
            $self->result_future->fail( $result[0], routine => );
         }

         delete $self->{tid};
      }),
   );

   $self->{tid} = $tid;
   $self->{id} = "T" . $tid;

   foreach ( @channels_in ) {
      my ( $ch, $wr, $rd ) = @$_;

      $ch->setup_async_mode( write_handle => $wr );
      $rd->close;

      $self->add_child( $ch ) unless $ch->parent;
   }

   foreach ( @channels_out ) {
      my ( $ch, $rd, $wr ) = @$_;

      $ch->setup_async_mode( read_handle => $rd );
      $wr->close;

      $self->add_child( $ch ) unless $ch->parent;
   }
}

=head1 METHODS

=cut

=head2 id

   $id = $routine->id

Returns an ID string that uniquely identifies the Routine out of all the
currently-running ones. (The ID of already-exited Routines may be reused,
however.)

=cut

sub id
{
   my $self = shift;
   return $self->{id};
}

=head2 model

   $model = $routine->model

Returns the detachment model in use by the Routine.

=cut

sub model
{
   my $self = shift;
   return $self->{model};
}

=head2 kill

   $routine->kill( $signal )

Sends the specified signal to the routine code. This is either implemented by
C<CORE::kill()> or C<threads::kill> as required. Note that in the thread case
this has the usual limits of signal delivery to threads; namely, that it works
at the Perl interpreter level, and cannot actually interrupt blocking system
calls.

=cut

sub kill
{
   my $self = shift;
   my ( $signal ) = @_;

   $self->{process}->kill( $signal ) if $self->{model} eq "fork";
   threads->object( $self->{tid} )->kill( $signal ) if $self->{model} eq "thread";
}

=head2 result_future

   $f = $routine->result_future

I<Since version 0.75.>

Returns a new C<IO::Async::Future> which will complete with the eventual
return value or exception when the routine finishes.

If the routine finishes with a successful result then this will be the C<done>
result of the future. If the routine fails with an exception then this will be
the C<fail> result.

=cut

sub result_future
{
   my $self = shift;

   return $self->{result_future} //= do {
      my $f = $self->loop->new_future;
      # This future needs to strongly retain $self to ensure it definitely gets
      # notified
      $f->on_ready( sub { undef $self } );
      $f;
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
