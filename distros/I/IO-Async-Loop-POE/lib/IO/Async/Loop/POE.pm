#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2012 -- leonerd@leonerd.org.uk

package IO::Async::Loop::POE;

use strict;
use warnings;

our $VERSION = '0.05';
use constant API_VERSION => '0.49';

use base qw( IO::Async::Loop );
IO::Async::Loop->VERSION( '0.49' );

use Carp;

use POE::Kernel 1.293;
use POE::Session;

# Placate POE warning that we didn't call this
# It won't do anything yet as we have no sessions
POE::Kernel->run();

=head1 NAME

C<IO::Async::Loop::POE> - use C<IO::Async> with C<POE>

=head1 SYNOPSIS

 use IO::Async::Loop::POE;

 my $loop = IO::Async::Loop::POE->new();

 $loop->add( ... );

 $loop->add( IO::Async::Signal->new(
       name => 'HUP',
       on_receipt => sub { ... },
 ) );

 $loop->loop_forever();

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses L<POE> to perform its work.

The entire C<IO::Async> system is represented by a single long-lived session
within the C<POE> core. It fully supports sharing the process space with
C<POE>; such resources as signals are properly shared between both event
systems.

=head1 CONSTRUCTOR

=cut

=head2 $loop = IO::Async::Loop::POE->new( %args )

This function returns a new instance of a C<IO::Async::Loop::POE> object.
It takes the following named arguments:

=over 8

=back

=cut

sub new
{
   my $class = shift;
   my ( %args ) = @_;

   my $self = $class->SUPER::__new( %args );

   my $kernelref = \($self->{kernel} = undef);

   $self->{session} = POE::Session->create(
      inline_states => {
         _start => sub {
            $_[KERNEL]->alias_set( "IO::Async" );
            $$kernelref = $_[KERNEL];
         },

         invoke => sub {
            # CODEref is always in the last position, but what that is varies
            # given the different events use different initial args
            $_[-1]->();
         },

         select_read => sub {
            $_[KERNEL]->select_read( $_[ARG0], invoke => $_[ARG1] );
         },
         unselect_read => sub {
            $_[KERNEL]->select_read( $_[ARG0] );
         },
         select_write => sub {
            $_[KERNEL]->select_write( $_[ARG0], invoke => $_[ARG1] );
         },
         unselect_write => sub {
            $_[KERNEL]->select_write( $_[ARG0] );
         },

         alarm_set => sub {
            $_[KERNEL]->alarm_set( invoke => $_[ARG0], $_[ARG1] );
         },
         delay_set => sub {
            $_[KERNEL]->delay_set( invoke => $_[ARG0], $_[ARG1] );
         },
         alarm_remove => sub {
            $_[KERNEL]->alarm_remove( $_[ARG0] );
         },

         sig => sub {
            $_[KERNEL]->sig( $_[ARG0], ( $_[ARG0] eq "CHLD" ) ? "invoke_child" : "invoke_signal", $_[ARG1] );
         },
         unsig => sub {
            $_[KERNEL]->sig( $_[ARG0] );
         },
         invoke_signal => sub {
            $_[-1]->();
            $_[KERNEL]->sig_handled;
         },

         sig_child => sub {
            $_[KERNEL]->sig_child( $_[ARG0], invoke_child => $_[ARG1] );
         },
         unsig_child => sub {
            $_[KERNEL]->sig_child( $_[ARG0] );
         },
         invoke_child => sub {
            $_[-1]->( $_[ARG1], $_[ARG2] ); # $pid, $dollarq
         },
      }
   );

   return $self;
}

sub _call
{
   my $self = shift;
   $self->{kernel}->call( $self->{session}, @_ );
}

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   if( defined $timeout and $timeout == 0 ) {
      $self->{kernel}->run_one_timeslice;
      return;
   }

   my $timer_id;
   if( defined $timeout ) {
      $timer_id = $self->_call( delay_set => $timeout, sub { } );
   }

   $self->{kernel}->run_one_timeslice;

   $self->_call( alarm_remove => $timer_id );
}

sub watch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";

   if( my $on_read_ready = $params{on_read_ready} ) {
      $self->_call( select_read => $handle, $on_read_ready );
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      $self->_call( select_write => $handle, $on_write_ready );
   }
}

sub unwatch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";

   if( my $on_read_ready = $params{on_read_ready} ) {
      $self->_call( unselect_read => $handle );
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      $self->_call( unselect_write => $handle );
   }
}

sub watch_time
{
   my $self = shift;
   my %params = @_;

   my $code = $params{code} or croak "Expected 'code' as CODE ref";

   if( defined $params{at} ) {
      return $self->_call( alarm_set => $params{at}, $code );
   }
   elsif( defined $params{after} ) {
      return $self->_call( delay_set => $params{after}, $code );
   }
   else {
      croak "Expected either 'at' or 'after'";
   }
}

sub unwatch_time
{
   my $self = shift;
   my ( $id ) = @_;

   $self->_call( alarm_remove => $id );
}

sub watch_signal
{
   my $self = shift;
   my ( $signal, $code ) = @_;

   exists $SIG{$signal} or croak "Cannot watch signal '$signal' - bad signal name";

   $self->_call( sig => $signal, $code );
}

sub unwatch_signal
{
   my $self = shift;
   my ( $signal ) = @_;

   $self->_call( unsig => $signal );
}

sub watch_idle
{
   my $self = shift;
   my %params = @_;

   my $when = delete $params{when} or croak "Expected 'when'";

   my $code = delete $params{code} or croak "Expected 'code' as a CODE ref";

   $when eq "later" or croak "Expected 'when' to be 'later'";

   return $self->_call( delay_set => 0, $code );
}

sub unwatch_idle
{
   my $self = shift;
   my ( $id ) = @_;

   $self->_call( alarm_remove => $id );
}

sub watch_child
{
   my $self = shift;
   my ( $pid, $code ) = @_;

   if( $pid ) {
      $self->_call( sig_child => $pid, $code );
   }
   else {
      $self->_call( sig => "CHLD", $code );
   }
}

sub unwatch_child
{
   my $self = shift;
   my ( $pid ) = @_;

   if( $pid ) {
      $self->_call( unsig_child => $pid );
   }
   else {
      $self->_call( unsig => "CHLD" );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
