#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012 -- leonerd@leonerd.org.uk

package IO::Async::Loop::EV;

use strict;
use warnings;

our $VERSION = '0.02';
use constant API_VERSION => '0.49';

use base qw( IO::Async::Loop );
IO::Async::Loop->VERSION( '0.49' );

use constant _CAN_SUBSECOND_ACCURATELY => 0;

use Carp;

use EV;

=head1 NAME

C<IO::Async::Loop::EV> - use C<IO::Async> with C<EV>

=head1 SYNOPSIS

 use IO::Async::Loop::EV;

 my $loop = IO::Async::Loop::EV->new();

 $loop->add( ... );

 $loop->add( IO::Async::Signal->new(
       name => 'HUP',
       on_receipt => sub { ... },
 ) );

 $loop->loop_forever();

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses L<EV> to perform its work.

=cut

sub new
{
   my $class = shift;
   my $self = $class->SUPER::__new( @_ );

   $self->{$_} = {} for qw( watch_r watch_w watch_time watch_signal watch_idle watch_child );

   return $self;
}

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   my $timeout_w;
   if( defined $timeout ) {
      $timeout_w = EV::timer $timeout, 0, sub {}; # simply to wake up RUN_ONCE
   }

   EV::run( EV::RUN_ONCE );
}

sub watch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";

   if( my $on_read_ready = $params{on_read_ready} ) {
      $self->{watch_r}{$handle} = EV::io( $handle, EV::READ, $on_read_ready );
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      $self->{watch_w}{$handle} = EV::io( $handle, EV::WRITE, $on_write_ready );
   }
}

sub unwatch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";

   if( $params{on_read_ready} ) {
      delete $self->{watch_r}{$handle};
   }

   if( $params{on_write_ready} ) {
      delete $self->{watch_w}{$handle};
   }
}

sub watch_time
{
   my $self = shift;
   my %params = @_;

   my $code = $params{code} or croak "Expected 'code' as CODE ref";

   my $w;
   if( defined $params{after} ) {
      $w = EV::timer $params{after}, 0, $code;
   }
   else {
      $w = EV::periodic $params{at}, 0, 0, $code;
   }

   return $self->{watch_time}{$w} = $w;
}

sub unwatch_time
{
   my $self = shift;
   my ( $id ) = @_;

   delete $self->{watch_time}{$id};
}

sub watch_signal
{
   my $self = shift;
   my ( $signal, $code ) = @_;

   defined $self->signame2num( $signal ) or croak "No such signal '$signal'";

   $self->{watch_signal}{$signal} = EV::signal $signal, $code;
}

sub unwatch_signal
{
   my $self = shift;
   my ( $signal ) = @_;

   delete $self->{watch_signal}{$signal};
}

sub watch_idle
{
   my $self = shift;
   my %params = @_;

   my $when = delete $params{when} or croak "Expected 'when'";

   my $code = delete $params{code} or croak "Expected 'code' as a CODE ref";

   $when eq "later" or croak "Expected 'when' to be 'later'";

   my $key;
   my $w = EV::idle sub {
      delete $self->{watch_idle}{$key};
      goto &$code;
   };

   $key = "$w";
   $self->{watch_idle}{$key} = $w;
   return $key;
}

sub unwatch_idle
{
   my $self = shift;
   my ( $id ) = @_;

   delete $self->{watch_idle}{$id};
}

sub watch_child
{
   my $self = shift;
   my ( $pid, $code ) = @_;

   $self->{watch_child}{$pid} = EV::child $pid, 0, sub {
      my $w = shift;
      $code->( $w->rpid, $w->rstatus );
   };
}

sub unwatch_child
{
   my $self = shift;
   my ( $pid ) = @_;

   delete $self->{watch_child}{$pid};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
