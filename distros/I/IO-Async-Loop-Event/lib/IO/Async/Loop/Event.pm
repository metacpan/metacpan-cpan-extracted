#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012 -- leonerd@leonerd.org.uk

package IO::Async::Loop::Event;

use strict;
use warnings;

our $VERSION = '0.02';
use constant API_VERSION => '0.49';

use base qw( IO::Async::Loop );
IO::Async::Loop->VERSION( '0.49' );

use constant _CAN_SUBSECOND_ACCURATELY => 0;

use Carp;

use Event;

=head1 NAME

C<IO::Async::Loop::Event> - use C<IO::Async> with C<Event>

=head1 SYNOPSIS

 use IO::Async::Loop::Event;

 my $loop = IO::Async::Loop::Event->new();

 $loop->add( ... );

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses L<Event> to perform its work.

=cut

sub new
{
   my $class = shift;
   my $self = $class->SUPER::__new( @_ );

   $self->{$_} = {} for qw( watch_io watch_sig watch_idle );

   return $self;
}

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   if( defined $timeout ) {
      Event::one_event( $timeout );
   }
   else {
      Event::one_event;
   }
}

sub run
{
   my $self = shift;

   my $result = Event::loop();
   wantarray ? @$result : $result->[0];
}

sub stop
{
   my $self = shift;
   my @result = @_;

   Event::unloop( \@result );
}

sub watch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";

   my $w = $self->{watch_io}{$handle} ||= [];

   if( my $on_read_ready = $params{on_read_ready} ) {
      $w->[1] = $on_read_ready;
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      $w->[2] = $on_write_ready;
   }

   my $poll = ( $w->[1] ? "r" : "" ) . ( $w->[2] ? "w" : "" );

   if( $w->[0] ) {
      $w->[0]->poll( $poll );
   }
   else {
      $w->[0] = Event->io(
         poll => $poll,
         fd => $handle,
         cb => sub {
            my $e = shift;
            if( $e->got =~ m/r/ and $w->[1] ) {
               $w->[1]->();
            }
            if( $e->got =~ m/w/ and $w->[2] ) {
               $w->[2]->();
            }
         }
      );
   }
}

sub unwatch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";

   my $w = $self->{watch_io}{$handle} or return;

   if( $params{on_read_ready} ) {
      undef $w->[1];
   }

   if( $params{on_write_ready} ) {
      undef $w->[2];
   }

   my $poll = ( $w->[1] ? "r" : "" ) . ( $w->[2] ? "w" : "" );

   if( length $poll ) {
      $w->[0]->poll( $poll );
   }
   else {
      $w->[0]->cancel;
      delete $self->{watch_io}{$handle};
   }
}

sub watch_time
{
   my $self = shift;
   my %params = @_;

   my $code = $params{code} or croak "Expected 'code' as CODE ref";

   my $w;
   if( defined $params{after} ) {
      my $delay = $params{after};
      $delay = 0 if $delay < 0;
      $w = Event->timer( after => $delay, cb => $code );
   }
   else {
      $w = Event->timer( at => $params{at}, cb => $code );
   }

   return $w;
}

sub unwatch_time
{
   my $self = shift;
   my ( $w ) = @_;

   $w->cancel;
}

sub watch_signal
{
   my $self = shift;
   my ( $name, $code ) = @_;

   exists $SIG{$name} or croak "Unrecognised signal name $name";

   my $w = Event->signal( signal => $name, cb => $code );
   $self->{watch_sig}{$name} = $w;
}

sub unwatch_signal
{
   my $self = shift;
   my ( $name ) = @_;

   ( delete $self->{watch_sig}{$name} )->cancel;
}

sub watch_idle
{
   my $self = shift;
   my %params = @_;

   my $when = delete $params{when} or croak "Expected 'when'";

   my $code = delete $params{code} or croak "Expected 'code' as a CODE ref";

   $when eq "later" or croak "Expected 'when' to be 'later'";

   my $key;
   my $idles = $self->{watch_idle};
   my $w = Event->timer(
      after => 0,
      cb => $code,
      prio => -1,
   );

   $key = "$w";
   $idles->{$key} = $w;
   return $key;
}

sub unwatch_idle
{
   my $self = shift;
   my ( $id ) = @_;

   ( delete $self->{watch_idle}{$id} )->cancel;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
