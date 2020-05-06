#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2020 -- leonerd@leonerd.org.uk

package IO::Async::Loop::IO::Async;

use strict;
use warnings;

our $VERSION = '0.03';
use constant API_VERSION => '0.76';

use base qw( IO::Async::Loop );
IO::Async::Loop->VERSION( 0.49 );

use Carp;

use Scalar::Util qw( weaken );

use IO::Async::Notifier;
use IO::Async::Handle;
use IO::Async::Timer::Absolute;
use IO::Async::Signal;
use IO::Async::PID;

=head1 NAME

C<IO::Async::Loop::IO::Async> - use C<IO::Async> with C<IO::Async>

=head1 SYNOPSIS

   use IO::Async::Loop::IO::Async;

   my $loop = IO::Async::Loop::IO::Async->new();

   $loop->add( ... );

   $loop->add( IO::Async::Signal->new(
         name => 'HUP',
         on_receipt => sub { ... },
   ) );

   $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses another instance of an
C<IO::Async::Loop> object as its underlying implementation. While this at
first appears to be pointless, this module distribution is not primarily
intended to serve a useful purpose for end-users. Rather, it stands as a real
code example, for authors of other modules to use for reference.

=head2 For C<IO::Async::Loop::*> Authors

Authors of other subclasses to implement C<IO::Async::Loop> subclasses may
find this distribution useful as a template. By copying the code and replacing
the contents of the various C<watch_*> and C<unwatch_*> methods, a Loop
implementation can be built making use of some other event system or
underlying kernel blocking primative.

=head2 For Authors of Other Event Systems

Authors of implementations in other event systems wishing to support running
their event system on top of L<IO::Async> may find this distribution useful to
read a way to implement the various underlying behaviours, such as watching
filehandles and timers. Examples in each of the C<watch_*> and C<unwatch_*>
methods may be useful to demonstrate the sort of code that might be required
to attach some other event system on top of C<IO::Async>.

=head1 CONSTRUCTOR

=cut

=head2 new

   $loop = IO::Async::Loop::IO::Async->new()

This function returns a new instance of a C<IO::Async::Loop::IO::Async> object.

=cut

sub new
{
   my $class = shift;
   my ( %args ) = @_;

   my $self = $class->SUPER::__new( %args );

   $self->{root_notifier} = IO::Async::Notifier->new;

   return $self;
}

=head1 METHODS

=cut

=head2 parent_loop

   $loop->parent_loop( $parent )

   $parent = $loop->parent_loop

Accessor for the underlying C<IO::Async::Loop> that this loop will use. If one
is not provided by the time that C<loop_once> is first invoked, one will be
constructed using the normal C<< IO::Async::Loop->new >> constructor. This
method may be used to access it after that.

=cut

sub parent_loop
{
   my $self = shift;
   my ( $loop ) = @_;

   $self->{parent_loop} = $loop if $loop;

   $self->{parent_loop} ||= do {
      my $loop = IO::Async::Loop->new;
      $loop->add( $self->{root_notifier} );
      $loop;
   };

   return $self->{parent_loop};
}

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   $self->parent_loop->loop_once( $timeout );
}

sub watch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";

   my $ioa_handle = $self->{handles}{$handle} ||= do {
      my $h = IO::Async::Handle->new;
      $self->{root_notifier}->add_child( $h );
      $h;
   };

   if( my $on_read_ready = $params{on_read_ready} ) {
      $ioa_handle->configure(
         read_handle => $handle,
         on_read_ready => $on_read_ready,
      );
      $ioa_handle->want_readready( 1 );
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      $ioa_handle->configure(
         write_handle => $handle,
         on_write_ready => $on_write_ready,
      );
      $ioa_handle->want_writeready( 1 );
   }
}

sub unwatch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";

   my $ioa_handle = $self->{handles}{$handle} or return;

   if( $params{on_read_ready} ) {
      $ioa_handle->want_readready( 0 );
      $ioa_handle->configure(
         read_handle => undef,
         on_read_ready => undef,
      );
   }

   if( $params{on_write_ready} ) {
      $ioa_handle->want_writeready( 0 );
      $ioa_handle->configure(
         write_handle => undef,
         on_write_ready => undef,
      );
   }

   if( !$ioa_handle->want_readready and !$ioa_handle->want_writeready ) {
      $self->{root_notifier}->remove_child( $ioa_handle );
      delete $self->{handles}{$handle};
   }
}

sub watch_time
{
   my $self = shift;
   my %params = @_;

   my $code = $params{code} or croak "Expected 'code' as CODE ref";

   my $time;
   if( defined $params{at} ) {
      $time = $params{at};
   }
   elsif( defined $params{after} ) {
      my $now = $params{now} || $self->time;
      $time = $now + $params{after};
   }
   else {
      croak "Expected one of 'at' or 'after'; got @_";
   }

   my $timer = IO::Async::Timer::Absolute->new(
      time => $time,
      on_expire => $code,
   );

   $self->{root_notifier}->add_child( $timer );

   return $timer;
}

sub unwatch_time
{
   my $self = shift;
   my ( $timer ) = @_;

   $timer->stop if $timer->get_loop;
   $self->{root_notifier}->remove_child( $timer );
}

sub watch_signal
{
   my $self = shift;
   my ( $signal, $code ) = @_;

   my $ioa_signal = IO::Async::Signal->new(
      name => $signal,
      on_receipt => $code,
   );

   $self->{signals}{$signal} = $ioa_signal;

   $self->{root_notifier}->add_child( $ioa_signal );
}

sub unwatch_signal
{
   my $self = shift;
   my ( $signal ) = @_;

   $self->{root_notifier}->remove_child( delete $self->{signals}{$signal} );
}

sub watch_idle
{
   my $self = shift;
   my %params = @_;

   my $code = $params{code} or croak "Expected 'code' as CODE ref";

   my $when = $params{when} or croak "Expected 'when'";

   $when eq "later" or croak "Expected 'when' to be 'later'";

   # TODO: Find a nice way to do this that isn't cheating
   return $self->parent_loop->watch_idle(
      when => "later",
      code => $code,
   );
}

sub unwatch_idle
{
   my $self = shift;
   my ( $id ) = @_;

   $self->parent_loop->unwatch_idle( $id );
}

sub watch_process
{
   my $self = shift;
   my ( $pid, $code ) = @_;

   # Some more cheating
   if( $pid == 0 ) {
      $self->parent_loop->watch_process( 0, $code );
      return;
   }

   weaken( my $weakself = $self );

   my $ioa_pid = IO::Async::PID->new(
      pid => $pid,
      on_exit => sub {
         my ( undef, $exitstatus ) = @_;

         $code->( $pid, $exitstatus );

         delete $weakself->{pids}{$pid};
      }
   );

   $self->{pids}{$pid} = $ioa_pid;

   $self->{root_notifier}->add_child( $ioa_pid );
}

sub unwatch_process
{
   my $self = shift;
   my ( $pid ) = @_;

   if( $pid == 0 ) {
      $self->parent_loop->unwatch_process( 0 );
   }

   $self->{root_notifier}->remove_child( delete $self->{pids}{$pid} );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
