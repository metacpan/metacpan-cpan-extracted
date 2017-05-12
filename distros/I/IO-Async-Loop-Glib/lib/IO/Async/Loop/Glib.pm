#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2013 -- leonerd@leonerd.org.uk

package IO::Async::Loop::Glib;

use strict;
use warnings;

our $VERSION = '0.21';
use constant API_VERSION => '0.49';

use base qw( IO::Async::Loop );
IO::Async::Loop->VERSION( '0.49' );

use Carp;

use Glib;

=head1 NAME

C<IO::Async::Loop::Glib> - use C<IO::Async> with F<Glib> or F<GTK>

=head1 SYNOPSIS

 use IO::Async::Loop::Glib;

 my $loop = IO::Async::Loop::Glib->new();

 $loop->add( ... );

 ...
 # Rest of GLib/Gtk program that uses GLib

 Glib::MainLoop->new->run();

Or

 $loop->loop_forever();

Or

 while(1) {
    $loop->loop_once();
 }

=head1 DESCRIPTION

This subclass of C<IO::Async::Loop> uses the C<Glib::MainLoop> to perform
read-ready and write-ready tests.

The appropriate C<Glib::IO> sources are added or removed from the
C<Glib::MainLoop> when notifiers are added or removed from the set, or when
they change their C<want_writeready> status. The callbacks are called
automatically by Glib itself; no special methods on this loop object are
required.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $loop = IO::Async::Loop::Glib->new()

This function returns a new instance of a C<IO::Async::Loop::Glib> object. It
takes no special arguments.

=cut

sub new
{
   my $class = shift;
   my ( %args ) = @_;

   my $self = $class->__new( %args );

   $self->{sourceid} = {};  # {$fd} -> [ $readid, $writeid, $hangupid ]

   return $self;
}

sub __new_feature
{
   my $self = shift;
   my ( $classname ) = @_;

   # veto IO::Async::TimeQueue since we implement its methods locally
   die __PACKAGE__." implements $classname internally" 
      if grep { $_ eq $classname } qw( IO::Async::TimeQueue );

   return $self->SUPER::__new_feature( $classname );
}

=head1 METHODS

There are no special methods in this subclass, other than those provided by
the C<IO::Async::Loop> base class.

=cut

sub watch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or croak "Expected 'handle'";
   my $fd = $handle->fileno;

   # TODO: Investigate if the following can be made more efficient by
   # installing just one source on all the masks, and detecting the particular
   # event bits within the callback

   my $sourceids = ( $self->{sourceid}->{$fd} ||= [] );

   if( my $on_read_ready = $params{on_read_ready} ) {
      Glib::Source->remove( $sourceids->[0] ) if defined $sourceids->[0];

      $sourceids->[0] = Glib::IO->add_watch( $fd,
         ['in', 'hup', 'err'],
         sub {
            $on_read_ready->();
            # Must yield true value or else GLib will remove this IO source
            return 1;
         }
      );
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      Glib::Source->remove( $sourceids->[1] ) if defined $sourceids->[1];

      $sourceids->[1] = Glib::IO->add_watch( $fd,
         ['out', 'hup', 'err'],
         sub {
            $on_write_ready->();
            # Must yield true value or else GLib will remove this IO source
            return 1;
         }
      );
   }

   if( my $on_hangup = $params{on_hangup} ) {
      $self->_CAN_ON_HANGUP or croak "Cannot watch_io for 'on_hangup' in ".ref($self);

      Glib::Source->remove( $sourceids->[2] ) if defined $sourceids->[2];

      $sourceids->[2] = Glib::IO->add_watch( $fd,
         ['hup'],
         sub {
            $on_hangup->();
            # Must yield true value or else GLib will remove this IO source
            return 1;
         }
      );
   }
}

sub unwatch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or croak "Expected 'handle'";
   my $fd = $handle->fileno;

   my $sourceids = $self->{sourceid}->{$fd} or return;

   if( $params{on_read_ready} ) {
      Glib::Source->remove( $sourceids->[0] ) if defined $sourceids->[0];
      undef $sourceids->[0];
   }

   if( $params{on_write_ready} ) {
      Glib::Source->remove( $sourceids->[1] ) if defined $sourceids->[1];
      undef $sourceids->[1];
   }

   if( $params{on_hangup} ) {
      $self->_CAN_ON_HANGUP or croak "Cannot watch_io for 'on_hangup' in ".ref($self);

      Glib::Source->remove( $sourceids->[2] ) if defined $sourceids->[2];
      undef $sourceids->[2];
   }

   delete $self->{sourceids}->{$fd} if not $sourceids->[0] and not $sourceids->[1] and not $sourceids->[2];
}

sub watch_time
{
   my $self = shift;
   my ( %params ) = @_;

   # Just let GLib handle all these timer events
   my $delay;
   if( exists $params{at} ) {
      my $now = exists $params{now} ? $params{now} : $self->time;

      $delay = delete($params{at}) - $now;
   }
   elsif( exists $params{after} ) {
      $delay = delete $params{after};
   }
   else {
      croak "Expected either 'at' or 'after' keys";
   }

   my $interval = $delay * 1000; # miliseconds
   $interval = 0 if $interval < 0; # clamp or Glib gets upset

   my $code = delete $params{code};
   ref $code eq "CODE" or croak "Expected 'code' to be a CODE reference";

   my $id;

   my $callback = sub {
      $code->();
      return 0;
   };

   return Glib::Timeout->add( $interval, $callback );
}

sub unwatch_time
{
   my $self = shift;
   my ( $id ) = @_;

   Glib::Source->remove( $id );

   return;
}

sub watch_child
{
   my $self = shift;
   my ( $pid, $code ) = @_;

   if( $pid == 0 ) {
      return $self->SUPER::watch_child( @_ );
   }

   my $childwatches = $self->{childwatches};

   $childwatches->{$pid} = Glib::Child->watch_add( $pid,
      sub {
         $code->( $_[0], $_[1] );
         delete $childwatches->{$pid};
         return 0;
      },
   );
}

sub unwatch_child
{
   my $self = shift;
   my ( $pid ) = @_;

   if( $pid == 0 ) {
      return $self->SUPER::unwatch_child( @_ );
   }

   Glib::Source->remove( delete $self->{childwatches}{$pid} );
}

sub watch_idle
{
   my $self = shift;
   my %params = @_;

   my $code = delete $params{code};
   ref $code eq "CODE" or croak "Expected 'code' to be a CODE reference";

   my $when = delete $params{when} or croak "Expected 'when'";
   $when eq "later" or croak "Expected 'when' to be 'later'";

   return Glib::Idle->add( sub { $code->(); return 0 } );
}

sub unwatch_idle
{
   my $self = shift;
   my ( $id ) = @_;

   Glib::Source->remove( $id );
}

=head2 $loop->loop_once( $timeout )

This method calls the C<iteration()> method on the underlying 
C<Glib::MainContext>. If a timeout value is supplied, then a Glib timeout
will be installed, to interrupt the loop at that time. If Glib indicates that
any callbacks were fired, then this method will return 1 (however, it does not
mean that any C<IO::Async> callbacks were invoked, as there may be other parts
of code sharing the Glib main context. Otherwise, it will return 0.

=cut

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   $self->_adjust_timeout( \$timeout, no_sigwait => 1 );

   my $timed_out = 0;

   my $timerid;
   if( defined $timeout ) {
      my $interval = $timeout * 1000; # miliseconds
      $timerid = Glib::Timeout->add( $interval, sub { $timed_out = 1; return 0; } );
   }

   my $context = Glib::MainContext->default;
   1 until $context->iteration( 1 );

   if( defined $timerid ) {
      Glib::Source->remove( $timerid ) unless $timed_out;
   }
}

sub loop_forever
{
   my $self = shift;

   my $mainloop = $self->{mainloop} = Glib::MainLoop->new();
   $mainloop->run;

   undef $self->{mainloop};
}

sub loop_stop
{
   my $self = shift;
   
   $self->{mainloop}->quit;
}

=head1 SEE ALSO

=over 4

=item *

L<Glib> - Perl wrappers for the GLib utility and Object libraries

=item *

L<Gtk2> - Perl interface to the 2.x series of the Gimp Toolkit library

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
