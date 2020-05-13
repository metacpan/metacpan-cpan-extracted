#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2015 -- leonerd@leonerd.org.uk

package IO::Async::Timer::Absolute;

use strict;
use warnings;
use base qw( IO::Async::Timer );

our $VERSION = '0.77';

use Carp;

=head1 NAME

C<IO::Async::Timer::Absolute> - event callback at a fixed future time

=head1 SYNOPSIS

 use IO::Async::Timer::Absolute;

 use POSIX qw( mktime );

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my @time = gmtime;

 my $timer = IO::Async::Timer::Absolute->new(
    time => mktime( 0, 0, 0, $time[3]+1, $time[4], $time[5] ),

    on_expire => sub {
       print "It's midnight\n";
       $loop->stop;
    },
 );

 $loop->add( $timer );

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Timer> implements one-shot events at a fixed
time in the future. The object waits for a given timestamp, and invokes its
callback at that point in the future.

For a C<Timer> object that waits for a delay relative to the time it is
started, see instead L<IO::Async::Timer::Countdown>.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_expire

Invoked when the timer expires.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 on_expire => CODE

CODE reference for the C<on_expire> event.

=head2 time => NUM

The epoch time at which the timer will expire.

Once constructed, the timer object will need to be added to the C<Loop> before
it will work.

Unlike other timers, it does not make sense to C<start> this object, because
its expiry time is absolute, and not relative to the time it is started.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{on_expire} ) {
      my $on_expire = delete $params{on_expire};
      ref $on_expire or croak "Expected 'on_expire' as a reference";

      $self->{on_expire} = $on_expire;
      undef $self->{cb}; # Will be lazily constructed when needed
   }

   if( exists $params{time} ) {
      my $time = delete $params{time};

      $self->stop if $self->is_running;

      $self->{time} = $time;

      $self->start if !$self->is_running;
   }

   unless( $self->can_event( 'on_expire' ) ) {
      croak 'Expected either a on_expire callback or an ->on_expire method';
   }

   $self->SUPER::configure( %params );
}

sub _make_cb
{
   my $self = shift;

   return $self->_capture_weakself( sub {
      my $self = shift or return;

      undef $self->{id};

      $self->invoke_event( "on_expire" );
   } );
}

sub _make_enqueueargs
{
   my $self = shift;

   return at => $self->{time};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
