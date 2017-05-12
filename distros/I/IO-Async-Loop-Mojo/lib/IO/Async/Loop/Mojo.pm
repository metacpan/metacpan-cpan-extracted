#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2013 -- leonerd@leonerd.org.uk

package IO::Async::Loop::Mojo;

use strict;
use warnings;

our $VERSION = '0.05';
use constant API_VERSION => '0.49';

use base qw( IO::Async::Loop );
IO::Async::Loop->VERSION( '0.49' );

use Carp;

use Mojo::Reactor;
use Mojo::IOLoop;

=head1 NAME

C<IO::Async::Loop::Mojo> - use C<IO::Async> with C<Mojolicious>

=head1 SYNOPSIS

 use IO::Async::Loop::Mojo;

 my $loop = IO::Async::Loop::Mojo->new();

 $loop->add( ... );

 ...
 # Rest of Mojolicious code here

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses L<Mojo::Reactor> to perform its IO
operations. It allows the use of L<IO::Async>-based code or modules from
within a L<Mojolicious> application.

=head1 CONSTRUCTOR

=cut

=head2 $loop = IO::Async::Loop::Mojo->new()

This function returns a new instance of a C<IO::Async::Loop::Mojo> object. It
takes no special arguments.

=cut

sub new
{
   my $class = shift;
   my $self = $class->__new( @_ );

   $self->{reactor} = Mojo::IOLoop->singleton->reactor;

   return $self;
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

   my $reactor = $self->{reactor};

   my $cbs;
   $cbs = $self->{io_cbs}{$fd} ||= do {
      # Install the watch function
      $reactor->io( $handle => sub {
         my ( $reactor, $writable ) = @_;
         if( $writable ) {
            $cbs->[1]->();
         }
         else {
            $cbs->[0]->();
         }
      } );

      [];
   };

   if( my $on_read_ready = $params{on_read_ready} ) {
      $cbs->[0] = $on_read_ready;
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      $cbs->[1] = $on_write_ready;
   }

   $reactor->watch( $handle => defined $cbs->[0], defined $cbs->[1] );
}

sub unwatch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or croak "Expected 'handle'";
   my $fd = $handle->fileno;

   my $reactor = $self->{reactor};

   my $cbs = $self->{io_cbs}{$fd} or return;

   if( $params{on_read_ready} ) {
      undef $cbs->[0];
   }

   if( $params{on_write_ready} ) {
      undef $cbs->[1];
   }

   if( defined $cbs->[0] or defined $cbs->[1] ) {
      $reactor->watch( $handle => defined $cbs->[0], defined $cbs->[1] );
   }
   else {
      $reactor->remove( $handle );
      delete $self->{io_cbs}{$fd};
   }
}

sub watch_time
{
   my $self = shift;
   my ( %params ) = @_;

   my $reactor = $self->{reactor};

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

   $delay = 0 if $delay < 0;

   my $code = delete $params{code};

   my $id;

   my $once;
   my $callback = sub {
      my $reactor = shift;
      $code->() unless $once++;
   };

   return $reactor->timer( $delay => $callback );
}

sub unwatch_time
{
   my $self = shift;
   my ( $id ) = @_;

   my $reactor = $self->{reactor};

   $reactor->remove( $id );

   return;
}

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;
   my $reactor = $self->{reactor};

   $self->_adjust_timeout( \$timeout );

   my $timeout_id;
   if( defined $timeout ) {
      $timeout_id = $reactor->timer( $timeout => sub {} );
   }

   $reactor->one_tick;

   $self->_manage_queues;

   $reactor->remove( $timeout_id ) if $timeout_id;
}

sub run
{
   my $self = shift;
   my $reactor = $self->{reactor};

   my $result = [];
   # Not all Mojo::Reactor classes cope well with nested invocations
   if( !exists $self->{result} ) {
      local $self->{result} = $result;
      $reactor->start;
   }
   else {
      local $self->{result} = $result;
      local $self->{running} = 1;
      $reactor->one_tick while $self->{running};
   }

   return wantarray ? @$result : $result->[0];
}

sub stop
{
   my $self = shift;
   @{ $self->{result} } = @_;

   $self->{running} ? undef $self->{running} : $self->{reactor}->stop;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
